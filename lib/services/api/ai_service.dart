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
You are '영은', a friendly language rehabilitation assistant in Korean.
The user said: "$userText".
1. Give a conversational reply.
2. Provide a pronunciation score out of 100 based on standard Korean grammar and naturalness of the sentence text.
3. Provide brief pronunciation and speech feedback.
Respond ONLY as JSON with this exact shape:
{
  "replyText": "your reply here",
  "pronunciationScore": 85,
  "pronunciationFeedback": "your feedback here"
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
      return AiResponse(
        replyText: '무슨 말씀이신지 이해했어요.',
        pronunciationScore: 80,
        pronunciationFeedback: '기본적인 전달력이 좋습니다.',
      );
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
      return '의사소통이 원활할 수 있도록 연습해 보아요.';
    }

    return normalized;
  }

  AiResponse _fallbackParse(String userText) {
    var reply = '안녕하세요! 발음이 아주 좋으시네요. 어떤 이야기를 나누고 싶으신가요?';
    var score = 85;
    var feedback = '전반적으로 훌륭하지만, 약간의 억양 교정이 필요할 수 있습니다.';

    if (userText.contains('어려워')) {
      reply = '천천히 다시 해보세요. 제가 도와드릴게요.';
      score = 60;
      feedback = "'어려워'라는 단어의 '려' 발음을 명확하게 해보세요.";
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
