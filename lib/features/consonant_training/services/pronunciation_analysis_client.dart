import 'dart:io';

import 'package:dio/dio.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';

class PronunciationAnalysisClient {
  PronunciationAnalysisClient({
    Dio? dio,
    this.baseUrl = const String.fromEnvironment(
      'PRONUNCIATION_ANALYSIS_URL',
      defaultValue: 'http://127.0.0.1:8000',
    ),
    this.pollInterval = const Duration(milliseconds: 500),
    this.timeout = const Duration(seconds: 30),
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;
  final Duration pollInterval;
  final Duration timeout;

  Future<PronunciationAnalysisResult> analyze({
    required String audioFilePath,
    required PronunciationContentItem item,
    required ConsonantTrainingTarget target,
    required String contentVersion,
    double? baselineScore,
  }) async {
    try {
      if (!await File(audioFilePath).exists()) {
        return PronunciationAnalysisResult.unavailable('녹음 파일을 찾을 수 없습니다.');
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/v1/analysis/jobs',
        data: FormData.fromMap({
          'audio': await MultipartFile.fromFile(audioFilePath),
          'text': item.text,
          'target_phone': target.phone,
          'position': target.position.name,
          'content_version': contentVersion,
          'baseline_score': ?baselineScore,
        }),
      );
      final jobId = response.data?['jobId'] as String?;
      if (jobId == null || jobId.isEmpty) {
        return PronunciationAnalysisResult.unavailable('분석 작업을 시작하지 못했습니다.');
      }

      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        final statusResponse = await _dio.get<Map<String, dynamic>>(
          '$baseUrl/v1/analysis/jobs/$jobId',
        );
        final result = PronunciationAnalysisResult.fromJson(
          statusResponse.data ?? const {},
        );
        if (result.status == PronunciationAnalysisStatus.completed ||
            result.status == PronunciationAnalysisStatus.failed ||
            result.status == PronunciationAnalysisStatus.unavailable) {
          return result;
        }
        await Future<void>.delayed(pollInterval);
      }
      return PronunciationAnalysisResult.unavailable('분석 응답 시간이 초과되었습니다.');
    } on DioException catch (error) {
      final detail = error.response?.data;
      return PronunciationAnalysisResult.unavailable(
        detail is Map
            ? detail['detail']?.toString() ?? '분석 서버에 연결할 수 없습니다.'
            : '분석 서버에 연결할 수 없습니다.',
      );
    } catch (_) {
      return PronunciationAnalysisResult.unavailable('발음 분석 중 오류가 발생했습니다.');
    }
  }
}
