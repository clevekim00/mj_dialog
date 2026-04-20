import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiService {
  const AiService();

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
The user said: "$userText".

Goals:
1. Reply naturally to the user. Always end with a natural follow-up question to keep the conversation moving.
2. Evaluate pronunciation/grammar objectively. Do NOT give excessive praise (e.g., avoid "Perfect!" or "Amazingly great!" if it's just normal). Be honest but encouraging.
3. Provide one specific tip for better speech or pronunciation based on the text.

Respond ONLY as JSON with this exact shape:
{
  "replyText": "your reply with a follow-up question",
  "pronunciationScore": 0-100,
  "pronunciationFeedback": "objective tip or feedback"
}
''';
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
      return '천천히 대화를 이어가 볼까요? 최근에 즐거웠던 일이 있으신가요?';
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
    if (targetText.isEmpty) {
      return AiResponse(
        replyText: '자유 읽기 연습을 완료했습니다.',
        pronunciationScore: spokenText.isEmpty ? 0 : 85,
        pronunciationFeedback: spokenText.isEmpty 
          ? '아무 내용이나 말씀해 보세요. 연습을 시작할 준비가 되었습니다.' 
          : '전체적으로 명확하게 들립니다. 꾸준히 연습해 보세요!',
      );
    }

    final target = targetText.replaceAll(' ', '');
    final spoken = spokenText.replaceAll(' ', '');
    
    int score = 80;
    if (spoken.isEmpty) score = 0;
    else if (target == spoken) score = 100;
    else if (spoken.length < target.length / 2) score = 40;
    else if (spoken.length < target.length * 0.8) score = 65;

    return AiResponse(
      replyText: '문장 읽기 연습을 완료했습니다.',
      pronunciationScore: score,
      pronunciationFeedback: score > 90 
        ? '거의 완벽하게 읽으셨습니다! 아주 훌륭합니다.' 
        : '제시된 문장과 조금 차이가 있습니다. 단어를 하나씩 천천히 다시 읽어보세요.',
    );
  }

  String _buildReadingPrompt(String targetText, String spokenText) {
    return '''
You are '영은', a professional language rehabilitation coach.
The user is practicing reading a specific sentence aloud.

Target Sentence: "$targetText"
User Spoke: "$spokenText"

Goals:
1. Compare the 'User Spoke' text with the 'Target Sentence'.
2. Identify any mispronunciations, omissions, or additions.
3. Provide an encouraging but objective pronunciation score (0-100).
4. Provide one specific tip to improve the pronunciation of this specific sentence.

Respond ONLY as JSON with this exact shape:
{
  "replyText": "Encouraging summary of the attempt",
  "pronunciationScore": 0-100,
  "pronunciationFeedback": "Specific tip for improvement"
}
''';
  }

  String _buildFreeReadingPrompt(String spokenText) {
    return '''
You are '영은', a professional language rehabilitation coach.
The user is speaking freely without a target sentence.

User Spoke: "$spokenText"

Goals:
1. Evaluate the clarity, articulation, and naturalness of the 'User Spoke' text.
2. Provide an encouraging but objective pronunciation/fluency score (0-100).
3. Provide one specific tip for clearer or more natural speech based on what the user said.

Respond ONLY as JSON with this exact shape:
{
  "replyText": "Feedback on the content and delivery",
  "pronunciationScore": 0-100,
  "pronunciationFeedback": "Specific tip for clearer speech"
}
''';
  }
}


class AiResponse {
  const AiResponse({
    required this.replyText,
    required this.pronunciationScore,
    required this.pronunciationFeedback,
  });

  final String replyText;
  final int pronunciationScore;
  final String pronunciationFeedback;
}
