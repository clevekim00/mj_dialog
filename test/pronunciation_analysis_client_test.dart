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
    );

    expect(result.status, PronunciationAnalysisStatus.completed);
    expect(result.overallPracticeScore, 84);
    expect(result.phonemes.single.expectedPhone, 'k');
    expect(adapter.statusReads, 2);
  });
}

class _AnalysisAdapter implements HttpClientAdapter {
  int statusReads = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'POST') {
      return _json({'jobId': 'job-1', 'status': 'queued'});
    }
    statusReads++;
    if (statusReads == 1) {
      return _json({'jobId': 'job-1', 'status': 'processing'});
    }
    return _json({
      'jobId': 'job-1',
      'status': 'completed',
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
