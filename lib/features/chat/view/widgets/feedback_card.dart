import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:speech_rehab/services/api/ai_service.dart';

class FeedbackCard extends StatelessWidget {
  final AiResponse aiResponse;
  final VoidCallback onDismiss;

  const FeedbackCard({
    super.key,
    required this.aiResponse,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color scoreColor = Colors.greenAccent;
    if (aiResponse.pronunciationScore < 60) {
      scoreColor = Colors.redAccent;
    } else if (aiResponse.pronunciationScore < 80) {
      scoreColor = Colors.orangeAccent;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '발음 피드백',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scoreColor),
                    ),
                    child: Text(
                      '${aiResponse.pronunciationScore} 점',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'AI의 응답:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                aiResponse.replyText,
                style: const TextStyle(fontSize: 18, color: Colors.white, height: 1.5),
              ),
              const SizedBox(height: 24),
              Text(
                '코칭 조언:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                aiResponse.pronunciationFeedback,
                style: TextStyle(fontSize: 16, color: Colors.blue[100], height: 1.5),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('닫기'),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
