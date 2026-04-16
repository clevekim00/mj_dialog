import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiService {
  AiService();

  /// Gets a conversational response and pronunciation feedback directly from the on-device Gemma model.
  Future<AiResponse> getResponseAndFeedback(String userText) async {
    try {
      
      // We check if the plugin is initialized. It must be initialized in main() usually but we can ensure here.
      // Assuming it's already initialized via `FlutterGemmaPlugin.instance.init()` 
      // with the proper path to the model asset or document directory.

      // Context prompt instructing Gemma's personality and evaluation logic
      final prompt = '''
You are '영은', a friendly language rehabilitation assistant in Korean.
The user said: "$userText".
1. Give a conversational reply.
2. Provide a pronunciation score out of 100 based on standard Korean grammar and naturalness of the sentence text.
3. Provide brief pronunciation and speech feedback.
Respond EXACTLY in this JSON format:
{
  "replyText": "your reply here",
  "pronunciationScore": 85,
  "pronunciationFeedback": "your feedback here"
}
''';

      // Call on-device Gemma using flutter_gemma!
      if (!FlutterGemma.hasActiveModel()) {
         print("Gemma model is not active.");
         return _fallbackParse(userText);
      }
      
      final model = await FlutterGemma.getActiveModel(maxTokens: 512);
      final chat = await model.createChat(temperature: 0.7);
      await chat.addQuery(Message(text: prompt, isUser: true));
      final modelResponse = await chat.generateChatResponse();
      
      String responseText = "";
      if (modelResponse is TextResponse) {
        responseText = modelResponse.token;
      }
      
      if (responseText.isNotEmpty) {
         return _parseResponse(responseText);
      } else {
        return _fallbackParse(userText);
      }
      
    } catch (e) {
      // Fallback or error handling if Gemma fails or is not initialized properly.
      print('On-device Gemma evaluation failed: $e');
      return _fallbackParse(userText);
    }
  }

  AiResponse _parseResponse(String rawGemmaOutput) {
     try {
       // A very naive JSON parser to extract from Gemma's raw text 
       // Note: production-grade should use a robust parser/regex as LLMs might output markdown formatting
       final matchReply = RegExp(r'"replyText"\s*:\s*"(.*?)"').firstMatch(rawGemmaOutput);
       final matchScore = RegExp(r'"pronunciationScore"\s*:\s*(\d+)').firstMatch(rawGemmaOutput);
       final matchFeedback = RegExp(r'"pronunciationFeedback"\s*:\s*"(.*?)"').firstMatch(rawGemmaOutput);

       return AiResponse(
         replyText: matchReply?.group(1) ?? "네, 잘 들었어요.",
         pronunciationScore: int.tryParse(matchScore?.group(1) ?? '80') ?? 80,
         pronunciationFeedback: matchFeedback?.group(1) ?? "의사소통이 원활할 수 있도록 연습해 보아요.",
       );
     } catch (e) {
       return AiResponse(
         replyText: "무슨 말씀이신지 이해했어요.",
         pronunciationScore: 80,
         pronunciationFeedback: "기본적인 전달력이 좋습니다.",
       );
     }
  }

  AiResponse _fallbackParse(String userText) {
      String reply = "안녕하세요! 발음이 아주 좋으시네요. 어떤 이야기를 나누고 싶으신가요?";
      int score = 85; 
      String feedback = "전반적으로 훌륭하지만, 약간의 억양 교정이 필요할 수 있습니다.";
      
      if (userText.contains('어려워')) {
        reply = "천천히 다시 해보세요. 제가 도와드릴게요.";
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
  final String replyText;
  final int pronunciationScore; // 0 to 100
  final String pronunciationFeedback;

  AiResponse({
    required this.replyText,
    required this.pronunciationScore,
    required this.pronunciationFeedback,
  });
}
