import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiService {
  const AiService();

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
