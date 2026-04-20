import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_rehab/features/chat/provider/chat_provider.dart';
import 'package:speech_rehab/features/chat/view/chat_screen.dart';

import 'package:flutter/cupertino.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';
import 'package:speech_rehab/services/practice_history_service.dart';

final historyTabProvider = NotifierProvider<HistoryTabNotifier, int>(HistoryTabNotifier.new);

class HistoryTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int value) => state = value;
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(chatControllerProvider);
    final practiceState = ref.watch(practiceProvider);
    final selectedTab = ref.watch(historyTabProvider);

    // Combine both types of sessions
    final List<dynamic> combinedHistory = [
      ...sessionState.sessions,
      ...practiceState.history,
    ];

    // Sort by date (descending)
    combinedHistory.sort((a, b) {
      final dateA = (a is ChatSession) ? a.createdAt : (a as PracticeSession).timestamp;
      final dateB = (b is ChatSession) ? b.createdAt : (b as PracticeSession).timestamp;
      return dateB.compareTo(dateA);
    });

    final filteredHistory = selectedTab == 0
        ? combinedHistory
        : combinedHistory.where((item) => item is PracticeSession).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('히스토리'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.record_voice_over),
            tooltip: '읽기 연습',
            onPressed: () {
              Navigator.pushNamed(context, '/practice');
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ref.read(chatControllerProvider.notifier).createNewSession();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: selectedTab,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              thumbColor: Colors.white.withValues(alpha: 0.1),
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('전체', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('연습 기록', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
              },
              onValueChanged: (value) {
                if (value != null) ref.read(historyTabProvider.notifier).setTab(value);
              },
            ),
          ),
        ),
      ),
      body: filteredHistory.isEmpty
          ? const Center(
              child: Text(
                '기록이 없습니다.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                final item = filteredHistory[index];
                
                if (item is ChatSession) {
                  return _buildChatSessionItem(context, ref, item, sessionState.currentSessionId);
                } else {
                  return _buildPracticeSessionItem(context, ref, item as PracticeSession);
                }
              },
            ),
    );
  }

  Widget _buildChatSessionItem(BuildContext context, WidgetRef ref, ChatSession session, String? currentId) {
    final isCurrent = session.id == currentId;
    final dateStr = DateFormat('MM월 dd일 HH:mm').format(session.createdAt);

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent.withValues(alpha: 0.2),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (_) {
        ref.read(chatControllerProvider.notifier).deleteSession(session.id);
      },
      child: ListTile(
        leading: Icon(
          Icons.chat_bubble_outline,
          color: isCurrent ? Colors.blueAccent : Colors.white24,
        ),
        title: Text(
          session.title,
          style: TextStyle(
            color: isCurrent ? Colors.white : Colors.white70,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'AI 대화 • $dateStr',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        onTap: () {
          ref.read(chatControllerProvider.notifier).switchSession(session.id);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          );
        },
      ),
    );
  }

  Widget _buildPracticeSessionItem(BuildContext context, WidgetRef ref, PracticeSession session) {
    final dateStr = DateFormat('MM월 dd일 HH:mm').format(session.timestamp);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.record_voice_over, color: Colors.blueAccent, size: 20),
      ),
      title: Text(
        session.targetText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PRACTICE',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$dateStr • ${session.score}점',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, '/practice_history');
      },
    );
  }
}
