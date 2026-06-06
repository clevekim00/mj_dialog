import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/chat/provider/chat_provider.dart';
import 'package:speech_rehab/features/chat/view/widgets/animated_orb.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';

class WordGameScreen extends ConsumerWidget {
  const WordGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(practiceProvider);
    final notifier = ref.read(practiceProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('단어 게임'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.replay_circle_filled_outlined),
            tooltip: '틀린 단어 복습',
            onPressed: () => _startFailedWordReview(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: '성과 대시보드',
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _buildHeader(practice),
            const SizedBox(height: 14),
            _buildDifficultyControls(ref, practice),
            const SizedBox(height: 14),
            _buildFocusSoundControls(ref, practice),
            const SizedBox(height: 14),
            _buildStats(practice),
            const SizedBox(height: 14),
            _buildArena(practice),
            const SizedBox(height: 18),
            _buildStatusChips(practice),
            const SizedBox(height: 18),
            _buildControls(practice, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PracticeProgress practice) {
    final status = switch (practice.wordGameStatus) {
      WordGameStatus.ready => '게임 시작을 누르면 단어가 내려옵니다.',
      WordGameStatus.running => '목표 단어를 말한 뒤 판정하면 맞은 단어가 사라집니다.',
      WordGameStatus.gameOver => '단어가 바닥에 닿아 게임이 끝났습니다.',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_esports_outlined, color: Colors.greenAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyControls(WidgetRef ref, PracticeProgress practice) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildDifficultyButton(ref, '쉬움', practice.wordGameDifficulty, 1),
          _buildDifficultyButton(ref, '보통', practice.wordGameDifficulty, 2),
          _buildDifficultyButton(ref, '집중', practice.wordGameDifficulty, 3),
        ],
      ),
    );
  }

  Widget _buildDifficultyButton(
    WidgetRef ref,
    String label,
    int current,
    int value,
  ) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: isSelected
            ? null
            : () => ref
                  .read(practiceProvider.notifier)
                  .setWordGameDifficulty(value),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.greenAccent.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.greenAccent : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusSoundControls(WidgetRef ref, PracticeProgress practice) {
    final isLocked =
        practice.wordGameStatus == WordGameStatus.running ||
        practice.state == PracticeState.recording ||
        practice.state == PracticeState.analyzing;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_outlined, color: Colors.greenAccent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '중점 발음',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                isLocked ? '게임 중 변경 불가' : '선택 단어 확률 증가',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFocusChipRow(
            label: '자음',
            values: const [
              'ㄱ',
              'ㄴ',
              'ㄷ',
              'ㄹ',
              'ㅁ',
              'ㅂ',
              'ㅅ',
              'ㅈ',
              'ㅊ',
              'ㅋ',
              'ㅌ',
              'ㅍ',
              'ㅎ',
            ],
            selected: practice.wordGameFocusConsonant,
            enabled: !isLocked,
            onSelected: (value) => ref
                .read(practiceProvider.notifier)
                .setWordGameFocusConsonant(value),
          ),
          const SizedBox(height: 10),
          _buildFocusChipRow(
            label: '모음',
            values: const ['ㅏ', 'ㅓ', 'ㅗ', 'ㅜ', 'ㅡ', 'ㅣ', 'ㅐ', 'ㅔ', 'ㅚ', 'ㅟ'],
            selected: practice.wordGameFocusVowel,
            enabled: !isLocked,
            onSelected: (value) => ref
                .read(practiceProvider.notifier)
                .setWordGameFocusVowel(value),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusChipRow({
    required String label,
    required List<String> values,
    required String? selected,
    required bool enabled,
    required ValueChanged<String?> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _buildFocusChip(
              label: '전체',
              selected: selected == null,
              enabled: enabled,
              onTap: () => onSelected(null),
            ),
            for (final value in values)
              _buildFocusChip(
                label: value,
                selected: selected == value,
                enabled: enabled,
                onTap: () => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFocusChip({
    required String label,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled && !selected ? onTap : null,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Colors.greenAccent.withValues(alpha: enabled ? 0.22 : 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Colors.greenAccent.withValues(alpha: enabled ? 0.55 : 0.25)
                : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.greenAccent.withValues(alpha: enabled ? 1 : 0.5)
                : Colors.white54,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStats(PracticeProgress practice) {
    final average = practice.wordGameHits == 0
        ? 0
        : practice.wordGameScore ~/ practice.wordGameHits;
    return Row(
      children: [
        _buildStat('성공', '${practice.wordGameHits}', Colors.greenAccent),
        const SizedBox(width: 8),
        _buildStat('실패', '${practice.wordGameMisses}', Colors.redAccent),
        const SizedBox(width: 8),
        _buildStat('평균', '$average점', Colors.blueAccent),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArena(PracticeProgress practice) {
    const arenaHeight = 360.0;
    return Container(
      height: arenaHeight,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final laneWidth = constraints.maxWidth / 3;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Container(
                  height: 2,
                  color: Colors.redAccent.withValues(alpha: 0.85),
                ),
              ),
              if (practice.wordGameStatus == WordGameStatus.ready)
                const Center(
                  child: Text(
                    '게임 시작',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (practice.wordGameStatus == WordGameStatus.gameOver)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '게임 종료',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '성공 ${practice.wordGameHits}개 · 실패 ${practice.wordGameMisses}개',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              for (final word in practice.fallingWords)
                Positioned(
                  left: word.lane * laneWidth + 8,
                  top: word.progress * (arenaHeight - 58),
                  width: laneWidth - 16,
                  child: _buildFallingWord(
                    word,
                    isTarget: word.item.id == practice.contentId,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFallingWord(FallingWord word, {required bool isTarget}) {
    final color = isTarget ? Colors.greenAccent : Colors.white70;
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTarget
            ? Colors.greenAccent.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        word.item.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChips(PracticeProgress practice) {
    if (practice.wordGameStatus != WordGameStatus.running) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(Icons.gps_fixed, '목표 ${practice.targetText}'),
        _buildChip(Icons.sync_alt_outlined, '움직임 ${practice.movementScore}/5'),
        if (practice.isExercisePattern)
          _buildChip(Icons.fitness_center_outlined, '운동 음절'),
        if (practice.isReviewMode)
          _buildChip(Icons.replay_circle_filled_outlined, '복습'),
        if (practice.wordGameFocusConsonant != null)
          _buildChip(
            Icons.center_focus_strong,
            '자음 ${practice.wordGameFocusConsonant}',
          ),
        if (practice.wordGameFocusVowel != null)
          _buildChip(
            Icons.center_focus_weak,
            '모음 ${practice.wordGameFocusVowel}',
          ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(PracticeProgress practice, PracticeNotifier notifier) {
    if (practice.wordGameStatus != WordGameStatus.running) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => notifier.startFallingWordGame(),
          icon: const Icon(Icons.play_arrow),
          label: Text(
            practice.wordGameStatus == WordGameStatus.gameOver
                ? '다시 시작'
                : '게임 시작',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    final orbState = switch (practice.state) {
      PracticeState.recording => ConversationState.listening,
      PracticeState.analyzing => ConversationState.thinking,
      _ => ConversationState.idle,
    };
    final isBusy = practice.state == PracticeState.analyzing;
    final isRecording = practice.state == PracticeState.recording;
    final recordLabel = isRecording ? '판정하기' : '녹음 시작';
    final recordIcon = isRecording ? Icons.check_circle : Icons.mic;
    void handleRecordTap() {
      if (isBusy) {
        return;
      }
      if (isRecording) {
        notifier.stopRecording();
      } else {
        notifier.startRecording();
      }
    }

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: handleRecordTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: AnimatedOrb(state: orbState),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isBusy
              ? '판정 중입니다'
              : isRecording
              ? '말한 뒤 다시 눌러 판정'
              : '구슬이나 아래 버튼을 눌러 말하세요',
          style: const TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : handleRecordTap,
            icon: Icon(recordIcon),
            label: Text(recordLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecording ? Colors.blueAccent : Colors.white,
              foregroundColor: isRecording ? Colors.white : Colors.black,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
              disabledForegroundColor: Colors.white38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        if (practice.state == PracticeState.error) ...[
          const SizedBox(height: 12),
          _buildRecordingError(),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => notifier.resetFallingWordGame(),
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('그만하기'),
          style: TextButton.styleFrom(foregroundColor: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildRecordingError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '마이크 권한을 확인한 뒤 다시 눌러 주세요.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _startFailedWordReview(BuildContext context, WidgetRef ref) {
    final started = ref.read(practiceProvider.notifier).startFailedWordReview();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(started ? '틀린 단어 복습을 시작합니다.' : '복습할 틀린 단어가 없습니다.'),
      ),
    );
  }
}
