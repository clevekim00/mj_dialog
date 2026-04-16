import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/chat/provider/chat_provider.dart';
import 'package:speech_rehab/features/chat/view/widgets/animated_orb.dart';
import 'package:speech_rehab/features/chat/view/widgets/feedback_card.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(
      chatControllerProvider.select((session) => session.errorMessage),
      (previous, next) {
        if (next == null || next == previous) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next)));
        ref.read(chatControllerProvider.notifier).clearError();
      },
    );

    final session = ref.watch(chatControllerProvider);
    final state = session.conversationState;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // Top Bar with Back Button
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.graphic_eq,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SPEECH REHAB',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48), // Spacer to balance back button
                ],
              ),
            ),

            // Central Orb - The focus of the conversation
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedOrb(state: state),
                  const SizedBox(height: 48),
                  // Helpful status text
                  Text(
                    _getStatusText(state),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Live Text / Response Text Display - Higher for readability
            Positioned(
              bottom: 220,
              left: 32,
              right: 32,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: session.liveText.isNotEmpty ||
                        state == ConversationState.listening
                    ? 1.0
                    : 0.0,
                child: Text(
                  session.liveText.isEmpty ? '듣고 있어요...' : session.liveText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ),

            // Feedback Card
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
              bottom: state == ConversationState.feedback ? 160 : -400,
              left: 24,
              right: 24,
              child: session.feedback != null
                  ? FeedbackCard(
                      aiResponse: session.feedback!,
                      onDismiss: () {
                        ref.read(chatControllerProvider.notifier).dismissFeedback();
                      },
                    )
                  : const SizedBox.shrink(),
            ),

            // Bottom Mic Button - Simplified, no text input
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: _buildMicButton(ref, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(ConversationState state) {
    switch (state) {
      case ConversationState.idle:
        return '준비되었어요';
      case ConversationState.listening:
        return '말씀해 주세요';
      case ConversationState.thinking:
        return '생각 중이에요';
      case ConversationState.speaking:
        return '말하는 중이에요';
      case ConversationState.feedback:
        return '피드백 확인 중';
    }
  }

  Widget _buildMicButton(WidgetRef ref, ConversationState state) {
    final isListening = state == ConversationState.listening;

    return GestureDetector(
      onTap: () {
        ref.read(chatControllerProvider.notifier).toggleVoiceInput(
              isVoiceSupported: true,
            );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening ? Colors.redAccent : Colors.white10,
              border: Border.all(
                color: isListening ? Colors.redAccent : Colors.white24,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isListening ? Colors.redAccent : Colors.white10)
                      .withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.mic_rounded,
              size: 40,
              color: isListening ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isListening ? '완료하려면 탭' : '탭하여 시작',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
