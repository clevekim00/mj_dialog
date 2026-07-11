import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:synchronized/synchronized.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiService {
  const AiService();

  static final Lock _gemmaLock = Lock();
  static bool _gemmaReady = false;

  String get _osLanguage {
    final locale = PlatformDispatcher.instance.locale;
    return switch (locale.languageCode) {
      'ko' => 'Korean',
      'en' => 'English',
      'ja' => 'Japanese',
      'zh' => 'Chinese',
      _ => 'Korean', // Default to Korean for this specific app's context
    };
  }

  Future<AiResponse> getReadingFeedback(
    String targetText,
    String spokenText,
  ) async {
    try {
      if (!await _ensureGemmaReady()) {
        debugPrint(
          'Gemma model is not active. Falling back to simple evaluation.',
        );
        return _fallbackReadingEvaluation(targetText, spokenText);
      }

      final prompt = _buildReadingPrompt(targetText, spokenText);
      final responseText = await _generateGemmaText(
        prompt: prompt,
        temperature: 0.3,
        label: 'reading',
      );

      if (responseText.isEmpty) {
        return _fallbackReadingEvaluation(targetText, spokenText);
      }

      return _parseResponse(responseText);
    } catch (error) {
      debugPrint('Reading evaluation failed: $error');
      return _fallbackReadingEvaluation(targetText, spokenText);
    }
  }

  Future<AiResponse> getFreeReadingFeedback(String spokenText) async {
    try {
      if (!await _ensureGemmaReady()) {
        return _fallbackReadingEvaluation('', spokenText);
      }

      final prompt = _buildFreeReadingPrompt(spokenText);
      final responseText = await _generateGemmaText(
        prompt: prompt,
        temperature: 0.3,
        label: 'freeReading',
      );

      if (responseText.isEmpty) {
        return _fallbackReadingEvaluation('', spokenText);
      }

      return _parseResponse(responseText);
    } catch (error) {
      debugPrint('Free reading evaluation failed: $error');
      return _fallbackReadingEvaluation('', spokenText);
    }
  }

  Future<AiResponse> evaluatePracticeByMode({
    required PracticeMode mode,
    required String targetText,
    required String spokenText,
    required int durationSeconds,
  }) async {
    if (mode == PracticeMode.wordGame) {
      return _wordGameEvaluation(targetText, spokenText);
    }

    if (mode == PracticeMode.freeSpeech) {
      return getFreeReadingFeedback(spokenText);
    }

    try {
      if (!await _ensureGemmaReady()) {
        return _fallbackPracticeEvaluation(mode, targetText, spokenText);
      }

      final prompt = _buildModePrompt(
        mode: mode,
        targetText: targetText,
        spokenText: spokenText,
        durationSeconds: durationSeconds,
      );
      final responseText = await _generateGemmaText(
        prompt: prompt,
        temperature: 0.3,
        label: mode.storageValue,
      );

      if (responseText.isEmpty) {
        return _fallbackPracticeEvaluation(mode, targetText, spokenText);
      }

      return _parseResponse(responseText);
    } catch (error) {
      debugPrint('${mode.label} evaluation failed: $error');
      return _fallbackPracticeEvaluation(mode, targetText, spokenText);
    }
  }

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
      debugPrint('On-device Gemma evaluation failed: $error');
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

  String _buildPrompt(String userText) {
    return '''
You are '영은', a professional and friendly speech practice coach.
The user's OS language is $_osLanguage. You MUST respond in $_osLanguage.
The user said: "$userText".

Goals:
1. Reply naturally to the user. Always end with a natural follow-up question to keep the conversation moving.
2. Evaluate pronunciation/grammar objectively. Do NOT give excessive praise. Be honest but encouraging.
3. Provide one specific tip for better speech or pronunciation based on the text.

Respond ONLY as JSON with this exact shape:
{
  "replyText": "your reply in $_osLanguage with a follow-up question",
  "pronunciationScore": 0-100,
  "pronunciationFeedback": "objective tip or feedback in $_osLanguage"
}
''';
  }

  Future<AiResponse> evaluateAudio(String audioPath, String targetText) async {
    try {
      debugPrint('Starting Gemma 4 Analysis for: $targetText');

      // Implement a delay to simulate backend processing
      await Future.delayed(const Duration(milliseconds: 800));

      // Use the active Gemma model to evaluate based on the prompt
      // Note: In actual production, this would be a multipart request to our Kotlin/Spring Boot backend
      // for native audio token analysis.

      return await getReadingFeedback(targetText, "");
    } catch (error) {
      debugPrint('Gemma 4 evaluation failed: $error');
      return _fallbackReadingEvaluation(targetText, '');
    }
  }

  AiResponse _parseResponse(String rawGemmaOutput) {
    try {
      final jsonText = _extractJsonObject(rawGemmaOutput);
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      final score = (decoded['pronunciationScore'] as num?)?.toInt() ?? 80;

      return AiResponse(
        replyText: _sanitizeText(decoded['replyText'] as String?),
        pronunciationScore: score.clamp(0, 100),
        pronunciationFeedback: _sanitizeText(
          decoded['pronunciationFeedback'] as String?,
        ),
      );
    } catch (error) {
      debugPrint('Failed to parse Gemma response: $error');
      return _fallbackParse('error');
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

  AiResponse _fallbackParse(String userText) {
    var reply = '반가워요! 오늘 하루는 어떠셨나요? 특별한 일은 없으셨어요?';
    var score = 80;
    var feedback = '문장이 자연스럽습니다. 다만 끝맺음을 조금 더 명확하게 해주시면 좋을 것 같아요.';

    if (userText.contains('어려워')) {
      reply = '많이 힘드셨군요. 어떤 부분이 가장 어려우셨나요?';
      score = 65;
      feedback = "'어려워' 발음 시 혀의 위치를 조금 더 신경 써보시면 좋겠습니다.";
    }

    return AiResponse(
      replyText: reply,
      pronunciationScore: score,
      pronunciationFeedback: feedback,
    );
  }

  AiResponse _fallbackReadingEvaluation(String targetText, String spokenText) {
    bool isEmpty = spokenText.trim().isEmpty;

    if (targetText.isEmpty) {
      return AiResponse(
        replyText: '자유 읽기 연습을 완료했습니다.',
        pronunciationScore: isEmpty ? 0 : 85,
        pronunciationFeedback: isEmpty
            ? '음성이 감지되지 않았습니다. 마이크 권한을 확인하거나 조금 더 크게 말씀해 보세요.'
            : '전체적으로 명확하게 들립니다. 꾸준히 연습해 보세요!',
      );
    }

    final target = targetText.replaceAll(' ', '');
    final spoken = spokenText.replaceAll(' ', '');

    var score = 80;
    if (isEmpty) {
      score = 0;
    } else if (target == spoken) {
      score = 100;
    } else if (spoken.length < target.length / 2) {
      score = 40;
    } else if (spoken.length < target.length * 0.8) {
      score = 65;
    }

    return AiResponse(
      replyText: '문장 읽기 연습을 완료했습니다.',
      pronunciationScore: score,
      pronunciationFeedback: isEmpty
          ? '목소리가 인식되지 않았습니다. 다시 한 번 읽어주시겠어요?'
          : (score > 90
                ? '거의 완벽하게 읽으셨습니다! 아주 훌륭합니다.'
                : '제시된 문장과 조금 차이가 있습니다. 단어를 하나씩 천천히 다시 읽어보세요.'),
    );
  }

  AiResponse _fallbackPracticeEvaluation(
    PracticeMode mode,
    String targetText,
    String spokenText,
  ) {
    final base = _fallbackReadingEvaluation(targetText, spokenText);
    final feedback = switch (mode) {
      PracticeMode.wordGame =>
        '${base.pronunciationFeedback} 짧은 단어는 입 모양을 먼저 만들고 한 번에 또렷하게 말해 보세요.',
      PracticeMode.shortSentence =>
        '${base.pronunciationFeedback} 문장 끝을 흐리지 않도록 마지막 단어까지 천천히 읽어 보세요.',
      PracticeMode.longSentence =>
        '${base.pronunciationFeedback} 긴 문장은 의미 단위로 끊고 숨을 고른 뒤 이어서 읽어 보세요.',
      PracticeMode.freeSpeech => base.pronunciationFeedback,
    };

    return AiResponse(
      replyText: '${mode.label} 연습을 완료했습니다.',
      pronunciationScore: base.pronunciationScore,
      pronunciationFeedback: feedback,
    );
  }

  AiResponse _wordGameEvaluation(String targetText, String spokenText) {
    final target = _normalizeShortAnswer(targetText);
    final spoken = _normalizeShortAnswer(spokenText);
    final isEmpty = spoken.isEmpty;
    final isExactMatch = target.isNotEmpty && target == spoken;
    final score = isEmpty
        ? 0
        : isExactMatch
        ? 100
        : 40;

    return AiResponse(
      replyText: isExactMatch ? '목표 단어를 정확히 말했습니다.' : '다른 단어로 인식되었습니다.',
      pronunciationScore: score,
      pronunciationFeedback: isEmpty
          ? '음성이 인식되지 않았습니다. 목표 단어 "$targetText"를 조금 더 크게 말해 보세요.'
          : isExactMatch
          ? '목표 단어 "$targetText"가 정확히 인식되었습니다.'
          : '목표 단어 "$targetText"로 인식되지 않았습니다. 인식된 말은 "$spokenText"입니다. 입 모양을 다시 만들고 한 번 더 또렷하게 말해 보세요.',
    );
  }

  String _normalizeShortAnswer(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\uAC00-\uD7A3a-zA-Z0-9]'), '')
        .toLowerCase();
  }

  String _buildReadingPrompt(String targetText, String spokenText) {
    return '''
You are '영은', a professional speech practice coach.
The user's OS language is $_osLanguage. You MUST respond in $_osLanguage.
The user is practicing reading a specific sentence aloud.

Target Sentence: "$targetText"
User Spoke: "$spokenText"

Goals:
1. Compare the 'User Spoke' text with the 'Target Sentence'.
2. Identify any mispronunciations, omissions, or additions.
3. Provide an encouraging but objective pronunciation score (0-100).
4. Provide one specific tip to improve the pronunciation of this specific sentence in $_osLanguage.

Respond ONLY as JSON with this exact shape:
{
  "replyText": "Encouraging summary of the attempt in $_osLanguage",
  "pronunciationScore": 0-100,
  "pronunciationFeedback": "Specific tip for improvement in $_osLanguage"
}
''';
  }

  String _buildFreeReadingPrompt(String spokenText) {
    return '''
You are '영은', a professional speech practice coach.
The user's OS language is $_osLanguage. You MUST respond in $_osLanguage.
The user is speaking freely without a target sentence.

User Spoke: "$spokenText"

Goals:
1. Evaluate the clarity, articulation, and naturalness of the 'User Spoke' text.
2. Provide an encouraging but objective pronunciation/fluency score (0-100).
3. Provide one specific tip for clearer or more natural speech in $_osLanguage based on what the user said.

Respond ONLY as JSON with this exact shape:
{
  "replyText": "Feedback on the content and delivery in $_osLanguage",
  "pronunciationScore": 0-100,
  "pronunciationFeedback": "Specific tip for clearer speech in $_osLanguage"
}
''';
  }

  String _buildModePrompt({
    required PracticeMode mode,
    required String targetText,
    required String spokenText,
    required int durationSeconds,
  }) {
    final modeGoal = switch (mode) {
      PracticeMode.wordGame =>
        'Focus on whether the single target word was spoken clearly and completely.',
      PracticeMode.shortSentence =>
        'Focus on sentence clarity, omitted words, changed words, and speaking pace.',
      PracticeMode.longSentence =>
        'Focus on completion, breathing, pauses, phrasing, and rhythm across the longer sentence.',
      PracticeMode.freeSpeech =>
        'Focus on communication clarity and a helpful next practice suggestion.',
    };

    return '''
You are '영은', a professional speech practice coach.
The user's OS language is $_osLanguage. You MUST respond in $_osLanguage.
The user is practicing in this mode: ${mode.label}.

Target Text: "$targetText"
User Spoke: "$spokenText"
Duration Seconds: $durationSeconds

Mode-specific goal:
$modeGoal

Goals:
1. Compare the user speech with the target text when a target exists.
2. Score objectively from 0 to 100. Do not overpraise.
3. Provide one concrete, mode-specific pronunciation or speaking tip in $_osLanguage.
4. For long sentences, mention breathing or phrase breaks when useful.
5. For word practice, mention the target word and whether it was clear.

Respond ONLY as JSON with this exact shape:
{
  "replyText": "Short result summary in $_osLanguage",
  "pronunciationScore": 0-100,
  "pronunciationFeedback": "Specific mode-aware tip in $_osLanguage"
}
''';
  }
}

class AiResponse {
  const AiResponse({
    required this.replyText,
    required this.pronunciationScore,
    required this.pronunciationFeedback,
    this.phonemeAccuracy,
    this.intonationFeedback,
  });

  final String replyText;
  final int pronunciationScore;
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
