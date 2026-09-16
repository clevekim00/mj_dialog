import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';

/// Supply a short-lived user token from your trusted authentication service.
/// Never embed the server signing secret or a shared permanent key in the app.
typedef AnalysisAccessTokenProvider = Future<String?> Function();

class PronunciationAnalysisClient {
  PronunciationAnalysisClient({
    Dio? dio,
    this.baseUrl = const String.fromEnvironment(
      'PRONUNCIATION_ANALYSIS_URL',
      defaultValue: 'http://127.0.0.1:8000',
    ),
    this.pollInterval = const Duration(milliseconds: 500),
    this.timeout = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 10),
    this.accessTokenProvider,
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;
  final Duration pollInterval;
  final Duration timeout;
  final Duration requestTimeout;
  final AnalysisAccessTokenProvider? accessTokenProvider;

  Future<PronunciationAnalysisResult> analyze({
    required String audioFilePath,
    required PronunciationContentItem item,
    required ConsonantTrainingTarget target,
    required String contentVersion,
    required String language,
    double? baselineScore,
    CancelToken? cancelToken,
  }) async {
    final uri = Uri.tryParse(baseUrl);
    final local =
        uri != null &&
        const {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.scheme != 'https' &&
            !(local && !kReleaseMode && uri.scheme == 'http'))) {
      return PronunciationAnalysisResult.unavailable(
        '보안 연결이 가능한 분석 서버를 설정해 주세요.',
      );
    }
    final requestToken = CancelToken();
    var finished = false;
    if (cancelToken?.isCancelled == true) requestToken.cancel('cancelled');
    cancelToken?.whenCancel.then((_) {
      if (!finished) requestToken.cancel('cancelled');
    });
    String? jobId;
    Map<String, dynamic> headers = {};
    final endpoint = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    Options options() => Options(
      headers: headers,
      followRedirects: false,
      sendTimeout: requestTimeout,
      receiveTimeout: requestTimeout,
    );
    // A per-request connect deadline also covers sockets that never connect.
    // Keep this on this client's requests; do not mutate shared Dio defaults.
    Future<Response<Map<String, dynamic>>> request(
      String method,
      String url, {
      Object? data,
    }) {
      final requestOptions =
          options().compose(
              _dio.options,
              url,
              data: data,
              cancelToken: requestToken,
            )
            ..method = method
            ..connectTimeout = requestTimeout;
      return _dio.fetch<Map<String, dynamic>>(requestOptions);
    }

    Future<PronunciationAnalysisResult> run() async {
      final token = await accessTokenProvider?.call();
      if (!local && (token == null || token.trim().isEmpty)) {
        return PronunciationAnalysisResult.unavailable(
          '분석 서버에 로그인한 뒤 다시 시도해 주세요.',
        );
      }
      if (token != null && token.isNotEmpty) {
        headers = {'Authorization': 'Bearer $token'};
      }
      if (requestToken.isCancelled) throw requestToken.cancelError!;
      if (!await File(audioFilePath).exists()) {
        return PronunciationAnalysisResult.unavailable('녹음 파일을 찾을 수 없습니다.');
      }
      if (await File(audioFilePath).length() > 20 * 1024 * 1024) {
        return PronunciationAnalysisResult.unavailable(
          '녹음 파일이 너무 큽니다. 짧게 다시 녹음해 주세요.',
        );
      }
      final response = await request(
        'POST',
        '$endpoint/v1/analysis/jobs',
        data: FormData.fromMap({
          'audio': await MultipartFile.fromFile(audioFilePath),
          'text': item.text,
          'language': language,
          'target_phone': target.phone,
          'position': target.position.name,
          'target_occurrence': 0,
          'content_version': contentVersion,
          'baseline_score': ?baselineScore,
        }),
      );
      jobId = response.data?['jobId'] as String?;
      if (jobId == null || jobId!.isEmpty) {
        return PronunciationAnalysisResult.unavailable('분석 작업을 시작하지 못했습니다.');
      }
      while (!requestToken.isCancelled) {
        final response = await request(
          'GET',
          '$endpoint/v1/analysis/jobs/${Uri.encodeComponent(jobId!)}',
        );
        final result = PronunciationAnalysisResult.fromJson(
          response.data ?? const {},
        );
        if (result.status == PronunciationAnalysisStatus.completed ||
            result.status == PronunciationAnalysisStatus.failed ||
            result.status == PronunciationAnalysisStatus.unavailable) {
          return result;
        }
        await Future.any([
          Future<void>.delayed(pollInterval),
          requestToken.whenCancel,
        ]);
      }
      throw requestToken.cancelError!;
    }

    try {
      return await Future.any<PronunciationAnalysisResult>([
        run(),
        requestToken.whenCancel.then((error) => throw error),
      ]).timeout(
        timeout,
        onTimeout: () {
          requestToken.cancel('deadline');
          return PronunciationAnalysisResult.unavailable('분석 응답 시간이 초과되었습니다.');
        },
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        return PronunciationAnalysisResult.unavailable('분석을 취소했습니다.');
      }
      final detail = error.response?.data;
      return PronunciationAnalysisResult.unavailable(
        detail is Map
            ? detail['detail']?.toString() ?? '분석 서버에 연결할 수 없습니다.'
            : '분석 서버에 연결할 수 없습니다.',
      );
    } catch (_) {
      return PronunciationAnalysisResult.unavailable('발음 분석 중 오류가 발생했습니다.');
    } finally {
      finished = true;
      if (!requestToken.isCancelled) requestToken.cancel('finished');
      if (jobId != null) {
        // Deletion uses a separate bounded request so cancelling polling does
        // not cancel cleanup. Expiry on the server is the fallback.
        unawaited(_deleteJob(endpoint, jobId!, headers));
      }
    }
  }

  Future<void> _deleteJob(
    String endpoint,
    String jobId,
    Map<String, dynamic> headers,
  ) async {
    final token = CancelToken();
    final deadline = Timer(
      const Duration(seconds: 3),
      () => token.cancel('cleanup deadline'),
    );
    try {
      final options =
          Options(
              method: 'DELETE',
              headers: headers,
              followRedirects: false,
              sendTimeout: const Duration(seconds: 2),
              receiveTimeout: const Duration(seconds: 2),
            ).compose(
              _dio.options,
              '$endpoint/v1/analysis/jobs/${Uri.encodeComponent(jobId)}',
              cancelToken: token,
            )
            ..connectTimeout = const Duration(seconds: 2);
      await _dio.fetch<void>(options);
    } catch (_) {
      // Server expiry is the fallback when cleanup cannot reach it.
    } finally {
      deadline.cancel();
    }
  }
}
