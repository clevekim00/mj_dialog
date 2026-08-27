import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';
import 'package:speech_rehab/features/consonant_training/services/pronunciation_analysis_client.dart';

void main() {
  test('비동기 분석 작업을 완료될 때까지 조회한다', () async {
    final audio = File(
      '${Directory.systemTemp.path}/analysis_${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
    await audio.writeAsBytes([1, 2, 3]);
    addTearDown(audio.delete);
    final adapter = _AnalysisAdapter();
    final client = PronunciationAnalysisClient(
      dio: Dio()..httpClientAdapter = adapter,
      baseUrl: 'https://analysis.test',
      pollInterval: Duration.zero,
    );

    final result = await client.analyze(
      audioFilePath: audio.path,
      item: const PronunciationContentItem(
        id: 'item',
        targetId: 'onset_g',
        level: ConsonantTrainingLevel.syllable,
        text: '가',
        pronunciation: ['k'],
        difficulty: 1,
        category: 'test',
        targetOccurrenceCount: 1,
      ),
      target: const ConsonantTrainingTarget(
        id: 'onset_g',
        grapheme: 'ㄱ',
        phone: 'k',
        position: PhonemePosition.onset,
        description: '',
      ),
      contentVersion: '1.0.0',
      language: 'en-US',
    );

    expect(result.status, PronunciationAnalysisStatus.completed);
    expect(result.overallPracticeScore, 84);
    expect(result.phonemes.single.expectedPhone, 'k');
    expect(result.language, 'en-US');
    expect(adapter.statusReads, 2);
    expect(adapter.sentLanguage, 'en-US');
  });

  test('MFA 정렬 결과는 점수 없이 음소 구간으로 파싱한다', () {
    final result = PronunciationAnalysisResult.fromJson({
      'jobId': 'mfa-job',
      'status': 'completed',
      'language': 'ko-KR',
      'modelVersion': 'mfa-korean-v3.0.0',
      'contentVersion': '1.0.0',
      'overallPracticeScore': null,
      'confidence': 0.0,
      'signalQuality': {'accepted': true},
      'phonemes': [
        {
          'expected': 'kf',
          'alignedPhone': 'k̚',
          'observedCandidates': [],
          'position': 'coda',
          'startMs': 520,
          'endMs': 700,
          'gop': null,
          'practiceScore': null,
          'scoreAvailable': false,
          'confidence': 0.0,
          'status': 'aligned',
        },
      ],
      'disclaimer': 'test',
    });

    expect(result.overallPracticeScore, isNull);
    expect(result.phonemes.single.practiceScore, isNull);
    expect(result.phonemes.single.rawGop, isNull);
    expect(result.phonemes.single.status, PhonemeFeedbackStatus.aligned);
    expect(result.phonemes.single.alignedPhone, 'k̚');
    expect(result.phonemes.single.startMs, 520);
  });
}

class _AnalysisAdapter implements HttpClientAdapter {
  int statusReads = 0;
  String? sentLanguage;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'POST') {
      final form = options.data as FormData;
      sentLanguage = form.fields
          .where((entry) => entry.key == 'language')
          .single
          .value;
      return _json({'jobId': 'job-1', 'status': 'queued'});
    }
    statusReads++;
    if (statusReads == 1) {
      return _json({'jobId': 'job-1', 'status': 'processing'});
    }
    return _json({
      'jobId': 'job-1',
      'status': 'completed',
      'language': 'en-US',
      'modelVersion': 'test-model',
      'contentVersion': '1.0.0',
      'overallPracticeScore': 84,
      'confidence': 0.9,
      'signalQuality': {'accepted': true},
      'baselineDelta': null,
      'phonemes': [
        {
          'expected': 'k',
          'observedCandidates': [
            {'phone': 'k', 'probability': 0.9},
          ],
          'position': 'onset',
          'startMs': 10,
          'endMs': 100,
          'gop': -0.1,
          'practiceScore': 84,
          'confidence': 0.9,
          'status': 'accurate',
        },
      ],
      'disclaimer': 'test',
    });
  }

  ResponseBody _json(Map<String, dynamic> value) => ResponseBody.fromString(
    jsonEncode(value),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}
