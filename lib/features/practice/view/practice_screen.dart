import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/practice_provider.dart';
import '../../chat/provider/chat_provider.dart';
import '../../chat/view/widgets/feedback_card.dart';
import '../../chat/view/widgets/animated_orb.dart';
import '../../../services/api/ai_service.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(practiceProvider);
    final notifier = ref.read(practiceProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('소리 내어 읽기 연습'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.pushNamed(context, '/dashboard');
            },
            tooltip: '성과 대시보드',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/practice_history');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildModeSelector(ref, practice.isFreeMode),
              const SizedBox(height: 20),
              _buildTargetCard(context, ref, practice),
              const SizedBox(height: 40),
              // Changed from Expanded to a fixed/min height for scrolling compatibility
              Container(
                constraints: const BoxConstraints(minHeight: 250),
                child: Center(
                  child: _buildInteractionArea(context, ref, practice, notifier),
                ),
              ),
              const SizedBox(height: 20),
              if (practice.feedback != null) ...[
                FeedbackCard(
                  aiResponse: practice.feedback!,
                  onDismiss: () => notifier.dismissFeedback(),
                ),
                const SizedBox(height: 20),
              ],
              if (practice.state == PracticeState.completed)
                _buildActionButtons(practice, notifier),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(WidgetRef ref, bool isFreeMode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(ref, '문장 연습', !isFreeMode),
          _buildModeButton(ref, '자유 읽기', isFreeMode),
        ],
      ),
    );
  }

  Widget _buildModeButton(WidgetRef ref, String label, bool isSelected) {
    return GestureDetector(
      onTap: isSelected ? null : () => ref.read(practiceProvider.notifier).toggleFreeMode(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetCard(BuildContext context, WidgetRef ref, PracticeProgress practice) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                practice.isFreeMode ? '다루고 싶은 주제로 말해보세요:' : '따라 읽어보세요:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              if (!practice.isFreeMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu_book, color: Colors.blueAccent, size: 20),
                      onPressed: () => _showTextInputDialog(context, ref),
                      tooltip: '연습할 문장 입력',
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white54, size: 20),
                      onPressed: () => ref.read(practiceProvider.notifier).nextSentence(),
                      tooltip: '다음 문장',
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            practice.isFreeMode ? '어제 있었던 일이나 오늘 기분,\n좋아하는 주제로 편하게 말씀해 보세요.' : practice.targetText,
            style: TextStyle(
              color: practice.isFreeMode ? Colors.white54 : Colors.white,
              fontSize: practice.isFreeMode ? 18 : 22,
              fontWeight: practice.isFreeMode ? FontWeight.normal : FontWeight.bold,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showTextInputDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('연습할 문장 입력', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '책에서 본 문장을 입력해 보세요...',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(practiceProvider.notifier).setTargetText(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionArea(BuildContext context, WidgetRef ref, PracticeProgress practice, PracticeNotifier notifier) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (practice.spokenText.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  '인식된 내용:',
                  style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.6), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  practice.spokenText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
        
        if (practice.state == PracticeState.analyzing)
          const Column(
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 20),
              Text('AI가 발음을 분석하고 있습니다...', style: TextStyle(color: Colors.white70)),
            ],
          )
        else
          _buildOrbArea(practice, notifier),
      ],
    );
  }

  Widget _buildOrbArea(PracticeProgress practice, PracticeNotifier notifier) {
    // Map PracticeState to ConversationState for AnimatedOrb
    final orbState = switch (practice.state) {
      PracticeState.recording => ConversationState.listening,
      PracticeState.analyzing => ConversationState.thinking,
      _ => ConversationState.idle,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (practice.state == PracticeState.recording) {
              notifier.stopRecording();
            } else {
              notifier.startRecording();
            }
          },
          child: AnimatedOrb(
            state: orbState,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          practice.state == PracticeState.recording ? '듣고 있습니다... 끝내려면 터치하세요' : '구슬을 터치하여 다시 녹음',
          style: TextStyle(
            color: practice.state == PracticeState.recording ? Colors.redAccent : Colors.white54,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(PracticeProgress practice, PracticeNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: practice.isPlaying 
              ? () => notifier.stopPlayback() 
              : () => notifier.playRecording(null),
          icon: Icon(practice.isPlaying ? Icons.stop : Icons.play_arrow),
          label: Text(practice.isPlaying ? '재생 중지' : '내 목소리 듣기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: practice.isPlaying 
                ? Colors.redAccent.withValues(alpha: 0.1) 
                : Colors.white.withValues(alpha: 0.1),
            foregroundColor: practice.isPlaying ? Colors.redAccent : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => notifier.shareRecording(),
          icon: const Icon(Icons.share, size: 20),
          label: const Text('공유'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => notifier.resetPractice(),
          icon: const Icon(Icons.refresh),
          label: const Text('다시 하기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }
}
