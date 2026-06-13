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
    final failedReviewEntries = notifier.failedWordReviewEntries();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('단어 게임'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music),
            tooltip: '녹음 보관함',
            onPressed: () => Navigator.pushNamed(context, '/recording_library'),
          ),
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
            if (failedReviewEntries.isNotEmpty &&
                practice.wordGameStatus != WordGameStatus.running &&
                !practice.isReviewMode) ...[
              const SizedBox(height: 14),
              _buildFailedWordReviewCard(context, ref, failedReviewEntries),
            ],
            const SizedBox(height: 14),
            _buildDifficultyControls(ref, practice),
            const SizedBox(height: 14),
            _buildFocusSoundControls(ref, practice),
            const SizedBox(height: 14),
            _buildStats(practice),
            const SizedBox(height: 14),
            _buildArena(practice, notifier),
            const SizedBox(height: 18),
            _buildStatusChips(practice),
            const SizedBox(height: 18),
            _buildControls(context, practice, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PracticeProgress practice) {
    final status = switch (practice.wordGameStatus) {
      WordGameStatus.ready =>
        practice.isReviewMode ? '틀린 단어만 모아 다시 연습합니다.' : '게임 시작을 누르면 단어가 내려옵니다.',
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

  Widget _buildFailedWordReviewCard(
    BuildContext context,
    WidgetRef ref,
    List<FailedWordReviewEntry> failedReviewEntries,
  ) {
    final notifier = ref.read(practiceProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.replay_circle_filled_outlined,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '틀린 단어 ${failedReviewEntries.length}개 복습',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '70점 미만이거나 놓친 단어만 모아서 다시 발음하고, 실패했던 녹음도 바로 들어볼 수 있습니다.',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 12),
          ...failedReviewEntries.map(
            (entry) => _buildFailedWordReviewRow(context, entry, notifier),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _startFailedWordReview(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: const Text('틀린 단어만 다시 연습'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedWordReviewRow(
    BuildContext context,
    FailedWordReviewEntry entry,
    PracticeNotifier notifier,
  ) {
    final audioPath = entry.latestAudioPath;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              entry.item.text.characters.first,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.item.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '실패 ${entry.failureCount}회 · 최근 ${entry.latestFailedSession.score}점',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: audioPath == null
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await notifier.playRecording(audioPath);
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? '${entry.item.text} 녹음을 재생합니다.'
                                : '녹음 파일을 재생할 수 없습니다.',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                  },
            icon: Icon(audioPath == null ? Icons.volume_off : Icons.play_arrow),
            label: Text(audioPath == null ? '녹음 없음' : '녹음 듣기'),
            style: TextButton.styleFrom(
              foregroundColor: audioPath == null
                  ? Colors.white30
                  : Colors.redAccent,
              disabledForegroundColor: Colors.white24,
              visualDensity: VisualDensity.compact,
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

  Widget _buildArena(PracticeProgress practice, PracticeNotifier notifier) {
    const arenaHeight = 360.0;
    final isBusy =
        practice.state == PracticeState.recording ||
        practice.state == PracticeState.analyzing;

    void handleWordTap(FallingWord word) {
      debugPrint(
        '[WordGameUI] word tapped: "${word.item.text}" '
        'id=${word.item.id} fallingId=${word.id} '
        'state=${practice.state.name} target=${practice.contentId}',
      );
      if (practice.state == PracticeState.analyzing) {
        debugPrint('[WordGameUI] tap ignored: analyzing');
        return;
      }
      if (practice.state == PracticeState.recording) {
        debugPrint('[WordGameUI] tap stops recording');
        notifier.stopRecording();
        return;
      }
      debugPrint('[WordGameUI] tap starts recording for selected word');
      notifier.selectFallingWord(word.id);
      notifier.startRecording();
    }

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
                    isBusy: isBusy,
                    onTap: () => handleWordTap(word),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFallingWord(
    FallingWord word, {
    required bool isTarget,
    required bool isBusy,
    required VoidCallback onTap,
  }) {
    final color = isTarget ? Colors.greenAccent : Colors.white70;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isBusy && !isTarget ? null : onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isTarget
              ? Colors.greenAccent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.42)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
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
            ),
            if (isTarget) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: isBusy ? '판정 중인 목표 단어' : '지금 말할 목표 단어',
                child: Icon(
                  isBusy ? Icons.hourglass_top : Icons.gps_fixed,
                  color: Colors.greenAccent,
                  size: 14,
                ),
              ),
            ],
          ],
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

  Widget _buildControls(
    BuildContext context,
    PracticeProgress practice,
    PracticeNotifier notifier,
  ) {
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
    void handleOrbTap() {
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
        _buildSpeechOrbButton(
          practice: practice,
          orbState: orbState,
          onTap: handleOrbTap,
        ),
        const SizedBox(height: 14),
        Text(
          isBusy
              ? '판정 중입니다'
              : isRecording
              ? '말한 뒤 말하기 버튼이나 목표 단어를 다시 눌러 판정하세요'
              : '말하기 버튼이나 목표 단어를 눌러 녹음을 시작하세요',
          style: const TextStyle(color: Colors.white54),
        ),
        if (practice.state == PracticeState.error) ...[
          const SizedBox(height: 12),
          _buildRecordingError(),
        ],
        if (practice.feedback != null || practice.lastAudioPath != null) ...[
          const SizedBox(height: 12),
          _buildLatestRecordingControls(context, practice, notifier),
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

  Widget _buildLatestRecordingControls(
    BuildContext context,
    PracticeProgress practice,
    PracticeNotifier notifier,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '방금 발음 녹음',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: practice.lastAudioPath == null
                ? null
                : () async {
                    if (practice.isPlaying) {
                      await notifier.stopPlayback();
                      return;
                    }
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await notifier.playRecording(null);
                    if (!ok) {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('녹음 파일을 재생할 수 없습니다.')),
                        );
                    }
                  },
            icon: Icon(practice.isPlaying ? Icons.stop : Icons.play_arrow),
            label: Text(practice.isPlaying ? '중지' : '듣기'),
            style: TextButton.styleFrom(
              foregroundColor: practice.lastAudioPath == null
                  ? Colors.white30
                  : Colors.greenAccent,
              disabledForegroundColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechOrbButton({
    required PracticeProgress practice,
    required ConversationState orbState,
    required VoidCallback onTap,
  }) {
    final isRecording = practice.state == PracticeState.recording;
    final isAnalyzing = practice.state == PracticeState.analyzing;
    final accent = isRecording
        ? Colors.redAccent
        : isAnalyzing
        ? Colors.amberAccent
        : Colors.greenAccent;
    final icon = isRecording
        ? Icons.stop_rounded
        : isAnalyzing
        ? Icons.hourglass_top_rounded
        : Icons.mic_rounded;
    final label = isRecording
        ? '판정하기'
        : isAnalyzing
        ? '판정 중'
        : '말하기 시작';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildRecognizedSpeechToast(practice),
            ),
            Positioned(bottom: 0, child: AnimatedOrb(state: orbState)),
            Positioned(
              bottom: 52,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withValues(alpha: 0.55)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accent, size: 18),
                    const SizedBox(width: 7),
                    Text(
                      label,
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecognizedSpeechToast(PracticeProgress practice) {
    final spokenText = practice.spokenText.trim();
    final shouldShow =
        practice.state == PracticeState.recording ||
        practice.state == PracticeState.analyzing ||
        practice.feedback != null ||
        practice.speechRecognitionUnavailable ||
        spokenText.isNotEmpty;
    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final text = switch (practice.state) {
      _ when practice.speechRecognitionUnavailable && spokenText.isEmpty =>
        '실시간 인식 권한 필요',
      PracticeState.recording when spokenText.isEmpty => '듣는 중...',
      PracticeState.analyzing when spokenText.isEmpty => '판정 중...',
      _ when spokenText.isNotEmpty => spokenText,
      _ when practice.feedback != null => '인식 없음',
      _ => '',
    };
    final hasResult = spokenText.isNotEmpty;
    final isUnavailable =
        practice.speechRecognitionUnavailable && spokenText.isEmpty;
    final isEmptyResult =
        practice.feedback != null && spokenText.isEmpty && !isUnavailable;
    final color = hasResult
        ? Colors.greenAccent
        : isUnavailable
        ? Colors.amberAccent
        : isEmptyResult
        ? Colors.redAccent
        : Colors.white54;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.hearing_outlined, color: color, size: 18),
          const SizedBox(width: 8),
          const Text(
            '인식된 발음',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
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
