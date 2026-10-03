import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/sentence_practice/sentence_analysis_client.dart';

class Adapter implements HttpClientAdapter {
  Adapter(this.answer);
  final Map<String, dynamic> Function(RequestOptions) answer;
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    calls++;
    return ResponseBody.fromString(
      jsonEncode(answer(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('unsafe remote URL is rejected before transmitting', () async {
    final adapter = Adapter((_) => {}), dio = Dio();
    dio.httpClientAdapter = adapter;
    await expectLater(
      SentenceAnalysisClient(
        dio: dio,
        baseUrl: 'http://example.com',
      ).capabilities(),
      throwsStateError,
    );
    expect(adapter.calls, 0);
  });
  test('mismatched result cannot attach to recording', () async {
    final file = await File(
      '${Directory.systemTemp.path}/sentence_client_test.wav',
    ).writeAsBytes([1, 2]);
    addTearDown(() => file.delete());
    final dio = Dio()
      ..httpClientAdapter = Adapter(
        (request) => request.method == 'POST'
            ? {'jobId': 'job'}
            : {
                'status': 'completed',
                'recordingId': 'wrong',
                'id': 'a',
                'audioSha256': 'h',
                'sentenceRevisionId': 's',
              },
      );
    Map<String, dynamic>? queued;
    await expectLater(
      SentenceAnalysisClient(dio: dio).analyze(
        recording: {'id': 'r', 'hash': 'h'},
        sentence: {'id': 's', 'text': 'Hi', 'language': 'en-US'},
        assessment: {'id': 'a'},
        path: file.path,
        cancel: CancelToken(),
        onQueued: (a) async => queued = a,
      ),
      throwsStateError,
    );
    expect(queued?['remoteJobId'], 'job');
  });
}
