import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mj_dialog/services/api/ai_service.dart';
import 'package:mj_dialog/services/audio/stt_service.dart';
import 'package:mj_dialog/services/audio/tts_service.dart';
import 'package:mj_dialog/features/chat/provider/chat_provider.dart';
import 'package:mj_dialog/features/chat/view/widgets/animated_orb.dart';
import 'package:mj_dialog/features/chat/view/widgets/feedback_card.dart';
import 'dart:io' show Platform;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  
  bool get _isDesktop => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  void _toggleVoiceInput() async {
    if (_isDesktop) {
      // Desktop: STT not reliable, use text input instead
      return;
    }
    
    final sttService = ref.read(sttServiceProvider);
    final currentState = ref.read(conversationStateProvider);

    if (currentState == ConversationState.idle || currentState == ConversationState.feedback) {
      ref.read(conversationStateProvider.notifier).updateState(ConversationState.listening);
      ref.read(sttLiveTextProvider.notifier).updateText('');
      
      bool success = await sttService.init();
      if (success) {
        sttService.startListening(onResult: (text, isFinal) {
          ref.read(sttLiveTextProvider.notifier).updateText(text);
          if (isFinal) {
            _processInput(text);
          }
        });
      } else {
        ref.read(conversationStateProvider.notifier).updateState(ConversationState.idle);
      }
    } else if (currentState == ConversationState.listening) {
      final lastText = ref.read(sttLiveTextProvider);
      await sttService.stopListening();
      _processInput(lastText);
    }
  }

  void _submitText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(sttLiveTextProvider.notifier).updateText(text);
    _processInput(text);
  }

  Future<void> _processInput(String text) async {
    if (text.trim().isEmpty) {
      ref.read(conversationStateProvider.notifier).updateState(ConversationState.idle);
      return;
    }

    ref.read(conversationStateProvider.notifier).updateState(ConversationState.thinking);
    
    final aiService = ref.read(aiServiceProvider);
    final ttsService = ref.read(ttsServiceProvider);

    try {
      final aiResult = await aiService.getResponseAndFeedback(text);
      
      ref.read(conversationStateProvider.notifier).updateState(ConversationState.speaking);
      ref.read(sttLiveTextProvider.notifier).updateText(aiResult.replyText);
      
      await ttsService.speak(aiResult.replyText);
      await Future.delayed(const Duration(seconds: 2)); 
      
      ref.read(aiFeedbackProvider.notifier).updateFeedback(aiResult);
      ref.read(conversationStateProvider.notifier).updateState(ConversationState.feedback);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      ref.read(conversationStateProvider.notifier).updateState(ConversationState.idle);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationStateProvider);
    final liveText = ref.watch(sttLiveTextProvider);
    final feedback = ref.watch(aiFeedbackProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Header
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.graphic_eq, color: Colors.white.withValues(alpha: 0.5)),
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

            // Central Orb
            Center(
              child: AnimatedOrb(state: state),
            ),

            // Live Text Display
            Positioned(
              bottom: _isDesktop ? 180 : 160,
              left: 32,
              right: 32,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: liveText.isNotEmpty || state == ConversationState.listening ? 1.0 : 0.0,
                child: Text(
                  liveText.isEmpty ? "듣고 있어요..." : liveText,
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

            // Feedback Card
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
              bottom: state == ConversationState.feedback ? 120 : -400,
              left: 24,
              right: 24,
              child: feedback != null
                  ? FeedbackCard(
                      aiResponse: feedback,
                      onDismiss: () {
                        ref.read(conversationStateProvider.notifier).updateState(ConversationState.idle);
                        ref.read(sttLiveTextProvider.notifier).updateText('');
                      },
                    )
                  : const SizedBox.shrink(),
            ),

            // Bottom Controls
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: _isDesktop ? _buildDesktopInput(state) : _buildMobileMic(state),
            ),
          ],
        ),
      ),
    );
  }

  /// Desktop: text field + send button
  Widget _buildDesktopInput(ConversationState state) {
    final isProcessing = state == ConversationState.thinking || state == ConversationState.speaking;
    
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
                hintText: isProcessing ? '처리 중...' : '메시지를 입력하세요...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              enabled: !isProcessing,
              onSubmitted: (_) => _submitText(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isProcessing ? null : _submitText,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isProcessing ? Colors.grey[700] : Colors.white,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 22,
                color: isProcessing ? Colors.grey[500] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile: mic button for voice input
  Widget _buildMobileMic(ConversationState state) {
    return Center(
      child: GestureDetector(
        onTap: _toggleVoiceInput,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state == ConversationState.listening ? Colors.red[400] : Colors.white,
            boxShadow: [
              BoxShadow(
                color: (state == ConversationState.listening ? Colors.red : Colors.white)
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Icon(
            state == ConversationState.listening ? Icons.stop_rounded : Icons.mic_rounded,
            size: 32,
            color: state == ConversationState.listening ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
