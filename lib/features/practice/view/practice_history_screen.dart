import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/practice_provider.dart';

class PracticeHistoryScreen extends ConsumerWidget {
  const PracticeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(practiceProvider);
    final notifier = ref.read(practiceProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('연습 기록'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: practice.history.isEmpty
          ? const Center(
              child: Text(
                '아직 연습 기록이 없습니다.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: practice.history.length,
              itemBuilder: (context, index) {
                final session = practice.history[index];
                return _buildHistoryCard(context, session, notifier);
              },
            ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, dynamic session, PracticeNotifier notifier) {
    final dateStr = DateFormat('yyyy.MM.dd HH:mm').format(session.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getScoreColor(session.score).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getScoreColor(session.score)),
                    ),
                    child: Text(
                      '${session.score}점',
                      style: TextStyle(
                        color: _getScoreColor(session.score),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
                    onPressed: () => _confirmDeletion(context, notifier, session.id),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
             session.targetText,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '인식된 발음: "${session.spokenText}"',
            style: const TextStyle(color: Colors.blueAccent, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  session.feedback,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.play_circle_fill, color: Colors.white70, size: 32),
                onPressed: () => notifier.playRecording(session.audioFilePath),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeletion(BuildContext context, PracticeNotifier notifier, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('기록 삭제', style: TextStyle(color: Colors.white)),
        content: const Text('이 연습 기록을 정말 삭제하시겠습니까?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              notifier.deleteSession(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('기록이 삭제되었습니다.')),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.greenAccent;
    if (score >= 70) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
