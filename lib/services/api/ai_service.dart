import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:synchronized/synchronized.dart';
import 'package:speech_rehab/services/app_language_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(
    languageCode: ref.watch(appLanguageProvider).resolvedLocale.languageCode,
  );
});

class AiService {
  const AiService({this.languageCode});

  final String? languageCode;

  static final Lock _gemmaLock = Lock();
  static bool _gemmaReady = false;

  String get _osLanguage {
    final code =
        languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    return switch (code) {
      'ko' => 'Korean',
      'en' => 'English',
      'ja' => 'Japanese',
      'zh' => 'Chinese',
      _ => 'Korean', // Default to Korean for this specific app's context
    };
  }

  static const textMatchVersion = 'text-match-v1';

  Future<AiResponse> getReadingFeedback(
    String targetText,
    String spokenText,
  ) async => _textMatchEvaluation(targetText, spokenText);

  Future<AiResponse> getFreeReadingFeedback(String spokenText) async =>
      spokenText.trim().isEmpty
      ? _unavailable()
      : const AiResponse(
          replyText: '자유 말하기 기록을 남겼습니다.',
          pronunciationScore: null,
          pronunciationFeedback:
              '인식된 내용을 확인하고 녹음을 들어보세요. 자유 말하기는 점수를 매기지 않습니다.',
          evaluationMethod: 'notAssessed',
          evaluationVersion: 'unscored-v1',
        );

  Future<AiResponse> evaluatePracticeByMode({
    required PracticeMode mode,
    required String targetText,
    required String spokenText,
    required int durationSeconds,
  }) async {
    if (mode == PracticeMode.freeSpeech) {
      return getFreeReadingFeedback(spokenText);
    }
    return _textMatchEvaluation(
      targetText,
      spokenText,
      exactOnly: mode == PracticeMode.wordGame,
    );
  }

  AiResponse _unavailable() => const AiResponse(
    replyText: '음성을 인식하지 못했습니다.',
    pronunciationScore: null,
    pronunciationFeedback:
        '인식 결과가 없어 비교할 수 없습니다. 녹음을 확인하거나 편할 때 다시 시도해 주세요. 발음이 틀렸다는 뜻은 아닙니다.',
    evaluationMethod: 'unavailable',
    evaluationVersion: 'unscored-v1',
  );

  AiResponse _textMatchEvaluation(
    String targetText,
    String spokenText, {
    bool exactOnly = false,
  }) {
    final target = _normalizeText(targetText).runes.toList();
    final spoken = _normalizeText(spokenText).runes.toList();
    if (spoken.isEmpty || target.isEmpty) return _unavailable();
    var previous = List<int>.generate(spoken.length + 1, (index) => index);
    for (var i = 1; i <= target.length; i++) {
      final current = List<int>.filled(spoken.length + 1, 0)..[0] = i;
      for (var j = 1; j <= spoken.length; j++) {
        final substitution =
            previous[j - 1] + (target[i - 1] == spoken[j - 1] ? 0 : 1);
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        current[j] = [
          substitution,
          deletion,
          insertion,
        ].reduce((a, b) => a < b ? a : b);
      }
      previous = current;
    }
    final distance = previous.last;
    final length = target.length > spoken.length
        ? target.length
        : spoken.length;
    final score = exactOnly
        ? (distance == 0 ? 100 : 0)
        : ((1 - distance / length) * 100).round().clamp(0, 100);
    return AiResponse(
      replyText: distance == 0
          ? '목표 글과 인식된 글이 일치합니다.'
          : '목표 글과 인식된 글에 차이가 있습니다.',
      pronunciationScore: score,
      pronunciationFeedback: distance == 0
          ? '텍스트 일치도입니다. 원음의 발음 정확도나 치료 효과를 평가한 점수는 아닙니다.'
          : '인식된 말은 "$spokenText"입니다. 음성 인식 오류일 수도 있으니 녹음을 들어보세요. 발음 정확도 점수가 아닙니다.',
      evaluationMethod: 'textMatch',
      evaluationVersion: textMatchVersion,
    );
  }

  String _normalizeText(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r"[\s.,!?;:，。！？、…]"), '');

  Future<AiResponse> getResponseAndFeedback(String userText) async {
    try {
      if (!await _ensureGemmaReady()) {
        debugPrint(
          'Gemma model is not active. Falling back to canned response.',
        );
        return _fallbackParse(userText);
      }

      final prompt = _buildPrompt(userText);
      final responseText = await _generateGemmaText(
        prompt: prompt,
        temperature: 0.7,
        label: 'chat',
      );

      if (responseText.isEmpty) {
        debugPrint('Gemma returned an empty response. Falling back.');
        return _fallbackParse(userText);
      }

      return _parseResponse(responseText);
    } catch (error) {
      debugPrint('On-device conversation unavailable.');
      return _fallbackParse(userText);
    }
  }

  Future<bool> _ensureGemmaReady() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(
        'Gemma is disabled on iOS because flutter_gemma crashes during native plugin registration on device startup.',
      );
      return false;
    }

    return _gemmaLock.synchronized(() async {
      if (_gemmaReady) {
        return true;
      }

      try {
        await FlutterGemma.initialize();
        if (!FlutterGemma.hasActiveModel()) {
          await FlutterGemma.installModel(
            modelType: ModelType.gemmaIt,
            fileType: ModelFileType.binary,
          ).fromAsset('assets/gemma-2b-it-gpu-int4.bin').install();
        }
        _gemmaReady = FlutterGemma.hasActiveModel();
        return _gemmaReady;
      } catch (error) {
        debugPrint('Gemma init failed or no model loaded: $error');
        return false;
      }
    });
  }

  Future<String> _generateGemmaText({
    required String prompt,
    required double temperature,
    required String label,
  }) async {
    return _gemmaLock.synchronized(() async {
      final watch = Stopwatch()..start();
      debugPrint('[Gemma] queued request started: $label');
      final model = await FlutterGemma.getActiveModel(maxTokens: 512);
      final chat = await model.createChat(temperature: temperature);
      await chat.addQuery(Message(text: prompt, isUser: true));
      final modelResponse = await chat.generateChatResponse();
      watch.stop();
      debugPrint(
        '[Gemma] request completed: $label '
        'elapsed=${watch.elapsedMilliseconds}ms',
      );

      return switch (modelResponse) {
        TextResponse() => modelResponse.token,
        _ => '',
      };
    });
  }

  String _buildPrompt(String userText) =>
      '''
You are a friendly conversation partner. Respond in $_osLanguage.
The user provided this text: "$userText".
Reply to its meaning and offer one natural follow-up question.
You have no audio. Never evaluate pronunciation, articulation, voice, fluency,
breathing, intelligibility, or treatment outcomes, and never assign a score.
Return only JSON: {"replyText": "your conversational reply"}.
''';

  Future<AiResponse> evaluateAudio(String audioPath, String targetText) async =>
      _unavailable();

  AiResponse _parseResponse(String rawGemmaOutput) {
    try {
      final decoded =
          jsonDecode(_extractJsonObject(rawGemmaOutput))
              as Map<String, dynamic>;
      return AiResponse(
        replyText: _sanitizeText(decoded['replyText'] as String?),
        pronunciationScore: null,
        pronunciationFeedback: '대화 내용에 대한 응답입니다. 음성이나 발음은 평가하지 않습니다.',
        evaluationMethod: 'notAssessed',
        evaluationVersion: 'chat-text-v1',
      );
    } catch (_) {
      return _fallbackParse('');
    }
  }

  String _extractJsonObject(String rawGemmaOutput) {
    final withoutFence = rawGemmaOutput
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final start = withoutFence.indexOf('{');
    final end = withoutFence.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw const FormatException('No JSON object found.');
    }

    return withoutFence.substring(start, end + 1);
  }

  String _sanitizeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return _osLanguage == 'Korean'
          ? '천천히 대화를 이어가 볼까요? 최근에 즐거웠던 일이 있으신가요?'
          : 'Shall we continue our conversation slowly? Has anything pleasant happened recently?';
    }

    return normalized;
  }

  AiResponse _fallbackParse(String userText) => const AiResponse(
    replyText: '천천히 이어가도 괜찮아요. 오늘 이야기하고 싶은 일이 있나요?',
    pronunciationScore: null,
    pronunciationFeedback: '기본 대화 안내입니다. 음성이나 발음은 평가하지 않습니다.',
    evaluationMethod: 'notAssessed',
    evaluationVersion: 'chat-fallback-v1',
  );
}

class AiResponse {
  const AiResponse({
    required this.replyText,
    required this.pronunciationScore,
    required this.pronunciationFeedback,
    this.evaluationMethod = 'notAssessed',
    this.evaluationVersion = 'unscored-v1',
    this.phonemeAccuracy,
    this.intonationFeedback,
  });

  final String replyText;
  final int? pronunciationScore;
  final String evaluationMethod;
  final String evaluationVersion;
  bool get hasComparableScore =>
      evaluationMethod == 'textMatch' && pronunciationScore != null;
  String get scoreLabel => switch (evaluationMethod) {
    'textMatch' => '텍스트 일치도',
    'legacy' => '이전 방식 점수',
    'unavailable' => '분석 불가',
    _ => '점수 없음',
  };
  String get scoreDisplay => pronunciationScore == null
      ? scoreLabel
      : '$scoreLabel $pronunciationScore${evaluationMethod == 'textMatch' ? '%' : '점'}';

  final String pronunciationFeedback;
  final List<PhonemeData>? phonemeAccuracy;
  final String? intonationFeedback;
}

class PhonemeData {
  final String phoneme;
  final int score;
  final String? issue;

  PhonemeData({required this.phoneme, required this.score, this.issue});

  factory PhonemeData.fromJson(Map<String, dynamic> json) {
    return PhonemeData(
      phoneme: json['phoneme'] as String,
      score: (json['score'] as num).toInt(),
      issue: json['issue'] as String?,
    );
  }
}
