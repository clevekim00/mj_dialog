import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_rehab/features/guided_training/model/guided_training_models.dart';
import 'package:speech_rehab/services/guided_training/guided_training_history_service.dart';
import 'package:speech_rehab/services/training/training_settings_service.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

enum _PlayerPhase { setup, playing, paused, complete }

class GuidedTrainingPlayerScreen extends ConsumerStatefulWidget {
  const GuidedTrainingPlayerScreen({
    super.key,
    required this.exercises,
    this.routineName = '구강·호흡 훈련',
    this.resumeSession,
  });

  final List<GuidedTrainingExercise> exercises;
  final String routineName;
  final GuidedTrainingSession? resumeSession;

  @override
  ConsumerState<GuidedTrainingPlayerScreen> createState() =>
      _GuidedTrainingPlayerScreenState();
}

class _GuidedTrainingPlayerScreenState
    extends ConsumerState<GuidedTrainingPlayerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _tts = FlutterTts();
  final _results = <GuidedTrainingExerciseResult>[];
  late final AnimationController _fallbackController;
  VideoPlayerController? _videoController;
  DateTime? _startedAt;
  _PlayerPhase _phase = _PlayerPhase.setup;
  int _exerciseIndex = 0;
  int _completedLoops = 0;
  int _targetLoops = 5;
  int _sessionRepeats = 5;
  int? _fatigueBefore;
  int? _fatigueAfter;
  double _speed = 0.75;
  double _captionScale = 1;
  bool _captionsEnabled = true;
  bool _ttsEnabled = true;
  bool _hapticsEnabled = true;
  bool _videoFailed = false;
  bool _videoInitializing = false;
  bool _loopHandled = false;
  int _videoCueBand = -1;
  bool _exerciseDone = false;
  bool _saved = false;
  bool _settingsReady = false;
  bool _transitioning = false;
  bool _allowPop = false;
  String? _saveError;
  String _sessionId = const Uuid().v4();
  final _activeClock = Stopwatch();
  int _restoredActiveSeconds = 0;
  GuidedTrainingSession? _resumable;
  late final GuidedTrainingHistoryService _history;

  GuidedTrainingExercise get _exercise => widget.exercises[_exerciseIndex];
  bool get _isLocked =>
      _exercise.safetyTier == GuidedTrainingSafetyTier.clinicianOnly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _history = ref.read(guidedTrainingHistoryServiceProvider);
    _fallbackController = AnimationController(
      vsync: this,
      duration: widget.exercises.isEmpty
          ? const Duration(seconds: 1)
          : _effectiveLoopDuration,
    )..addStatusListener(_onFallbackStatus);
    if (widget.exercises.isNotEmpty) {
      _loadSettings();
    }
  }

  Duration get _effectiveLoopDuration => Duration(
    milliseconds: (_exercise.loopDuration.inMilliseconds / _speed).round(),
  );

  Future<void> _loadSettings() async {
    final values = await Future.wait<Object>([
      TrainingSettingsService.loadDefaultRepeatCount(),
      TrainingSettingsService.loadPlaybackSpeed(),
      TrainingSettingsService.loadCaptionScale(),
      TrainingSettingsService.loadCaptionsEnabled(),
      TrainingSettingsService.loadTtsEnabled(),
      TrainingSettingsService.loadHapticsEnabled(),
    ]);
    final sessions = await _history.loadSessions();
    final ids = widget.exercises.map((e) => e.id).toList();
    final candidates = sessions.where(
      (session) =>
          session.canResume &&
          session.exerciseIds.length == ids.length &&
          List.generate(
            ids.length,
            (i) => session.exerciseIds[i] == ids[i],
          ).every((same) => same),
    );
    if (!context.mounted) return;
    setState(() {
      _resumable =
          widget.resumeSession ??
          (candidates.isEmpty ? null : candidates.first);
      _settingsReady = true;
      final storedRepeat = values[0] as int;
      _targetLoops = const [5, 10, 20].contains(storedRepeat)
          ? storedRepeat
          : 5;
      _speed = values[1] as double;
      _captionScale = values[2] as double;
      _captionsEnabled = values[3] as bool;
      _ttsEnabled = values[4] as bool;
      _hapticsEnabled = values[5] as bool;
      _fallbackController.duration = _effectiveLoopDuration;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _phase == _PlayerPhase.playing) {
      _pause();
    }
  }

  Future<void> _prepareVideo({required bool autoPlay}) async {
    await _videoController?.dispose();
    if (!mounted || _allowPop) return;
    _videoController = null;
    _videoFailed = false;
    _videoInitializing = false;
    _loopHandled = false;
    _videoCueBand = -1;
    _fallbackController.stop();
    _fallbackController.reset();

    final asset = _exercise.videoAsset;
    if (asset == null) {
      setState(() => _videoFailed = true);
      if (autoPlay && _phase == _PlayerPhase.playing) _startFallbackLoop();
      return;
    }

    final controller = VideoPlayerController.asset(asset);
    _videoController = controller;
    setState(() => _videoInitializing = true);
    try {
      await controller.initialize();
      if (!mounted || controller != _videoController) return;
      await controller.setLooping(false);
      await controller.setPlaybackSpeed(_speed);
      controller.addListener(_onVideoTick);
      setState(() => _videoInitializing = false);
      if (autoPlay && _phase == _PlayerPhase.playing) await controller.play();
    } catch (_) {
      await controller.dispose();
      if (!mounted || controller != _videoController) return;
      _videoController = null;
      setState(() {
        _videoInitializing = false;
        _videoFailed = true;
      });
      if (autoPlay && _phase == _PlayerPhase.playing) _startFallbackLoop();
    }
  }

  void _onVideoTick() {
    if (_phase != _PlayerPhase.playing || _transitioning) return;
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized || _loopHandled) {
      return;
    }
    final duration = controller.value.duration;
    if (duration == Duration.zero) return;
    final progress =
        controller.value.position.inMilliseconds / duration.inMilliseconds;
    final cueBand = switch (progress) {
      < 0.15 => 0,
      < 0.45 => 1,
      < 0.65 => 2,
      < 0.9 => 3,
      _ => 4,
    };
    if (cueBand != _videoCueBand && mounted) {
      _videoCueBand = cueBand;
      setState(() {});
    }
    if (controller.value.position >=
        duration - const Duration(milliseconds: 80)) {
      _loopHandled = true;
      unawaited(_completeLoop());
    }
  }

  void _onFallbackStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _phase == _PlayerPhase.playing) {
      unawaited(_completeLoop());
    }
  }

  Future<void> _completeLoop() async {
    if (!mounted ||
        _phase != _PlayerPhase.playing ||
        _exerciseDone ||
        _transitioning) {
      return;
    }
    final completedExerciseIndex = _exerciseIndex;
    if (_hapticsEnabled) unawaited(HapticFeedback.selectionClick());
    setState(() {
      _completedLoops += 1;
      _exerciseDone = _completedLoops >= _targetLoops;
    });

    await _persist(GuidedTrainingSessionStatus.paused);
    if (!mounted ||
        _exerciseIndex != completedExerciseIndex ||
        _phase == _PlayerPhase.complete) {
      return;
    }
    if (_exerciseDone) {
      _activeClock.stop();
      await _videoController?.pause();
      _fallbackController.stop();
      return;
    }

    final controller = _videoController;
    if (controller != null && !_videoFailed) {
      await controller.seekTo(Duration.zero);
      _loopHandled = false;
      _videoCueBand = -1;
      if (_phase == _PlayerPhase.playing) await controller.play();
    } else {
      _startFallbackLoop();
    }
  }

  void _startFallbackLoop() {
    if (!mounted || _phase != _PlayerPhase.playing || _allowPop) return;
    _fallbackController.duration = _effectiveLoopDuration;
    _fallbackController.forward(from: 0);
  }

  Future<void> _start() async {
    if (_isLocked ||
        !_settingsReady ||
        _transitioning ||
        _fatigueBefore == null) {
      return;
    }
    _transitioning = true;
    _sessionRepeats = _targetLoops;
    _startedAt = DateTime.now();
    setState(() => _phase = _PlayerPhase.playing);
    await _persist(GuidedTrainingSessionStatus.paused);
    if (!mounted) return;
    await _prepareVideo(autoPlay: true);
    if (!mounted) return;
    setState(() => _transitioning = false);
    if (_phase == _PlayerPhase.playing) {
      _activeClock.start();
      await _speakInstruction();
    }
  }

  Future<void> _resumeSaved() async {
    final saved = _resumable;
    if (saved == null ||
        !saved.canResume ||
        saved.exerciseIndex >= widget.exercises.length) {
      return;
    }
    setState(() {
      _sessionId = saved.id;
      _startedAt = saved.startedAt;
      _results.addAll(saved.results);
      _exerciseIndex = saved.exerciseIndex;
      _completedLoops = saved.currentCompletedLoops;
      _targetLoops = saved.currentTargetLoops;
      _sessionRepeats = saved.repeatCount;
      _speed = const [0.5, 0.75, 1.0].contains(saved.playbackSpeed)
          ? saved.playbackSpeed
          : 0.75;
      _fatigueBefore = saved.fatigueBefore;
      _restoredActiveSeconds = saved.durationSeconds;
      _exerciseDone = _completedLoops >= _targetLoops;
      _phase = _PlayerPhase.paused;
    });
    await _prepareVideo(autoPlay: false);
  }

  GuidedTrainingSession _snapshot(GuidedTrainingSessionStatus status) =>
      GuidedTrainingSession(
        id: _sessionId,
        startedAt: _startedAt ?? DateTime.now(),
        completedAt: DateTime.now(),
        routineName: widget.routineName,
        fatigueBefore: _fatigueBefore ?? 1,
        fatigueAfter: _fatigueAfter,
        results: List.unmodifiable(_results),
        schemaVersion: 2,
        status: status,
        activeDurationSeconds:
            _restoredActiveSeconds + _activeClock.elapsed.inSeconds,
        exerciseIds: widget.exercises.map((e) => e.id).toList(),
        exerciseIndex: _exerciseIndex,
        currentCompletedLoops: _completedLoops,
        repeatCount: _sessionRepeats,
        currentTargetLoops: _targetLoops,
        playbackSpeed: _speed,
      );

  Future<bool> _persist(GuidedTrainingSessionStatus status) async {
    if (_startedAt == null || _allowPop) return true;
    final snapshot = _snapshot(
      _phase == _PlayerPhase.complete
          ? GuidedTrainingSessionStatus.completed
          : status,
    );
    try {
      await _history.saveSession(snapshot);
      if (mounted) {
        if (_saveError != null) setState(() => _saveError = null);
        ref.invalidate(guidedTrainingSessionsProvider);
      }
      return true;
    } catch (_) {
      if (mounted) setState(() => _saveError = '기록을 저장하지 못했어요. 다시 저장해 주세요.');
      return false;
    }
  }

  Future<void> _close() async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _speakInstruction() async {
    if (!_ttsEnabled) return;
    try {
      final locale = Localizations.localeOf(context);
      await _tts.setLanguage(locale.languageCode == 'ko' ? 'ko-KR' : 'en-US');
      await _tts.setSpeechRate(0.42);
      await _tts.speak(_exercise.instruction);
    } catch (_) {
      // TTS is optional; visual training continues when it is unavailable.
    }
  }

  Future<void> _pause() async {
    if (_phase == _PlayerPhase.complete || _phase == _PlayerPhase.setup) return;
    _activeClock.stop();
    if (mounted) setState(() => _phase = _PlayerPhase.paused);
    _fallbackController.stop();
    await _videoController?.pause();
    try {
      await _tts.stop();
    } catch (_) {}
    await _persist(GuidedTrainingSessionStatus.paused);
  }

  Future<void> _resume() async {
    if (_exerciseDone || _transitioning) return;
    setState(() => _phase = _PlayerPhase.playing);
    if (_videoController != null && !_videoFailed) {
      _loopHandled = false;
      _onVideoTick();
      if (!_exerciseDone) await _videoController!.play();
    } else {
      _fallbackController.forward();
    }
    if (mounted && _phase == _PlayerPhase.playing) _activeClock.start();
  }

  Future<void> _setSpeed(double value) async {
    setState(() {
      _speed = value;
      _fallbackController.duration = _effectiveLoopDuration;
    });
    await TrainingSettingsService.savePlaybackSpeed(value);
    await _videoController?.setPlaybackSpeed(value);
    await _persist(GuidedTrainingSessionStatus.paused);
  }

  Future<void> _advance({bool skipped = false}) async {
    if (_transitioning) return;
    setState(() => _transitioning = true);
    _activeClock.stop();
    await _videoController?.pause();
    _fallbackController.stop();
    if (!mounted) return;
    _results.add(
      GuidedTrainingExerciseResult(
        exerciseId: _exercise.id,
        targetLoops: _targetLoops,
        completedLoops: _completedLoops,
        playbackSpeed: _speed,
        skipped: skipped,
        videoFailed: _videoFailed,
      ),
    );
    if (_exerciseIndex >= widget.exercises.length - 1) {
      await _videoController?.pause();
      _fallbackController.stop();
      setState(() {
        _phase = _PlayerPhase.complete;
        _transitioning = false;
      });
      await _persist(GuidedTrainingSessionStatus.completed);
      return;
    }

    setState(() {
      _exerciseIndex += 1;
      _completedLoops = 0;
      _exerciseDone = false;
    });
    _targetLoops = _sessionRepeats;
    if (_isLocked) {
      _transitioning = false;
      await _advance(skipped: true);
      return;
    }
    setState(() => _phase = _PlayerPhase.playing);
    await _persist(GuidedTrainingSessionStatus.paused);
    if (!mounted) return;
    await _prepareVideo(autoPlay: true);
    if (!mounted) return;
    setState(() => _transitioning = false);
    if (_phase == _PlayerPhase.playing) {
      _activeClock.start();
      await _speakInstruction();
    }
  }

  Future<void> _saveAndClose() async {
    if (_saved) return;
    setState(() => _saved = true);
    final success = await _persist(GuidedTrainingSessionStatus.completed);
    if (!mounted) return;
    setState(() => _saved = false);
    if (success) await _close();
  }

  @override
  void dispose() {
    _activeClock.stop();
    if (_startedAt != null && !_allowPop) {
      final snapshot = _snapshot(
        _phase == _PlayerPhase.complete
            ? GuidedTrainingSessionStatus.completed
            : GuidedTrainingSessionStatus.paused,
      );
      unawaited(_history.saveSession(snapshot).catchError((Object _) {}));
    }
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    _fallbackController.dispose();
    unawaited(_tts.stop().catchError((Object _) => null));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return const Scaffold(body: Center(child: Text('선택한 훈련이 없습니다.')));
    }
    return PopScope(
      canPop: _allowPop || _phase == _PlayerPhase.setup,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0C1319),
        appBar: AppBar(
          title: Text(widget.routineName),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: '진행 저장하고 닫기',
            onPressed: () => _confirmExit(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_saveError != null)
                MaterialBanner(
                  content: Text(_saveError!),
                  actions: [
                    TextButton(
                      onPressed: () => _persist(
                        _phase == _PlayerPhase.complete
                            ? GuidedTrainingSessionStatus.completed
                            : GuidedTrainingSessionStatus.paused,
                      ),
                      child: const Text('다시 저장'),
                    ),
                  ],
                ),
              Expanded(
                child: switch (_phase) {
                  _PlayerPhase.setup => _buildSetup(),
                  _PlayerPhase.playing || _PlayerPhase.paused => _buildPlayer(),
                  _PlayerPhase.complete => _buildComplete(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetup() {
    final estimatedSeconds = widget.exercises.fold<int>(
      0,
      (sum, item) =>
          sum +
          (item.loopDuration.inMilliseconds * _targetLoops / _speed / 1000)
              .ceil(),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        const Text(
          '훈련 준비',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.exercises.length}개 운동 · 예상 ${_durationLabel(estimatedSeconds)}',
          style: const TextStyle(color: Colors.white60, fontSize: 16),
        ),
        const SizedBox(height: 22),
        if (_resumable != null) ...[
          Card(
            child: ListTile(
              title: const Text('지난 연습을 이어할까요?'),
              subtitle: Text(
                '${_resumable!.exerciseIndex + 1}번째 운동 · ${_resumable!.currentCompletedLoops}회 진행',
              ),
              trailing: FilledButton(
                onPressed: _resumeSaved,
                child: const Text('이어하기'),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if ((_fatigueBefore ?? 0) >= 4) ...[
          const Text(
            '피곤하면 반복을 줄이거나 쉬어도 괜찮아요.',
            style: TextStyle(color: Colors.orangeAccent),
          ),
          TextButton(
            onPressed: () => setState(() => _targetLoops = 5),
            child: const Text('5회씩 짧게 연습하기'),
          ),
        ],
        _selectorCard(
          title: '시작 전 피로도 · 1 편안함 / 5 매우 피곤함',
          child: _fatigueSelector(
            value: _fatigueBefore,
            onChanged: (value) => setState(() => _fatigueBefore = value),
          ),
        ),
        const SizedBox(height: 14),
        _selectorCard(
          title: '모든 운동의 반복 횟수',
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 5, label: Text('5회')),
              ButtonSegment(value: 10, label: Text('10회')),
              ButtonSegment(value: 20, label: Text('20회')),
            ],
            selected: {
              const [5, 10, 20].contains(_targetLoops) ? _targetLoops : 5,
            },
            onSelectionChanged: (values) {
              setState(() => _targetLoops = values.first);
            },
          ),
        ),
        const SizedBox(height: 14),
        _selectorCard(title: '재생 속도', child: _speedSelector()),
        const SizedBox(height: 18),
        const _SafetyNotice(),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: _settingsReady && !_isLocked && _fatigueBefore != null
              ? _start
              : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(
            !_settingsReady
                ? '설정 불러오는 중…'
                : _fatigueBefore == null
                ? '시작 전 피로도를 골라주세요'
                : '훈련 시작',
          ),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        ),
      ],
    );
  }

  Widget _buildPlayer() {
    final paused = _phase == _PlayerPhase.paused;
    final progress = _targetLoops == 0 ? 0.0 : _completedLoops / _targetLoops;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        Row(
          children: [
            Text(
              '${_exerciseIndex + 1}/${widget.exercises.length}',
              style: const TextStyle(
                color: Colors.tealAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_exercise.category.label} · ${_exercise.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _SafetyBadge(tier: _exercise.safetyTier),
          ],
        ),
        const SizedBox(height: 14),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildStage(),
                if (_captionsEnabled)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: _CaptionOverlay(
                      caption: _exercise.shortCaption,
                      phase: _currentCueLabel,
                      scale: _captionScale,
                    ),
                  ),
                if (paused)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(
                      child: Icon(
                        Icons.pause_circle,
                        size: 72,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _exercise.instruction,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.45,
          ),
        ),
        if (_exercise.safetyMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _exercise.safetyMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('시범 반복', style: TextStyle(color: Colors.white60)),
            Text(
              '$_completedLoops / $_targetLoops',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0, 1),
          minHeight: 10,
          borderRadius: BorderRadius.circular(999),
          color: Colors.tealAccent,
          backgroundColor: Colors.white12,
        ),
        const SizedBox(height: 16),
        _speedSelector(),
        const SizedBox(height: 14),
        if (_exerciseDone)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: _transitioning || _targetLoops >= 100
                    ? null
                    : () {
                        setState(() {
                          _phase = _PlayerPhase.playing;
                          _activeClock.start();
                          _targetLoops = (_targetLoops + 5).clamp(1, 100);
                          _exerciseDone = false;
                        });
                        if (_videoFailed) {
                          _startFallbackLoop();
                        } else {
                          _loopHandled = false;
                          _videoController
                              ?.seekTo(Duration.zero)
                              .then((_) => _videoController?.play());
                        }
                      },
                child: const Text('5회 더'),
              ),
              FilledButton.icon(
                onPressed: _transitioning ? null : () => _advance(),
                icon: Icon(
                  _exerciseIndex == widget.exercises.length - 1
                      ? Icons.check
                      : Icons.skip_next,
                ),
                label: Text(
                  _exerciseIndex == widget.exercises.length - 1
                      ? '훈련 완료'
                      : '다음 운동',
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _transitioning
                      ? null
                      : paused
                      ? _resume
                      : _pause,
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                  label: Text(paused ? '계속하기' : '일시정지'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton.icon(
                  onPressed: _transitioning
                      ? null
                      : () => _confirmSkip(context),
                  icon: const Icon(Icons.skip_next),
                  label: const Text('건너뛰기'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStage() {
    final controller = _videoController;
    if (controller != null && controller.value.isInitialized && !_videoFailed) {
      return ColoredBox(
        color: Colors.black,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }
    if (_videoInitializing) {
      return const ColoredBox(
        color: Color(0xFF172432),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AnimatedBuilder(
      animation: _fallbackController,
      builder: (context, _) => _FallbackTrainingStage(
        exercise: _exercise,
        progress: _fallbackController.value,
      ),
    );
  }

  String get _currentCueLabel {
    final controller = _videoController;
    double progress;
    if (controller != null && controller.value.isInitialized) {
      final total = controller.value.duration.inMilliseconds;
      progress = total == 0
          ? 0
          : controller.value.position.inMilliseconds / total;
    } else {
      progress = _fallbackController.value;
    }
    if (progress < 0.15) return '편안하게 준비하세요';
    if (progress < 0.45) return '천천히 따라 하세요';
    if (progress < 0.65) return '잠깐 유지하세요';
    if (progress < 0.9) return '천천히 돌아오세요';
    return '힘을 빼고 쉬세요';
  }

  Widget _buildComplete() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.check_circle, color: Colors.tealAccent, size: 82),
        const SizedBox(height: 18),
        const Text(
          '훈련을 마쳤어요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          '${_results.where((result) => !result.skipped).length}/${widget.exercises.length}개 운동을 진행했습니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 16),
        ),
        const SizedBox(height: 28),
        _selectorCard(
          title: '종료 후 피로도 (선택) · 1 편안함 / 5 매우 피곤함',
          child: _fatigueSelector(
            value: _fatigueAfter,
            onChanged: (value) {
              setState(() => _fatigueAfter = value);
              _persist(GuidedTrainingSessionStatus.completed);
            },
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saved ? null : _saveAndClose,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saved ? '저장 중…' : '완료'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        ),
      ],
    );
  }

  Widget _speedSelector() => SegmentedButton<double>(
    segments: const [
      ButtonSegment(value: 0.5, label: Text('0.5×')),
      ButtonSegment(value: 0.75, label: Text('0.75×')),
      ButtonSegment(value: 1, label: Text('1×')),
    ],
    selected: {_speed},
    onSelectionChanged: (values) => _setSpeed(values.first),
  );

  Widget _fatigueSelector({
    required int? value,
    required ValueChanged<int> onChanged,
  }) => Wrap(
    spacing: 8,
    children: [
      for (var index = 1; index <= 5; index++)
        ChoiceChip(
          selected: value == index,
          label: Text('$index'),
          onSelected: (_) => onChanged(index),
        ),
    ],
  );

  Widget _selectorCard({required String title, required Widget child}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );

  Future<void> _confirmSkip(BuildContext context) async {
    await _pause();
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('현재 운동을 건너뛸까요?'),
        content: const Text('진행한 시범 반복 수는 기록에 남습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속하기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('건너뛰기'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _advance(skipped: true);
  }

  Future<void> _confirmExit(BuildContext context) async {
    if (_phase == _PlayerPhase.setup) {
      await _close();
      return;
    }
    if (_phase == _PlayerPhase.complete) {
      await _saveAndClose();
      return;
    }
    await _pause();
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('진행을 저장하고 쉴까요?'),
        content: const Text('지금까지의 반복은 기록에 남고 다음에 이어할 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속하기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장하고 마치기'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed == true) {
      if (await _persist(GuidedTrainingSessionStatus.stopped)) await _close();
    }
    // Dismissing the dialog leaves the session paused; resuming is explicit.
  }

  String _durationLabel(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    if (minutes == 0) return '$rest초';
    return rest == 0 ? '$minutes분' : '$minutes분 $rest초';
  }
}

class _CaptionOverlay extends StatelessWidget {
  const _CaptionOverlay({
    required this.caption,
    required this.phase,
    required this.scale,
  });

  final String caption;
  final String phase;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15 * scale,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              phase,
              style: TextStyle(color: Colors.tealAccent, fontSize: 12 * scale),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackTrainingStage extends StatelessWidget {
  const _FallbackTrainingStage({
    required this.exercise,
    required this.progress,
  });

  final GuidedTrainingExercise exercise;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final movement = Curves.easeInOut.transform(
      progress < 0.5 ? progress * 2 : (1 - progress) * 2,
    );
    final icon = switch (exercise.visualMode) {
      GuidedTrainingVisualMode.faceCloseUp => Icons.face_retouching_natural,
      GuidedTrainingVisualMode.oralCutaway =>
        Icons.medical_information_outlined,
      GuidedTrainingVisualMode.upperBody => Icons.air,
      GuidedTrainingVisualMode.phoneme => Icons.record_voice_over,
    };
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172432), Color(0xFF28445A)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.42,
            child: Image.asset(
              'assets/images/ai_speech_2d_tutor.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          Transform.scale(
            scale: 0.9 + movement * 0.18,
            child: Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: Colors.tealAccent.withValues(alpha: 0.88),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.tealAccent.withValues(alpha: 0.3),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.black, size: 48),
            ),
          ),
          const Positioned(
            right: 12,
            top: 12,
            child: Chip(
              avatar: Icon(Icons.image_outlined, size: 16),
              label: Text('텍스트 안내'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyBadge extends StatelessWidget {
  const _SafetyBadge({required this.tier});
  final GuidedTrainingSafetyTier tier;

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      GuidedTrainingSafetyTier.general => Colors.greenAccent,
      GuidedTrainingSafetyTier.caution => Colors.orangeAccent,
      GuidedTrainingSafetyTier.clinicianOnly => Colors.redAccent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tier.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.health_and_safety_outlined, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '통증, 사레, 삼킴 곤란, 호흡 불편 또는 어지럼이 생기면 즉시 중단하세요. 이 앱은 전문가의 진단과 치료를 대신하지 않습니다.',
                style: TextStyle(height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
