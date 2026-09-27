import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_rehab/services/audio/audio_recorder_service.dart';
import 'package:speech_rehab/services/audio/audio_player_service.dart';
import 'package:speech_rehab/services/audio/tts_service.dart';
import '../model/rehab_session.dart';
import '../services/rehab_session_repository.dart';
import 'rehab_ui.dart';

class RehabPlayerScreen extends ConsumerStatefulWidget {
  const RehabPlayerScreen({super.key, required this.session});
  final RehabSession session;
  @override
  ConsumerState<RehabPlayerScreen> createState() => _RehabPlayerScreenState();
}

class _RehabPlayerScreenState extends ConsumerState<RehabPlayerScreen>
    with WidgetsBindingObserver {
  late RehabSession _session;
  RehabSession? _pending;
  AudioRecorderService? _recorder;
  AudioPlayerService? _player;
  TtsService? _tts;
  bool _recording = false,
      _busy = false,
      _allowPop = false,
      _background = false;
  bool _audioPlaying = false;
  String? _error, _takeId;
  final _clock = Stopwatch();
  bool get _terminal =>
      _session.status == RehabStatus.completed ||
      _session.status == RehabStatus.partial ||
      _session.status == RehabStatus.stopped;
  bool get _locked => _busy || _pending != null;
  RehabTask get _task =>
      _session.tasks[_session.taskIndex.clamp(0, _session.tasks.length - 1)];

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background = state != AppLifecycleState.resumed;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      unawaited(_stopAudio());
      if (!_busy && !_terminal) unawaited(_pause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_tts?.dispose());
    unawaited(_player?.stop());
    super.dispose();
  }

  Future<bool> _persist(RehabSession next) async {
    if (_background && next.status == RehabStatus.inProgress) {
      next = next.copyWith(status: RehabStatus.paused);
    }
    _pending = next;
    try {
      await ref.read(rehabRepositoryProvider).save(next);
      ref.invalidate(rehabSessionsProvider);
      if (!mounted) return false;
      setState(() {
        _session = next;
        _pending = null;
        _error = null;
      });
      return true;
    } catch (_) {
      if (mounted) setState(() => _error = rehabL10n(context).rehabSaveError);
      return false;
    }
  }

  Future<void> _retrySave() async {
    if (_busy || _pending == null) return;
    setState(() => _busy = true);
    await _persist(_pending!);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _stopAudio() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    try {
      await _player?.stop();
    } catch (_) {}
    if (mounted) setState(() => _audioPlaying = false);
  }

  Future<void> _listen({String? path}) async {
    if (_recording || _locked) return;
    setState(() => _busy = true);
    await _stopAudio();
    if (!mounted) return;
    setState(() => _audioPlaying = true);
    try {
      if (path == null) {
        _tts ??= TtsService(languageTag: _session.language);
        await _tts!.speak(_task.text.replaceAll('/', ' '));
        if (mounted) setState(() => _audioPlaying = false);
      } else {
        _player ??= ref.read(audioPlayerServiceProvider);
        await _player!.playFile(path);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _audioPlaying = false;
          _error = rehabL10n(context).rehabAudioError;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_background && mounted && !_terminal) await _pause();
  }

  Future<void> _startRecording() async {
    if (_locked || _recording) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    await _stopAudio();
    try {
      _recorder ??= ref.read(audioRecorderServiceProvider);
      _takeId = const Uuid().v4();
      await _recorder!.startRecording('rehab_${_takeId!}');
      _clock
        ..reset()
        ..start();
      if (mounted) setState(() => _recording = true);
    } catch (_) {
      if (mounted) setState(() => _error = rehabL10n(context).rehabRecordError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_background && mounted) await _pause();
  }

  Future<bool> _stopRecording() async {
    if (!_recording || _busy) return false;
    setState(() => _busy = true);
    _clock.stop();
    final task = _task;
    try {
      final path = await _recorder!.stopRecording();
      if (!mounted) return false;
      setState(() => _recording = false);
      if (path == null || path.isEmpty) throw StateError('No recording');
      final take = RehabTake(
        id: _takeId!,
        taskId: task.id,
        text: task.text,
        path: path,
        createdAt: DateTime.now(),
        seconds: (_clock.elapsedMilliseconds / 1000).ceil(),
      );
      return await _persist(
        _session.copyWith(takes: [..._session.takes, take]),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _recording = false;
          _error = rehabL10n(context).rehabRecordError;
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pause() async {
    if (_locked || _terminal) return;
    if (_recording && !await _stopRecording()) return;
    if (!mounted) return;
    setState(() => _busy = true);
    await _stopAudio();
    await _persist(_session.copyWith(status: RehabStatus.paused));
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _resume() async {
    if (_locked) return;
    setState(() => _busy = true);
    await _persist(_session.copyWith(status: RehabStatus.inProgress));
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _next() async {
    if (_locked || _recording) return;
    if (_session.taskIndex + 1 >= _session.tasks.length) {
      await _finish();
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    await _stopAudio();
    await _persist(_session.copyWith(taskIndex: _session.taskIndex + 1));
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _finish() async {
    if (_locked) return;
    if (_recording && !await _stopRecording()) return;
    if (!mounted) return;
    setState(() => _busy = true);
    await _stopAudio();
    await _persist(
      _session.copyWith(
        status: _session.completedTasks == _session.tasks.length
            ? RehabStatus.completed
            : RehabStatus.partial,
        fatigueAfter: _session.fatigueAfter,
      ),
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _exit() async {
    if (_locked) return;
    if (!_terminal) await _pause();
    if (!mounted || _pending != null || _recording) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = rehabL10n(context);
    final en = rehabEnglish(context);
    final paused = _session.status == RehabStatus.paused;
    final count = _session.countFor(_task.id);
    final currentTakes = _session.takes
        .where((t) => t.taskId == _task.id)
        .toList();
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_exit());
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_terminal ? l.rehabSaved : _session.title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Semantics(liveRegion: true, child: Text(_error!)),
                          if (_pending != null)
                            FilledButton(
                              onPressed: _busy ? null : _retrySave,
                              child: Text(l.rehabRetrySave),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (_terminal) ...[
                  Text(
                    en
                        ? '${_session.takes.length} recordings · ${_session.completedTasks}/${_session.tasks.length} tasks completed'
                        : '${_session.takes.length}번 녹음 · ${_session.completedTasks}/${_session.tasks.length}개 과제 완료',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(l.rehabUnscored),
                  for (final take in _session.takes)
                    ListTile(
                      title: Text(take.text),
                      trailing: IconButton(
                        tooltip: l.rehabListenMine,
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _listen(path: take.path),
                      ),
                    ),
                  if (_audioPlaying)
                    TextButton(
                      onPressed: _stopAudio,
                      child: Text(l.rehabStopAudio),
                    ),
                  Text(l.rehabOptionalFatigue),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var n = 1; n <= 5; n++)
                        ChoiceChip(
                          label: Text('$n / 5'),
                          selected: _session.fatigueAfter == n,
                          onSelected: _locked
                              ? null
                              : (_) async {
                                  setState(() => _busy = true);
                                  await _persist(
                                    _session.copyWith(fatigueAfter: n),
                                  );
                                  if (mounted) setState(() => _busy = false);
                                },
                        ),
                    ],
                  ),
                ] else if (paused) ...[
                  Text(
                    l.rehabPaused,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(l.rehabSafety),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _locked ? null : _resume,
                    child: Text(l.rehabResume),
                  ),
                ] else ...[
                  Text(
                    '${_session.taskIndex + 1} / ${_session.tasks.length} · ${_task.title}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_task.prompt != null) ...[
                    Text(
                      _task.prompt!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _task.text,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_task.instruction),
                  const SizedBox(height: 12),
                  Text(
                    en
                        ? '$count recordings · target ${_session.repetitions}'
                        : '$count번 녹음 · 목표 ${_session.repetitions}번',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _locked || _recording
                            ? null
                            : () => _listen(),
                        icon: const Icon(Icons.volume_up),
                        label: Text(l.rehabListen),
                      ),
                      if (currentTakes.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: _locked || _recording
                              ? null
                              : () => _listen(path: currentTakes.last.path),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l.rehabListenMine),
                        ),
                      if (_audioPlaying)
                        TextButton(
                          onPressed: _stopAudio,
                          child: Text(l.rehabStopAudio),
                        ),
                    ],
                  ),
                  if (currentTakes.length > 1)
                    ExpansionTile(
                      title: Text(l.rehabCompare),
                      children: [
                        for (var i = 0; i < currentTakes.length; i++)
                          ListTile(
                            title: Text('${i + 1} · ${currentTakes[i].text}'),
                            trailing: IconButton(
                              tooltip: l.rehabListenMine,
                              icon: const Icon(Icons.play_arrow),
                              onPressed: _locked || _recording
                                  ? null
                                  : () => _listen(path: currentTakes[i].path),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text(l.rehabRecordingOnly),
                  const SizedBox(height: 8),
                  Text(l.rehabNoMic),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _locked || _recording ? null : _next,
                    child: Text(
                      count >= _session.repetitions ? l.rehabNext : l.rehabSkip,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_terminal && !paused)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: _locked
                          ? null
                          : _recording
                          ? () async {
                              await _stopRecording();
                            }
                          : _startRecording,
                      icon: Icon(_recording ? Icons.stop : Icons.mic),
                      label: Text(
                        _recording ? l.rehabStopRecording : l.rehabRecord,
                      ),
                    ),
                  ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  children: [
                    if (!_terminal && !paused)
                      TextButton(
                        onPressed: _locked ? null : _pause,
                        child: Text(l.rehabPause),
                      ),
                    TextButton(
                      onPressed: _locked
                          ? null
                          : _terminal
                          ? _exit
                          : _finish,
                      child: Text(_terminal ? l.rehabDone : l.rehabFinish),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
