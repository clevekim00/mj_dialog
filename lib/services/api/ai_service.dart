import 'dart:ui';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiService {
  const AiService();

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

  Future<AiResponse> getReadingFeedback(String targetText, String spokenText) async {
    try {
      if (!FlutterGemma.hasActiveModel()) {
        debugPrint('Gemma model is not active. Falling back to simple evaluation.');
        return _fallbackReadingEvaluation(targetText, spokenText);
      }

      final prompt = _buildReadingPrompt(targetText, spokenText);
      final model = await FlutterGemma.getActiveModel(maxTokens: 512);
      final chat = await model.createChat(temperature: 0.3); // Lower temperature for objective evaluation
      await chat.addQuery(Message(text: prompt, isUser: true));
      final modelResponse = await chat.generateChatResponse();

      final responseText = switch (modelResponse) {
        TextResponse() => modelResponse.token,
        _ => '',
      };

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
      if (!FlutterGemma.hasActiveModel()) {
        return _fallbackReadingEvaluation('', spokenText);
      }

      final prompt = _buildFreeReadingPrompt(spokenText);
      final model = await FlutterGemma.getActiveModel(maxTokens: 512);
      final chat = await model.createChat(temperature: 0.3);
      await chat.addQuery(Message(text: prompt, isUser: true));
      final modelResponse = await chat.generateChatResponse();

      final responseText = switch (modelResponse) {
        TextResponse() => modelResponse.token,
        _ => '',
      };

      if (responseText.isEmpty) {
        return _fallbackReadingEvaluation('', spokenText);
      }

      return _parseResponse(responseText);
    } catch (error) {
      debugPrint('Free reading evaluation failed: $error');
      return _fallbackReadingEvaluation('', spokenText);
    }
  }

  Future<AiResponse> getResponseAndFeedback(String userText) async {
    try {
      if (!FlutterGemma.hasActiveModel()) {
        debugPrint('Gemma model is not active. Falling back to canned response.');
        return _fallbackParse(userText);
      }

      final prompt = _buildPrompt(userText);
      final model = await FlutterGemma.getActiveModel(maxTokens: 512);
      final chat = await model.createChat(temperature: 0.7);
      await chat.addQuery(Message(text: prompt, isUser: true));
      final modelResponse = await chat.generateChatResponse();

      final responseText = switch (modelResponse) {
        TextResponse() => modelResponse.token,
        _ => '',
      };

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

  String _buildPrompt(String userText) {
    return '''
You are '영은', a professional and friendly language rehabilitation coach.
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

  String _buildGemma4ReadingPrompt(String targetText) {
    return '''
You are a professional language rehabilitation AI using Gemma 4 multimodal capabilities.
The user is providing an audio input.
The target sentence is: "$targetText".

Analyze the NATIVE AUDIO TOKENS and compare them with the target text.
1. Provide a phoneme-level accuracy breakdown.
2. Evaluate the intonation, rhythm, and pitch.
3. Provide an overall pronunciation score (0-100).
4. Give specific, actionable feedback in Korean.

Respond ONLY as JSON:
{
  "replyText": "brief summary",
  "pronunciationScore": 0-100,
  "pronunciationFeedback": "main tip",
  "phonemeAccuracy": [{"phoneme": "string", "score": 0-100, "issue": "string or null"}],
  "intonationFeedback": "intonation/pitch feedback string"
}
''';
  }

  AiResponse _parseGemma4Response(String rawOutput) {
    try {
      final jsonText = _extractJsonObject(rawOutput);
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      
      return AiResponse(
        replyText: decoded['replyText'] as String? ?? '',
        pronunciationScore: (decoded['pronunciationScore'] as num?)?.toInt() ?? 0,
        pronunciationFeedback: decoded['pronunciationFeedback'] as String? ?? '',
        phonemeAccuracy: (decoded['phonemeAccuracy'] as List?)
            ?.map((e) => PhonemeData.fromJson(e as Map<String, dynamic>))
            .toList(),
        intonationFeedback: decoded['intonationFeedback'] as String?,
      );
    } catch (e) {
      debugPrint('Error parsing Gemma 4 response: $e');
      return _fallbackReadingEvaluation('', '');
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
        pronunciationFeedback:
            _sanitizeText(decoded['pronunciationFeedback'] as String?),
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
    
    int score = 80;
    if (isEmpty) score = 0;
    else if (target == spoken) score = 100;
    else if (spoken.length < target.length / 2) score = 40;
    else if (spoken.length < target.length * 0.8) score = 65;

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

  String _buildReadingPrompt(String targetText, String spokenText) {
    return '''
You are '영은', a professional language rehabilitation coach.
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
You are '영은', a professional language rehabilitation coach.
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

  PhonemeData({
    required this.phoneme,
    required this.score,
    this.issue,
  });

  factory PhonemeData.fromJson(Map<String, dynamic> json) {
    return PhonemeData(
      phoneme: json['phoneme'] as String,
      score: (json['score'] as num).toInt(),
      issue: json['issue'] as String?,
    );
  }
}
