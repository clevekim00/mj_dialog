import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SentenceAnalysisClient {
  SentenceAnalysisClient({
    Dio? dio,
    this.baseUrl = const String.fromEnvironment(
      'SENTENCE_ANALYSIS_URL',
      defaultValue: 'http://127.0.0.1:8001',
    ),
    this.accessToken,
  }) : dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 20),
               followRedirects: false,
             ),
           );
  final Dio dio;
  final String baseUrl;
  final String? accessToken;
  String get endpoint =>
      '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/v1/sentence-analysis';
  void validate() {
    final uri = Uri.tryParse(baseUrl);
    final local =
        uri != null && {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.scheme != 'https' &&
            !(local && !kReleaseMode && uri.scheme == 'http'))) {
      throw StateError('Secure server URL required');
    }
    if (!local && (accessToken?.trim().isEmpty ?? true)) {
      throw StateError('Sign in to the analysis server first');
    }
  }

  Options get options => Options(
    headers: {
      if (accessToken?.isNotEmpty == true)
        'Authorization': 'Bearer $accessToken',
    },
    followRedirects: false,
  );
  Future<Map<String, dynamic>> capabilities() async {
    validate();
    return (await dio.get<Map<String, dynamic>>(
      '$endpoint/capabilities',
      options: options,
    )).data!;
  }

  Future<Map<String, dynamic>> analyze({
    required Map<String, dynamic> recording,
    required Map<String, dynamic> sentence,
    required Map<String, dynamic> assessment,
    required String path,
    required CancelToken cancel,
    required Future<void> Function(Map<String, dynamic>) onQueued,
  }) async {
    validate();
    final timer = Timer(
      const Duration(minutes: 2),
      () => cancel.cancel('deadline'),
    );
    try {
      String? job = assessment['remoteJobId'] as String?;
      if (job == null) {
        final file = File(path);
        if (!await file.exists() || await file.length() > 20 * 1024 * 1024) {
          throw StateError('Missing or oversized audio');
        }
        final response = await dio.post<Map<String, dynamic>>(
          '$endpoint/jobs',
          data: FormData.fromMap({
            'audio': await MultipartFile.fromFile(path),
            'recordingId': recording['id'],
            'assessmentId': assessment['id'],
            'sentenceRevisionId': sentence['id'],
            'confirmedText': sentence['text'],
            'language': sentence['language'],
            'audioSha256': recording['hash'],
            'analysisVersion': 'sentence-v1',
            'consentPolicyVersion': 'sentence-local-v1',
          }),
          options: Options(
            headers: {...options.headers!, 'Idempotency-Key': assessment['id']},
            followRedirects: false,
          ),
          cancelToken: cancel,
        );
        job = response.data?['jobId'] as String?;
        if (job == null) throw StateError('Invalid job response');
        await onQueued({
          ...assessment,
          'status': 'queued',
          'remoteJobId': job,
          'server': baseUrl,
        });
      }
      while (!cancel.isCancelled) {
        final data = (await dio.get<Map<String, dynamic>>(
          '$endpoint/jobs/${Uri.encodeComponent(job)}',
          options: options,
          cancelToken: cancel,
        )).data!;
        if (!{'queued', 'running'}.contains(data['status'])) {
          if (data['recordingId'] != recording['id'] ||
              data['audioSha256'] != recording['hash'] ||
              data['sentenceRevisionId'] != sentence['id'] ||
              data['id'] != assessment['id']) {
            throw StateError('Result does not match this recording');
          }
          return {...data, 'remoteJobId': job, 'server': baseUrl};
        }
        await Future.any([
          Future<void>.delayed(const Duration(seconds: 1)),
          cancel.whenCancel,
        ]);
      }
      throw StateError('Analysis cancelled');
    } finally {
      timer.cancel();
    }
  }

  Future<void> delete(String job) async {
    validate();
    await dio.delete<void>(
      '$endpoint/jobs/${Uri.encodeComponent(job)}',
      options: options,
    );
  }
}
