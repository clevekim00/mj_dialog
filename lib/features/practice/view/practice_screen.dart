import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/services/practice_content_service.dart';
import '../model/practice_mode.dart';
import '../provider/practice_provider.dart';
import '../../chat/provider/chat_provider.dart';
import '../../chat/view/widgets/feedback_card.dart';
import '../../chat/view/widgets/animated_orb.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(practiceProvider);
    final notifier = ref.read(practiceProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text(practice.mode.label),
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
              _buildRehabSessionCard(ref, practice),
              const SizedBox(height: 20),
              _buildModeSelector(ref, practice.mode),
              if (practice.mode == PracticeMode.wordGame) ...[
                const SizedBox(height: 14),
                _buildWordGameControls(ref, practice),
              ],
              if (practice.mode == PracticeMode.longSentence) ...[
                const SizedBox(height: 14),
                _buildLongSentenceTools(context, ref),
              ],
              const SizedBox(height: 20),
              _buildTargetCard(context, ref, practice),
              const SizedBox(height: 40),
              // Changed from Expanded to a fixed/min height for scrolling compatibility
              Container(
                constraints: const BoxConstraints(minHeight: 210),
                child: Center(
                  child: _buildInteractionArea(
                    context,
                    ref,
                    practice,
                    notifier,
                  ),
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

  Widget _buildModeSelector(WidgetRef ref, PracticeMode mode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(ref, '단어', mode, PracticeMode.wordGame),
          _buildModeButton(ref, '짧은 문장', mode, PracticeMode.shortSentence),
          _buildModeButton(ref, '긴 문장', mode, PracticeMode.longSentence),
          _buildModeButton(ref, '자유', mode, PracticeMode.freeSpeech),
        ],
      ),
    );
  }

  Widget _buildRehabSessionCard(WidgetRef ref, PracticeProgress practice) {
    const goals = ['또렷하게 말하기', '천천히 말하기', '크게 말하기', '숨 조절하기'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                '오늘의 연습 세션',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '불편감, 사레, 호흡 곤란, 갑작스러운 말 변화가 있으면 연습을 멈추고 전문가에게 문의하세요.',
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          const Text(
            '목표',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: goals.map((goal) {
              final isSelected = practice.sessionGoal == goal;
              return ChoiceChip(
                label: Text(goal),
                selected: isSelected,
                selectedColor: Colors.blueAccent,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? Colors.blueAccent : Colors.white12,
                ),
                onSelected: (_) {
                  ref.read(practiceProvider.notifier).setSessionGoal(goal);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '시작 전 피로도',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${practice.fatigueBefore}/5',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: practice.fatigueBefore.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white12,
            label: '${practice.fatigueBefore}',
            onChanged: practice.state == PracticeState.recording
                ? null
                : (value) {
                    ref
                        .read(practiceProvider.notifier)
                        .setFatigueBefore(value.round());
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildWordGameControls(WidgetRef ref, PracticeProgress practice) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDifficultyButton(ref, '쉬움', practice.wordGameDifficulty, 1),
          _buildDifficultyButton(ref, '보통', practice.wordGameDifficulty, 2),
          _buildDifficultyButton(ref, '집중', practice.wordGameDifficulty, 3),
        ],
      ),
    );
  }

  Widget _buildLongSentenceTools(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_outlined, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '내 긴 문장으로 연습하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '자주 쓰는 문장이나 어려운 문장을 저장해 두고 반복해서 읽을 수 있습니다.',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showLongSentenceEditor(context, ref),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('문장 추가'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orangeAccent,
                    side: BorderSide(
                      color: Colors.orangeAccent.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCustomLongSentenceManager(context, ref),
                  icon: const Icon(Icons.folder_special_outlined),
                  label: const Text('문장 관리'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    return GestureDetector(
      onTap: isSelected
          ? null
          : () => ref
                .read(practiceProvider.notifier)
                .setWordGameDifficulty(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(
    WidgetRef ref,
    String label,
    PracticeMode currentMode,
    PracticeMode mode,
  ) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: isSelected
          ? null
          : () => ref.read(practiceProvider.notifier).setMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetCard(
    BuildContext context,
    WidgetRef ref,
    PracticeProgress practice,
  ) {
    if (practice.mode == PracticeMode.wordGame) {
      return _buildFallingWordGameCard(context, ref, practice);
    }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _targetLabel(practice.mode),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
              if (!practice.isFreeMode)
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 2,
                    runSpacing: 2,
                    children: [
                      if (practice.mode == PracticeMode.wordGame)
                        IconButton(
                          icon: const Icon(
                            Icons.replay_circle_filled_outlined,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                          onPressed: () => _startFailedWordReview(context, ref),
                          tooltip: '틀린 단어 복습',
                        ),
                      if (practice.mode == PracticeMode.longSentence) ...[
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          onPressed: () =>
                              _showLongSentenceEditor(context, ref),
                          tooltip: '내 긴 문장 추가',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.folder_special_outlined,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () =>
                              _showCustomLongSentenceManager(context, ref),
                          tooltip: '내 긴 문장 관리',
                        ),
                      ],
                      IconButton(
                        icon: const Icon(
                          Icons.menu_book,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        onPressed: () => _showTextInputDialog(context, ref),
                        tooltip: practice.mode == PracticeMode.longSentence
                            ? '이번만 연습할 문장 입력'
                            : '연습할 문장 입력',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () =>
                            ref.read(practiceProvider.notifier).nextItem(),
                        tooltip: '다음 항목',
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            practice.isFreeMode
                ? '어제 있었던 일이나 오늘 기분,\n좋아하는 주제로 편하게 말씀해 보세요.'
                : _formatTargetText(practice),
            style: TextStyle(
              color: practice.isFreeMode ? Colors.white54 : Colors.white,
              fontSize: switch (practice.mode) {
                PracticeMode.wordGame => 44,
                PracticeMode.longSentence => 17,
                _ => practice.isFreeMode ? 18 : 22,
              },
              fontWeight: practice.mode == PracticeMode.longSentence
                  ? FontWeight.w600
                  : (practice.isFreeMode ? FontWeight.normal : FontWeight.bold),
              height: practice.mode == PracticeMode.longSentence ? 1.6 : 1.4,
            ),
          ),
          if (!practice.isFreeMode) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSmallChip(Icons.category_outlined, practice.category),
                _buildSmallChip(
                  Icons.signal_cellular_alt,
                  '난이도 ${practice.difficulty}',
                ),
                if (practice.contentSource == PracticeContentSource.custom)
                  _buildSmallChip(Icons.bookmark_added_outlined, '내 문장'),
                if (practice.isReviewMode)
                  _buildSmallChip(Icons.replay_circle_filled_outlined, '복습'),
                if (practice.mode == PracticeMode.wordGame) ...[
                  _buildSmallChip(
                    Icons.sync_alt_outlined,
                    '움직임 ${practice.movementScore}/5',
                  ),
                  if (practice.isExercisePattern)
                    _buildSmallChip(Icons.fitness_center_outlined, '운동 음절'),
                ],
                if (practice.retryCount > 0)
                  _buildSmallChip(
                    Icons.replay_outlined,
                    '재시도 ${practice.retryCount}',
                  ),
                if (practice.mode == PracticeMode.shortSentence)
                  _buildSmallChip(
                    Icons.repeat,
                    '반복 ${_repeatCountForCurrent(practice)}회',
                  ),
                if (practice.streakCount > 0)
                  _buildSmallChip(
                    Icons.local_fire_department_outlined,
                    '연속 성공 ${practice.streakCount}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallingWordGameCard(
    BuildContext context,
    WidgetRef ref,
    PracticeProgress practice,
  ) {
    final notifier = ref.read(practiceProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '단어가 바닥에 닿기 전에 발음하세요',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.replay_circle_filled_outlined,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                onPressed: () => _startFailedWordReview(context, ref),
                tooltip: '틀린 단어 복습',
              ),
              IconButton(
                icon: const Icon(Icons.restart_alt, color: Colors.white54),
                onPressed: () => notifier.resetFallingWordGame(),
                tooltip: '게임 초기화',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWordGameStats(practice),
          const SizedBox(height: 12),
          _buildFallingWordArena(practice),
          const SizedBox(height: 14),
          if (practice.wordGameStatus == WordGameStatus.running)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSmallChip(Icons.gps_fixed, '목표 ${practice.targetText}'),
                _buildSmallChip(
                  Icons.sync_alt_outlined,
                  '움직임 ${practice.movementScore}/5',
                ),
                if (practice.isExercisePattern)
                  _buildSmallChip(Icons.fitness_center_outlined, '운동 음절'),
                if (practice.isReviewMode)
                  _buildSmallChip(Icons.replay_circle_filled_outlined, '복습'),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWordGameStats(PracticeProgress practice) {
    final average = practice.wordGameHits == 0
        ? 0
        : practice.wordGameScore ~/ practice.wordGameHits;
    return Row(
      children: [
        Expanded(
          child: _buildGameStat(
            '성공',
            '${practice.wordGameHits}',
            Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildGameStat(
            '실패',
            '${practice.wordGameMisses}',
            Colors.redAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildGameStat('평균', '$average점', Colors.blueAccent)),
      ],
    );
  }

  Widget _buildGameStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
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
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallingWordArena(PracticeProgress practice) {
    const arenaHeight = 320.0;
    return Container(
      height: arenaHeight,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
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
                bottom: 16,
                child: Container(
                  height: 2,
                  color: Colors.redAccent.withValues(alpha: 0.8),
                ),
              ),
              if (practice.wordGameStatus == WordGameStatus.ready)
                const Center(
                  child: Text(
                    '게임 시작을 누르면 단어가 내려옵니다.',
                    style: TextStyle(color: Colors.white54),
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '성공 ${practice.wordGameHits}개 · 평균 ${practice.wordGameHits == 0 ? 0 : practice.wordGameScore ~/ practice.wordGameHits}점',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              for (final word in practice.fallingWords)
                Positioned(
                  left: word.lane * laneWidth + 8,
                  top: word.progress * (arenaHeight - 56),
                  width: laneWidth - 16,
                  child: _buildFallingWordChip(
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

  Widget _buildFallingWordChip(FallingWord word, {required bool isTarget}) {
    final color = isTarget ? Colors.greenAccent : Colors.white70;
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTarget
            ? Colors.greenAccent.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        word.item.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  String _targetLabel(PracticeMode mode) {
    return switch (mode) {
      PracticeMode.wordGame => '단어를 또렷하게 말해보세요:',
      PracticeMode.shortSentence => '짧은 문장을 따라 읽어보세요:',
      PracticeMode.longSentence => '긴 문장을 의미 단위로 끊어 읽어보세요:',
      PracticeMode.freeSpeech => '다루고 싶은 주제로 말해보세요:',
    };
  }

  String _formatTargetText(PracticeProgress practice) {
    if (practice.mode != PracticeMode.longSentence) {
      return practice.targetText;
    }
    return practice.targetText
        .replaceAllMapped(
          RegExp(r'([.!?。！？])\s+'),
          (match) => '${match.group(1)}\n\n',
        )
        .replaceAll(' 하면서 ', ' 하면서\n')
        .replaceAll(' 전에 ', ' 전에\n')
        .replaceAll(' 함께 ', ' 함께\n')
        .replaceAll(' 때는 ', ' 때는\n');
  }

  Widget _buildSmallChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
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
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white10),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
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
                ref
                    .read(practiceProvider.notifier)
                    .setTargetText(controller.text.trim());
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

  void _startFailedWordReview(BuildContext context, WidgetRef ref) {
    final started = ref.read(practiceProvider.notifier).startFailedWordReview();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(started ? '틀린 단어 복습을 시작합니다.' : '복습할 틀린 단어가 없습니다.'),
      ),
    );
  }

  void _showLongSentenceEditor(
    BuildContext context,
    WidgetRef ref, {
    PracticeContentItem? item,
  }) {
    final textController = TextEditingController(text: item?.text ?? '');
    final categoryController = TextEditingController(
      text: item?.category == null || item?.category == '내 문장'
          ? ''
          : item!.category,
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final text = textController.text.trim();
          final difficulty = CustomPracticeContentService.estimateDifficulty(
            text,
          );

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              item == null ? '내 긴 문장 추가' : '내 긴 문장 수정',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: textController,
                    minLines: 6,
                    maxLines: 10,
                    maxLength: CustomPracticeContentService.maxStoryLength,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => setState(() => errorText = null),
                    decoration: InputDecoration(
                      hintText:
                          '반복해서 읽을 긴 문장을 입력하세요. ${CustomPracticeContentService.minStoryLength}자 이상이면 좋아요.',
                      hintStyle: const TextStyle(color: Colors.white24),
                      errorText: errorText,
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: categoryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '상황 예: 병원, 전화, 가족',
                      hintStyle: TextStyle(color: Colors.white24),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '예상 난이도 $difficulty · 단편 소설처럼 긴 호흡으로 읽는 기준입니다.',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  '취소',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final sentence = textController.text.trim();
                  if (sentence.length <
                      CustomPracticeContentService.minStoryLength) {
                    setState(
                      () => errorText =
                          '긴 문장은 ${CustomPracticeContentService.minStoryLength}자 이상 입력해 주세요.',
                    );
                    return;
                  }

                  final notifier = ref.read(practiceProvider.notifier);
                  if (item == null) {
                    await notifier.addCustomLongSentence(
                      text: sentence,
                      category: categoryController.text,
                    );
                  } else {
                    await notifier.updateCustomLongSentence(
                      id: item.id,
                      text: sentence,
                      category: categoryController.text,
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: Text(item == null ? '추가' : '저장'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCustomLongSentenceManager(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: FutureBuilder<List<PracticeContentItem>>(
            future: ref
                .read(practiceProvider.notifier)
                .loadCustomLongSentences(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '내 긴 문장',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showLongSentenceEditor(context, ref);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.blueAccent,
                          ),
                        ),
                      )
                    else if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          '저장한 긴 문장이 없습니다.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${item.category} · 난이도 ${item.difficulty}',
                                style: const TextStyle(color: Colors.white38),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(sheetContext);
                                      _showLongSentenceEditor(
                                        context,
                                        ref,
                                        item: item,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      await ref
                                          .read(practiceProvider.notifier)
                                          .deleteCustomLongSentence(item.id);
                                      if (sheetContext.mounted) {
                                        Navigator.pop(sheetContext);
                                        _showCustomLongSentenceManager(
                                          context,
                                          ref,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInteractionArea(
    BuildContext context,
    WidgetRef ref,
    PracticeProgress practice,
    PracticeNotifier notifier,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (practice.spokenText.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '인식된 내용:',
                  style: TextStyle(
                    color: Colors.blueAccent.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
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
              Text(
                'AI가 발음을 분석하고 있습니다...',
                style: TextStyle(color: Colors.white70),
              ),
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
          child: AnimatedOrb(state: orbState),
        ),
        const SizedBox(height: 18),
        Text(
          practice.state == PracticeState.recording
              ? '불편하면 즉시 멈추고 쉬어 주세요'
              : _idlePrompt(practice.mode),
          style: TextStyle(
            color: practice.state == PracticeState.recording
                ? Colors.redAccent
                : Colors.white54,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 220,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              if (practice.state == PracticeState.recording) {
                notifier.stopRecording();
              } else {
                notifier.startRecording();
              }
            },
            icon: Icon(
              practice.state == PracticeState.recording
                  ? Icons.check_circle
                  : Icons.mic,
            ),
            label: Text(
              practice.state == PracticeState.recording ? '판정하기' : '녹음 시작',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: practice.state == PracticeState.recording
                  ? Colors.blueAccent
                  : Colors.white,
              foregroundColor: practice.state == PracticeState.recording
                  ? Colors.white
                  : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _idlePrompt(PracticeMode mode) {
    return switch (mode) {
      PracticeMode.wordGame => '목표 단어를 보고 녹음하세요',
      PracticeMode.shortSentence => '짧은 문장을 읽고 녹음하세요',
      PracticeMode.longSentence => '긴 문장을 천천히 읽고 녹음하세요',
      PracticeMode.freeSpeech => '편하게 말할 준비가 되면 녹음하세요',
    };
  }

  Widget _buildActionButtons(
    PracticeProgress practice,
    PracticeNotifier notifier,
  ) {
    return Column(
      children: [
        if (practice.mode == PracticeMode.shortSentence) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => notifier.resetPractice(),
              icon: const Icon(Icons.repeat),
              label: const Text('같은 문장 반복'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => notifier.nextItem(),
              icon: const Icon(Icons.skip_next),
              label: const Text('다음 짧은 문장'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
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
                foregroundColor: practice.isPlaying
                    ? Colors.redAccent
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => notifier.shareRecording(),
              icon: const Icon(Icons.share, size: 20),
              label: const Text('공유'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            if (practice.mode != PracticeMode.shortSentence)
              ElevatedButton.icon(
                onPressed: () => notifier.resetPractice(),
                icon: const Icon(Icons.refresh),
                label: const Text('다시 하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  int _repeatCountForCurrent(PracticeProgress practice) {
    if (practice.contentId != null) {
      return practice.history
          .where((session) => session.contentId == practice.contentId)
          .length;
    }
    return practice.history
        .where(
          (session) =>
              session.mode == PracticeMode.shortSentence.storageValue &&
              session.targetText == practice.targetText,
        )
        .length;
  }
}
