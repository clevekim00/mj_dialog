import '../../games/art/pixel_game_art.dart';
import 'package:speech_rehab/features/rehab/comfort/comfort_training.dart';
import 'package:speech_rehab/features/rehab/audio/recorder_waveform.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';

class WordGameScreen extends ConsumerStatefulWidget {
  const WordGameScreen({super.key, this.continuousListening = true});
  final bool continuousListening;

  @override
  ConsumerState<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends ConsumerState<WordGameScreen>
    with WidgetsBindingObserver {
  late bool _continuous;
  bool _autoActive = false, _judging = false;
  Timer? _settleTimer, _limitTimer, _nextTimer;
  String? _listeningNotice;

  void _cancelAutoTimers() {
    _settleTimer?.cancel();
    _limitTimer?.cancel();
    _nextTimer?.cancel();
  }

  Future<void> _listenNextWord() async {
    if (!mounted || !_autoActive) return;
    final notifier = ref.read(practiceProvider.notifier);
    if (ref.read(practiceProvider).wordGameStatus != WordGameStatus.running) {
      setState(() => _autoActive = false);
      return;
    }
    try {
      await notifier.stopPlayback();
      if (!mounted || !_autoActive) return;
      await notifier.startRecording();
      if (!mounted || !_autoActive) return;
      final progress = ref.read(practiceProvider);
      if (progress.state == PracticeState.error ||
          progress.speechRecognitionUnavailable) {
        await _pauseSession(finishRecording: true);
        if (mounted) {
          setState(
            () => _listeningNotice =
                '계속 듣기를 사용할 수 없어요. 권한을 확인하거나 버튼 방식으로 연습해 주세요.',
          );
        }
        return;
      }
      _limitTimer = Timer(const Duration(seconds: 30), () {
        unawaited(_pauseSession(finishRecording: true));
        if (mounted) {
          setState(() => _listeningNotice = '잠시 쉬고 있어요. 준비되면 이어가 주세요.');
        }
      });
    } catch (_) {
      _autoActive = false;
      _cancelAutoTimers();
      if (mounted) {
        setState(
          () => _listeningNotice = '듣기 또는 저장을 마치지 못했어요. 녹음 상태를 확인해 주세요.',
        );
      }
    }
  }

  Future<void> _judgeAndContinue() async {
    if (!mounted || !_autoActive || _judging) return;
    _judging = true;
    _settleTimer?.cancel();
    _limitTimer?.cancel();
    try {
      await ref.read(practiceProvider.notifier).stopRecording();
      if (!mounted || !_autoActive) return;
      final progress = ref.read(practiceProvider);
      if (progress.state == PracticeState.error ||
          progress.spokenText.trim().isEmpty ||
          progress.feedback?.hasComparableScore != true) {
        await _pauseSession();
        if (mounted) {
          setState(
            () => _listeningNotice = '인식 결과를 확인하지 못했어요. 편할 때 다시 시작해 주세요.',
          );
        }
        return;
      }
      _nextTimer = Timer(
        const Duration(milliseconds: 1500),
        () => unawaited(_listenNextWord()),
      );
    } catch (_) {
      _autoActive = false;
      _cancelAutoTimers();
      if (mounted) {
        setState(() => _listeningNotice = '저장을 완료하지 못했어요. 계속 듣기를 멈췄어요.');
      }
    } finally {
      _judging = false;
    }
  }

  void _startOrResume({bool resume = false}) {
    final notifier = ref.read(practiceProvider.notifier);
    resume ? notifier.resumeWordGame() : notifier.startFallingWordGame();
    setState(() {
      _autoActive = _continuous;
      _listeningNotice = null;
    });
    if (_autoActive) unawaited(_listenNextWord());
  }

  @override
  void initState() {
    super.initState();
    _continuous = widget.continuousListening;
    ref.listenManual(practiceProvider, (previous, next) {
      if (!_autoActive || _judging || next.state != PracticeState.recording) {
        return;
      }
      if (next.spokenText.trim().isNotEmpty &&
          previous?.spokenText != next.spokenText) {
        _settleTimer?.cancel();
        _settleTimer = Timer(
          const Duration(milliseconds: 2500),
          () => unawaited(_judgeAndContinue()),
        );
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _autoActive = false;
    _cancelAutoTimers();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _pauseSession({bool finishRecording = false}) async {
    _autoActive = false;
    _cancelAutoTimers();
    if (mounted) setState(() {});
    final notifier = ref.read(practiceProvider.notifier);
    final practice = ref.read(practiceProvider);
    if (finishRecording &&
        (practice.state == PracticeState.recording ||
            practice.state == PracticeState.analyzing)) {
      await notifier.stopRecording();
    }
    if (!mounted) return;
    notifier.pauseWordGame();
    if (ref.read(practiceProvider).isPlaying) {
      try {
        await notifier.stopPlayback();
      } catch (_) {}
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden) {
      unawaited(_pauseSession(finishRecording: true));
    }
  }

  Future<void> _openSecondary(String route) async {
    await _pauseSession(finishRecording: true);
    if (mounted) Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final practice = ref.watch(practiceProvider);
    final notifier = ref.read(practiceProvider.notifier);
    final failedReviewEntries = notifier.failedWordReviewEntries();
    final locked =
        practice.state == PracticeState.recording ||
        practice.state == PracticeState.analyzing;

    return PopScope(
      canPop: !locked,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(_pauseSession());
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              practice.state == PracticeState.recording
                  ? '녹음을 끝낸 뒤 나갈 수 있어요.'
                  : '녹음을 저장하고 있어요. 잠시만 기다려 주세요.',
            ),
            action: practice.state == PracticeState.recording
                ? SnackBarAction(
                    label: '녹음 끝내기',
                    onPressed: () => _pauseSession(finishRecording: true),
                  )
                : null,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          title: const Text('단어 말하기'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            ComfortButton(
              situation: ComfortContext.game,
              enabled: !locked && !_autoActive,
            ),
            IconButton(
              icon: const Icon(Icons.library_music),
              tooltip: '녹음 보관함',
              onPressed: locked
                  ? null
                  : () => _openSecondary('/recording_library'),
            ),
            IconButton(
              icon: const Icon(Icons.replay_circle_filled_outlined),
              tooltip: '다시 볼 단어 복습',
              onPressed: locked
                  ? null
                  : () => _startFailedWordReview(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: '성과 대시보드',
              onPressed: locked ? null : () => _openSecondary('/dashboard'),
            ),
          ],
        ),
        bottomNavigationBar: _autoActive
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    onPressed: () => _pauseSession(finishRecording: true),
                    icon: const Icon(Icons.pause),
                    label: const Text('듣기 중지 · 잠시 쉬기'),
                  ),
                ),
              )
            : null,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _buildHeader(practice),
              SwitchListTile(
                title: const Text('계속 듣고 자동 판정'),
                subtitle: const Text(
                  '한 번 시작하면 단어마다 자동으로 녹음해요. 인식된 글이 2.5초 유지되면 판정해요. 30초가 지나면 잠시 쉬어요.',
                ),
                value: _continuous,
                onChanged: locked || _autoActive
                    ? null
                    : (value) => setState(() => _continuous = value),
              ),
              if (_listeningNotice != null) Text(_listeningNotice!),
              SwitchListTile(
                title: const Text('시간 제한이 있는 낙하 모드'),
                subtitle: const Text('끄면 단어가 내려오지 않습니다.'),
                value: practice.wordGameTimed,
                onChanged:
                    practice.wordGameStatus == WordGameStatus.running ||
                        practice.wordGameStatus == WordGameStatus.paused
                    ? null
                    : notifier.setWordGameTimed,
              ),
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
              RecorderWaveform(recorder: notifier.audioRecorder),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PracticeProgress practice) {
    final status = switch (practice.wordGameStatus) {
      WordGameStatus.ready =>
        practice.isReviewMode
            ? '인식 차이가 있었던 단어를 다시 연습합니다.'
            : practice.wordGameTimed
            ? '선택한 낙하 모드입니다. 준비되면 시작하세요.'
            : '시간 제한 없이 한 단어씩 편안하게 연습합니다.',
      WordGameStatus.running =>
        _autoActive
            ? '치즈가 듣고 있어요. 목표 단어를 말하면 자동으로 비교해요.'
            : '목표 단어를 말한 뒤 판정하면 맞은 단어가 사라집니다.',
      WordGameStatus.paused => '잠시 쉬는 중입니다. 준비되면 이어가세요.',
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
                  '다시 볼 단어 ${failedReviewEntries.length}개 복습',
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
            '텍스트 일치도가 70% 미만인 단어를 모았습니다. 음성 인식 오류일 수 있으니 녹음을 먼저 확인해 주세요.',
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
              label: const Text('다시 볼 단어만 다시 연습'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
        borderRadius: BorderRadius.zero,
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
                  '인식 차이 ${entry.failureCount}회 · 일치도 ${entry.latestFailedSession.score}%',
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
        borderRadius: BorderRadius.zero,
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
          borderRadius: BorderRadius.zero,
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
      if (_autoActive) return;
      if (practice.state == PracticeState.analyzing) {
        return;
      }
      if (practice.state == PracticeState.recording) {
        notifier.stopRecording();
        return;
      }
      notifier.selectFallingWord(word.id);
      notifier.startRecording();
    }

    return Container(
      height: arenaHeight,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final laneWidth = constraints.maxWidth / 3;
          return Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: PixelGameBackdrop(night: true)),
              ),
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
                    '연습 시작',
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
      borderRadius: BorderRadius.zero,
      onTap: isBusy && !isTarget ? null : onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isTarget
              ? Colors.greenAccent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.zero,
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
    if (practice.wordGameStatus == WordGameStatus.paused) {
      return FilledButton.icon(
        onPressed: () => _startOrResume(resume: true),
        icon: const Icon(Icons.play_arrow),
        label: const Text('연습 이어가기'),
      );
    }
    if (practice.wordGameStatus != WordGameStatus.running) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          key: const ValueKey('word-game-start'),
          onPressed: () => _startOrResume(),
          icon: const Icon(Icons.play_arrow),
          label: Text(
            practice.wordGameStatus == WordGameStatus.gameOver
                ? '다시 시작'
                : '연습 시작',
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

    final isBusy = practice.state == PracticeState.analyzing;
    final isRecording = practice.state == PracticeState.recording;
    void handleOrbTap() {
      if (_autoActive) {
        unawaited(_pauseSession(finishRecording: true));
        return;
      }
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
        Text(
          practice.feedback != null
              ? ((practice.feedback?.pronunciationScore ?? 0) >= 70
                    ? '치즈: 잘했어! 다음 단어도 같이 해 보자.'
                    : '치즈: 괜찮아. 천천히 다시 해 보자.')
              : '치즈: 준비되면 편하게 말해 줘.',
          style: const TextStyle(color: Colors.amberAccent),
        ),
        _buildSpeechOrbButton(practice: practice, onTap: handleOrbTap),
        const SizedBox(height: 14),
        Text(
          isBusy
              ? '판정 중입니다'
              : isRecording
              ? (_autoActive
                    ? '듣고 있어요. 말한 뒤 잠깐 기다리면 자동으로 판정해요.'
                    : '말한 뒤 말하기 버튼이나 목표 단어를 다시 눌러 판정하세요')
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
        OutlinedButton.icon(
          onPressed: _autoActive
              ? () => _pauseSession(finishRecording: true)
              : isBusy || isRecording
              ? null
              : notifier.pauseWordGame,
          icon: const Icon(Icons.pause),
          label: const Text('잠시 쉬기'),
        ),
        TextButton.icon(
          onPressed: isBusy || isRecording
              ? null
              : () => notifier.resetFallingWordGame(),
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
                    await _pauseSession(finishRecording: true);
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
        ? (_autoActive ? '치즈가 듣는 중' : '판정하기')
        : isAnalyzing
        ? '판정 중'
        : '말하기 시작';

    return Semantics(
      button: true,
      enabled: !isAnalyzing,
      label: _autoActive
          ? '계속 듣기 중지'
          : isRecording
          ? '녹음 마치고 텍스트 비교'
          : '단어 말하기 시작',
      onTap: isAnalyzing ? null : onTap,
      child: GestureDetector(
        key: const ValueKey('word-game-microphone'),
        behavior: HitTestBehavior.opaque,
        onTap: isAnalyzing ? null : onTap,
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
              Positioned(
                bottom: 0,
                child: PixelGameMascot(
                  active: isRecording,
                  cheering:
                      practice.feedback != null &&
                      (practice.feedback?.pronunciationScore ?? 0) >= 70,
                ),
              ),
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
                    borderRadius: BorderRadius.zero,
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
        borderRadius: BorderRadius.zero,
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
            '인식된 글',
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
        borderRadius: BorderRadius.zero,
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
        content: Text(started ? '다시 볼 단어 복습을 시작합니다.' : '복습할 다시 볼 단어가 없습니다.'),
      ),
    );
  }
}
