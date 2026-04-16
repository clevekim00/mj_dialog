import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mj_dialog/features/chat/provider/chat_provider.dart';
import 'package:mj_dialog/features/chat/view/widgets/animated_orb.dart';
import 'package:mj_dialog/features/chat/view/widgets/feedback_card.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();

  bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  bool get _isVoiceSupported => !_isDesktop;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitText(WidgetRef ref) {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _textController.clear();
    ref.read(chatControllerProvider.notifier).submitText(text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      chatControllerProvider.select((session) => session.errorMessage),
      (previous, next) {
        if (next == null || next == previous) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next)));
        ref.read(chatControllerProvider.notifier).clearError();
      },
    );

    final session = ref.watch(chatControllerProvider);
    final state = session.conversationState;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.graphic_eq,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gemma AI Coach',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: AnimatedOrb(state: state),
            ),
            Positioned(
              bottom: _isDesktop ? 180 : 160,
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
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
              bottom: state == ConversationState.feedback ? 120 : -400,
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
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: _isDesktop
                  ? _buildDesktopInput(ref, session)
                  : _buildMobileMic(ref, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopInput(WidgetRef ref, ChatSessionState session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: session.isProcessing ? '처리 중...' : '메시지를 입력하세요...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              enabled: !session.isProcessing,
              onSubmitted: (_) => _submitText(ref),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: session.isProcessing ? null : () => _submitText(ref),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: session.isProcessing ? Colors.grey[700] : Colors.white,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 22,
                color: session.isProcessing ? Colors.grey[500] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMic(WidgetRef ref, ConversationState state) {
    return Center(
      child: GestureDetector(
        onTap: () {
          ref.read(chatControllerProvider.notifier).toggleVoiceInput(
                isVoiceSupported: _isVoiceSupported,
              );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                state == ConversationState.listening ? Colors.red[400] : Colors.white,
            boxShadow: [
              BoxShadow(
                color:
                    (state == ConversationState.listening ? Colors.red : Colors.white)
                        .withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            state == ConversationState.listening
                ? Icons.stop_rounded
                : Icons.mic_rounded,
            size: 32,
            color:
                state == ConversationState.listening ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
