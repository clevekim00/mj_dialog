import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_rehab/features/chat/provider/chat_provider.dart';
import 'package:speech_rehab/features/chat/view/chat_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(chatControllerProvider);
    final sessions = sessionState.sessions;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('대화 히스토리'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
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
      ),
      body: sessions.isEmpty
          ? const Center(
              child: Text(
                '저장된 대화가 없습니다.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isCurrent = session.id == sessionState.currentSessionId;
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
                      '$dateStr • 메시지 ${session.messages.length}개',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check, color: Colors.blueAccent, size: 16)
                        : null,
                    onTap: () {
                      ref.read(chatControllerProvider.notifier).switchSession(session.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
