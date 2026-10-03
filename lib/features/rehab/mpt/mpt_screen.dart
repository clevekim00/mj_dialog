import 'package:speech_rehab/features/rehab/comfort/comfort_training.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_rehab/services/audio/audio_player_service.dart';
import '../audio/practice_capture.dart';
import '../audio/practice_waveform.dart';
import '../model/rehab_session.dart';
import '../services/rehab_session_repository.dart';
import '../view/rehab_ui.dart';
import 'mpt_result.dart';
import 'mpt_voice_timer.dart';

class MptScreen extends ConsumerStatefulWidget {
  const MptScreen({super.key});
  @override
  ConsumerState<MptScreen> createState() => _MptState();
}

class _MptState extends ConsumerState<MptScreen> with WidgetsBindingObserver {
  final _id = const Uuid().v4();
  final _created = DateTime.now();
  final _clock = Stopwatch();
  bool _automatic = true;
  MptVoiceTimer? _voiceTimer;
  int get _displayMs =>
      _automatic ? (_voiceTimer?.durationMs ?? 0) : _clock.elapsedMilliseconds;
  final _trials = <MptTrial>[];
  final _takes = <RehabTake>[];
  PracticeCapture? _capture;
  AudioPlayerService? _player;
  Timer? _ticker;
  RehabSession? _pending;
  bool _busy = false, _recording = false, _review = false, _ready = false;
  bool _confirm = false, _background = false, _allowPop = false;
  bool _timingStarted = false, _timingFrozen = false;
  int? _fatigue;
  int _onset = 0, _end = 0, _duration = 0;
  String? _error, _attempt, _path, _stopReason;
  int get _valid => _trials.where((t) => t.accepted && t.eligible).length;
  bool get _en => rehabEnglish(context);
  String tr(String ko, String en) => _en ? en : ko;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _clock.stop();
    _capture?.frame.removeListener(_frame);
    _capture?.problem.removeListener(_inputEnded);
    _capture?.limitReached.removeListener(_inputEnded);
    if (_recording) unawaited(_capture!.stopRecording());
    unawaited(_player?.stop() ?? Future<void>.value());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background = state != AppLifecycleState.resumed;
    if (_background) {
      unawaited(_player?.stop() ?? Future<void>.value());
      if (_recording) {
        _stopReason = 'interrupted';
        if (!_busy) unawaited(_finish('interrupted'));
      }
    }
  }

  void _frame() {
    if (!mounted || !_recording || _busy || _timingFrozen) return;
    if (_automatic && _capture!.frame.value != null) {
      final timer = _voiceTimer!;
      timer.add(_capture!.frame.value!);
      if (timer.phase == MptVoicePhase.phonating ||
          timer.phase == MptVoicePhase.ended) {
        _timingStarted = true;
        _onset = timer.onsetMs;
      }
      if (timer.phase == MptVoicePhase.ended ||
          timer.phase == MptVoicePhase.invalid) {
        unawaited(_finish(timer.failure ?? 'unreviewed'));
      }
    }
    setState(() {});
  }

  String _autoStatus() => switch (_voiceTimer?.phase) {
    MptVoicePhase.calibrating => tr(
      '주변 소리를 확인해요. 잠깐 조용히 기다리세요.',
      'Checking background sound. Stay quiet briefly.',
    ),
    MptVoicePhase.waiting => tr(
      '준비됐어요. 편안하게 “아~” 해 주세요.',
      'Ready. Sustain a comfortable “ah”.',
    ),
    MptVoicePhase.phonating => tr(
      '측정 중 · 소리가 끝나면 자동으로 멈춰요.',
      'Timing · stops automatically after your voice ends.',
    ),
    MptVoicePhase.ended => tr(
      '측정 완료 · 녹음을 확인하세요.',
      'Timing complete · review the recording.',
    ),
    MptVoicePhase.invalid => tr(
      '자동 측정을 마쳤어요. 환경과 녹음을 확인하세요.',
      'Automatic timing stopped. Check the environment and recording.',
    ),
    _ => '',
  };

  void _inputEnded() {
    if (!_recording) return;
    final reason = _capture!.problem.value != null
        ? 'input_error'
        : _capture!.limitReached.value
        ? 'recording_limit'
        : null;
    if (reason != null) {
      _stopReason = reason;
      if (!_busy) unawaited(_finish(reason));
    }
  }

  Future<void> _start() async {
    if (_busy ||
        _recording ||
        _review ||
        _pending != null ||
        !_ready ||
        _fatigue == null ||
        _valid >= 3) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _player?.stop();
      if (_capture == null) {
        _capture = ref.read(practiceCaptureProvider);
        _capture!.frame.addListener(_frame);
        _capture!.problem.addListener(_inputEnded);
        _capture!.limitReached.addListener(_inputEnded);
      }
      _attempt = const Uuid().v4();
      _path = null;
      _stopReason = null;
      _timingStarted = false;
      _timingFrozen = false;
      _onset = 0;
      _end = 0;
      _duration = 0;
      _clock.reset();
      _voiceTimer = _automatic ? MptVoiceTimer() : null;
      await _capture!.startRecording('rehab_mpt_$_attempt');
      _recording = true;
      _ready = false;
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted && _recording) setState(() {});
      });
    } catch (_) {
      _error = tr(
        '마이크를 시작하지 못했어요. 권한을 확인하고 다시 시도하세요.',
        'Could not start the microphone. Check permission and retry.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_recording && _background) await _finish('interrupted');
    if (mounted) _inputEnded();
  }

  void _beginTiming() {
    if (_busy || !_recording || _timingStarted || _stopReason != null) return;
    setState(() {
      _onset = _capture!.durationMs;
      _timingStarted = true;
      _clock.start();
    });
  }

  RehabSession _session() => RehabSession(
    id: _id,
    title: tr('최대발성시간 (MPT)', 'Maximum phonation time (MPT)'),
    language: _en ? 'en-US' : 'ko-KR',
    startedAt: _created.toUtc(),
    localDate: rehabDate(_created),
    offsetMinutes: _created.timeZoneOffset.inMinutes,
    repetitions: 3,
    fatigueBefore: _fatigue!,
    taskIndex: 1,
    tasks: [
      RehabTask(
        id: 'mpt',
        title: 'MPT',
        text: '/a/',
        instruction: 'One breath, comfortable pitch and loudness',
        prompt: _automatic ? MptResult.automaticProtocol : MptResult.protocol,
      ),
    ],
    takes: List.of(_takes),
    status: _valid == 3 ? RehabStatus.completed : RehabStatus.partial,
    feedback: {
      'kind': 'mpt',
      'version': _automatic ? MptResult.automaticProtocol : MptResult.protocol,
      'timingMethod': _automatic ? 'automatic-acoustic' : 'observer-stopwatch',
      if (_automatic) ...{
        'detectorVersion': MptVoiceTimer.version,
        'calibrationMs': MptVoiceTimer.calibrationMs,
        'onsetHoldMs': MptVoiceTimer.onsetHoldMs,
        'offsetHoldMs': MptVoiceTimer.offsetHoldMs,
      },
      'vowel': '/a/',
      'trials': _trials.map((t) => t.toJson()).toList(),
      'validTrialCount': _valid,
      'maximumMs': MptResult.maximum(_trials),
      'clinicallyValidated': false,
    },
  );
  Future<void> _save() async {
    _pending ??= _session();
    await ref.read(rehabRepositoryProvider).save(_pending!);
    _pending = null;
    ref.invalidate(rehabSessionsProvider);
  }

  Future<void> _finish(String reason) async {
    if (_busy || !_recording) return;
    _stopReason ??= reason;
    if (!_timingFrozen) {
      _clock.stop();
      _duration = _automatic
          ? _voiceTimer!.durationMs
          : _clock.elapsedMilliseconds;
      _end = _automatic ? _voiceTimer!.endMs : _capture!.durationMs;
      _timingFrozen = true;
    }
    _ticker?.cancel();
    setState(() => _busy = true);
    try {
      _path ??= await _capture!.stopRecording();
      final failure =
          _stopReason == 'unreviewed' &&
              (!_timingStarted || _path == null || _end <= _onset)
          ? 'no_timed_audio'
          : _stopReason!;
      _trials.add(
        MptTrial(
          id: _attempt!,
          durationMs: _duration,
          hadGap: _automatic && (_voiceTimer?.hadGap ?? false),
          onsetOffsetMs: _onset,
          endOffsetMs: _end,
          reason: failure,
          timingMethod: _automatic
              ? 'automatic-acoustic'
              : 'observer-stopwatch',
        ),
      );
      if (_path != null) {
        _takes.add(
          RehabTake(
            id: _attempt!,
            taskId: 'mpt',
            text: tr(
              'MPT 시도 ${_trials.length}',
              'MPT attempt ${_trials.length}',
            ),
            path: _path!,
            createdAt: DateTime.now(),
            seconds: (_capture!.durationMs / 1000).ceil(),
            durationMs: _capture!.durationMs,
            waveform: List.of(_capture!.envelope),
          ),
        );
      }
      _recording = false;
      _review = true;
      _confirm = false;
      await _save();
      _error = null;
    } catch (_) {
      _error = tr(
        '저장하지 못했어요. 재시도 후 계속하세요.',
        'Save failed. Retry before continuing.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retry() async {
    if (_recording) {
      await _finish(_stopReason ?? 'interrupted');
      return;
    }
    setState(() => _busy = true);
    try {
      await _save();
      _error = null;
    } catch (_) {
      _error = tr('저장하지 못했어요. 다시 시도하세요.', 'Save failed. Please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _judge(bool accepted) async {
    if (_busy || _pending != null || !_review) return;
    setState(() => _busy = true);
    try {
      _trials[_trials.length - 1] = _trials.last.reviewed(accepted);
      _review = false;
      _confirm = false;
      await _save();
      _error = null;
    } catch (_) {
      _error = tr('저장하지 못했어요. 재시도하세요.', 'Save failed. Please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exit() async {
    if (_busy) return;
    if (_recording) await _finish('interrupted');
    if (_pending != null || _recording || !mounted) return;
    await _player?.stop();
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _listen() async {
    try {
      _player ??= ref.read(audioPlayerServiceProvider);
      await _player!.stop();
      await _player!.playFile(_path!);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = tr('녹음을 재생할 수 없어요.', 'Could not play the recording.'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_exit());
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(tr('최대발성시간 (MPT)', 'Maximum phonation time (MPT)')),
        actions: [
          ComfortButton(
            situation: ComfortContext.mpt,
            enabled: !_recording && !_busy,
          ),
        ],
      ),
      bottomNavigationBar: _recording
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_automatic) ...[
                      Text(
                        '${(_displayMs / 1000).toStringAsFixed(1)} ${tr('초', 's')}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      Text(_autoStatus(), textAlign: TextAlign.center),
                    ],
                    if (_error != null && _stopReason != null)
                      FilledButton(
                        onPressed: _busy ? null : _retry,
                        child: Text(tr('저장 재시도', 'Retry save')),
                      ),
                    if (!_automatic && !_timingStarted && _stopReason == null)
                      FilledButton(
                        onPressed: _busy ? null : _beginTiming,
                        child: Text(
                          tr('소리 시작 · 타이머 시작', 'Voice onset · Start timer'),
                        ),
                      ),
                    if (!_automatic && _timingStarted && _stopReason == null)
                      FilledButton(
                        onPressed: _busy ? null : () => _finish('unreviewed'),
                        child: Text(
                          tr('소리 끝 · 타이머 종료', 'Voice offset · Stop timer'),
                        ),
                      ),
                    TextButton(
                      onPressed: _busy ? null : () => _finish('interrupted'),
                      child: Text(tr('불편해요 · 중단', 'Discomfort · Stop')),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                tr(
                  _automatic
                      ? '“아~”를 시작하면 자동으로 시간을 재요.'
                      : '보호자·검사자가 버튼을 눌러 시간을 재요.',
                  _automatic
                      ? 'The timer starts automatically when you sustain “ah”.'
                      : 'A helper or examiner times the sound using the buttons.',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                tr(
                  '편안히 앉아 숨을 충분히 들이마신 뒤, 편안한 높이와 크기로 “아~”를 한 번의 날숨 동안 가능한 만큼 이어 내세요. 억지로 힘주지 마세요. 중간에 숨을 다시 쉬면 그 시도는 제외해요.',
                  'Sit comfortably, take a full breath, then sustain “ah” on one exhalation for as long as you comfortably can at your usual pitch and loudness. Do not strain. Exclude a trial if another breath is taken.',
                ),
              ),
              Text(
                tr(
                  _automatic
                      ? '녹음 준비 → 1.5초 조용히 기다리기 → 준비 안내 후 “아~” 발성 → 자동 종료 → 녹음 확인. 각 시도 사이 충분히 쉬어요.'
                      : '녹음 준비 → 실제 소리 시작 때 타이머 시작 → 소리가 끝나면 종료 → 녹음 확인. 충분히 쉬고 총 3회의 유효 시도를 기록해요.',
                  _automatic
                      ? 'Prepare recording → stay quiet for 1.5 seconds → sustain “ah” when ready → automatic stop → review recording. Rest between trials.'
                      : 'Prepare recording → start timer at voice onset → stop at voice offset → review recording. Rest sufficiently between 3 valid trials.',
                ),
              ),
              Text(
                tr(
                  '통증·어지러움·숨참이 있으면 즉시 멈추세요. 정상·비정상 판정이나 진단은 제공하지 않아요. 자동 감지는 소음·약한 발성에 오차가 있을 수 있고, 앱의 임상 검증은 아직 진행되지 않았어요.',
                  'Stop immediately for pain, dizziness or breathlessness. No normal/abnormal grading or diagnosis is provided. Noise or weak voice can affect automatic timing; the app is not clinically validated.',
                ),
              ),
              SwitchListTile(
                title: Text(tr('발성 자동 감지', 'Automatic voice timing')),
                subtitle: Text(
                  tr(
                    '소리의 시작·끝을 추정해요. “아”인지 또는 한 호흡인지는 녹음으로 확인해요.',
                    'Estimates sound boundaries. Review the vowel and single breath yourself.',
                  ),
                ),
                value: _automatic,
                onChanged: _busy || _recording || _trials.isNotEmpty
                    ? null
                    : (value) => setState(() => _automatic = value),
              ),
              const SizedBox(height: 16),
              Text(tr('유효 시도 $_valid / 3', 'Confirmed trials $_valid / 3')),
              if (_trials.isNotEmpty)
                Text(MptResult.summary(_session().feedback, _en)),
              if (!_recording &&
                  !_review &&
                  _valid < 3 &&
                  _pending == null) ...[
                Text(tr('시작 전 피로도', 'Fatigue before starting')),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var n = 1; n <= 5; n++)
                      ChoiceChip(
                        label: Text('$n / 5'),
                        selected: _fatigue == n,
                        onSelected: _busy || _trials.isNotEmpty
                            ? null
                            : (_) => setState(() => _fatigue = n),
                      ),
                  ],
                ),
                if ((_fatigue ?? 0) >= 4)
                  Text(
                    tr(
                      '피곤하면 오늘은 쉬어도 괜찮아요.',
                      'You can rest today if you feel tired.',
                    ),
                  ),
                CheckboxListTile(
                  value: _ready,
                  onChanged: _busy ? null : (v) => setState(() => _ready = v!),
                  title: Text(
                    tr(
                      _automatic
                          ? '충분히 쉬었고, 조용한 곳에서 녹음을 확인할 준비가 됐어요.'
                          : '충분히 쉬었고, 조용한 곳에서 측정을 도와줄 사람이 준비됐어요.',
                      _automatic
                          ? 'I have rested in a quiet place and am ready to review the recording.'
                          : 'I have rested, and a helper is ready in a quiet place.',
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _busy || !_ready || _fatigue == null
                      ? null
                      : _start,
                  child: Text(tr('녹음 준비', 'Prepare recording')),
                ),
              ],
              if (_recording) ...[
                if (!_automatic)
                  Text(
                    '${(_clock.elapsedMilliseconds / 1000).toStringAsFixed(1)} ${tr('초', 's')}',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                Text(
                  tr(
                    '녹음은 최대 120초입니다. 한도에 도달한 시도는 결과에서 제외돼요.',
                    'Recording is limited to 120 seconds. A trial reaching the limit is excluded.',
                  ),
                ),
              ],
              if (_capture != null && (_recording || _review))
                PracticeWaveform(
                  values: List.of(_capture!.envelope),
                  durationMs: _capture!.durationMs,
                  english: _en,
                ),
              if (_review && _pending == null) ...[
                if (_automatic && (_voiceTimer?.hadGap ?? false))
                  Text(
                    tr(
                      '발성이 잠깐 끊긴 구간이 있어요. 중간에 숨을 다시 쉬었다면 제외하세요.',
                      'A brief gap was detected. Exclude the trial if you took another breath.',
                    ),
                  ),
                if (_path != null)
                  Wrap(
                    spacing: 12,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : _listen,
                        child: Text(tr('녹음 듣기', 'Listen to recording')),
                      ),
                      TextButton(
                        onPressed: () => _player?.stop(),
                        child: Text(tr('재생 중지', 'Stop playback')),
                      ),
                    ],
                  ),
                if (_trials.last.eligible) ...[
                  CheckboxListTile(
                    value: _confirm,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _confirm = v!),
                    title: Text(
                      tr(
                        '한 번의 숨으로 “아”를 냈고, 중간 호흡·기침·방해 소리 없이 끝까지 정확히 시간을 쟀어요. 녹음도 확인했어요.',
                        'I checked the recording: one sustained “ah” on one breath, no cough or interference, and correctly timed onset and offset.',
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy || !_confirm ? null : () => _judge(true),
                    child: Text(tr('유효 시도로 저장', 'Confirm valid trial')),
                  ),
                ] else
                  Text(
                    tr(
                      '중단·오류 또는 측정 구간이 없어 유효 시도로 쓸 수 없어요.',
                      'Interrupted, failed or untimed audio cannot count as a valid trial.',
                    ),
                  ),
                TextButton(
                  onPressed: _busy ? null : () => _judge(false),
                  child: Text(tr('이 시도 제외 · 쉬기', 'Exclude trial · Rest')),
                ),
              ],
              if (_error != null) Text(_error!),
              if (_pending != null)
                TextButton(
                  onPressed: _busy ? null : _retry,
                  child: Text(tr('저장 재시도', 'Retry save')),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _busy ? null : _exit,
                child: Text(tr('마치기', 'Finish')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
