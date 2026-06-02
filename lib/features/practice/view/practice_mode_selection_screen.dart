import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/chat/provider/chat_provider.dart';
import 'package:speech_rehab/features/chat/view/chat_screen.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';

class PracticeModeSelectionScreen extends ConsumerWidget {
  const PracticeModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(practiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('연습 선택'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _buildTodaySummary(practice),
          const SizedBox(height: 18),
          _buildModeCard(
            context: context,
            icon: Icons.sports_esports_outlined,
            title: '단어 게임',
            subtitle: '짧은 단어를 큰 글자로 보고 또렷하게 말해요.',
            color: Colors.greenAccent,
            onTap: () => _openPractice(context, ref, PracticeMode.wordGame),
          ),
          _buildModeCard(
            context: context,
            icon: Icons.short_text,
            title: '짧은 문장 읽기',
            subtitle: '일상에서 바로 쓰는 짧은 표현을 반복해요.',
            color: Colors.blueAccent,
            onTap: () =>
                _openPractice(context, ref, PracticeMode.shortSentence),
          ),
          _buildModeCard(
            context: context,
            icon: Icons.notes_outlined,
            title: '긴 문장 읽기',
            subtitle: '호흡과 끊어 읽기를 함께 연습해요.',
            color: Colors.orangeAccent,
            onTap: () => _openPractice(context, ref, PracticeMode.longSentence),
          ),
          _buildModeCard(
            context: context,
            icon: Icons.forum_outlined,
            title: '자유 대화',
            subtitle: '정해진 문장 없이 실제 상황처럼 말해요.',
            color: Colors.purpleAccent,
            onTap: () {
              ref.read(chatControllerProvider.notifier).createNewSession();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary(PracticeProgress practice) {
    final today = DateTime.now();
    final todayCount = practice.history.where((session) {
      return session.timestamp.year == today.year &&
          session.timestamp.month == today.month &&
          session.timestamp.day == today.day;
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.today_outlined, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              todayCount == 0
                  ? '오늘은 아직 구조화된 연습 기록이 없습니다.'
                  : '오늘 $todayCount회 연습했습니다.',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  void _openPractice(BuildContext context, WidgetRef ref, PracticeMode mode) {
    ref.read(practiceProvider.notifier).setMode(mode);
    Navigator.pushNamed(context, '/practice');
  }
}
