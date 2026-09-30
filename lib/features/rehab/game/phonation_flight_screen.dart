import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../audio/practice_capture.dart';
import '../audio/practice_waveform.dart';
import '../model/rehab_session.dart';
import '../services/rehab_session_repository.dart';
import '../view/rehab_ui.dart';
import '../view/rehab_records_screen.dart';
import 'phonation_flight_engine.dart';

class PhonationFlightScreen extends ConsumerStatefulWidget {
  const PhonationFlightScreen({super.key});
  @override
  ConsumerState<PhonationFlightScreen> createState() => _FlightState();
}

class _FlightState extends ConsumerState<PhonationFlightScreen>
    with WidgetsBindingObserver {
  PracticeCapture? _capture;
  PhonationFlightEngine _flight = PhonationFlightEngine();
  bool _running = false, _busy = false, _background = false, _allowPop = false;
  String? _error, _id, _path;
  DateTime? _started;
  RehabSession? _pending;
  bool _saved = false;
  int? _fatigue;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background = state != AppLifecycleState.resumed;
    if (_background && _running && !_busy) unawaited(_finish());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _capture?.frame.removeListener(_frame);
    _capture?.problem.removeListener(_inputEnded);
    _capture?.limitReached.removeListener(_inputEnded);
    super.dispose();
  }

  Future<void> _start() async {
    if (_busy || _running || _pending != null || _fatigue == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_capture == null) {
        _capture = ref.read(practiceCaptureProvider);
        _capture!.frame.addListener(_frame);
        _capture!.problem.addListener(_inputEnded);
        _capture!.limitReached.addListener(_inputEnded);
      }
      _flight = PhonationFlightEngine();
      _id = const Uuid().v4();
      _started = DateTime.now();
      _path = null;
      _saved = false;
      await _capture!.startRecording('rehab_$_id');
      if (mounted) setState(() => _running = true);
    } catch (_) {
      if (mounted) setState(() => _error = rehabL10n(context).rehabRecordError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_background && mounted && _running) await _finish();
    if (mounted) _inputEnded();
  }

  void _frame() {
    if (!mounted || !_running) return;
    final frame = _capture!.frame.value;
    if (frame == null) return;
    setState(() => _flight.add(frame));
    // A product limit for this easy practice round, not a therapeutic dose/MPT.
    if (_flight.elapsedMs >= 20000 && !_busy) unawaited(_finish());
  }

  void _inputEnded() {
    if (_running &&
        !_busy &&
        (_capture!.problem.value != null || _capture!.limitReached.value)) {
      unawaited(_finish());
    }
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _path ??= await _capture!.stopRecording();
      if (_path == null) throw StateError('No audio');
      if (!mounted) return;
      _running = false;
      final en = rehabEnglish(context), now = _started!;
      _pending ??= RehabSession(
        id: _id!,
        title: en ? 'Gentle voice flight' : '목소리로 천천히 날기',
        language: en ? 'en-US' : 'ko-KR',
        startedAt: now.toUtc(),
        localDate: rehabDate(now),
        offsetMinutes: now.timeZoneOffset.inMinutes,
        repetitions: 1,
        fatigueBefore: _fatigue!,
        fatigueChecks: [_fatigue!],
        tasks: [
          RehabTask(
            id: 'voice-flight',
            title: en ? 'Voice play' : '발성 놀이',
            text: en ? 'ah' : '아~',
            instruction: en ? 'Comfortable sustained sound' : '편안하게 이어 내는 소리',
            prompt: 'game-feedback-not-mpt',
          ),
        ],
        takes: [
          RehabTake(
            id: _id!,
            taskId: 'voice-flight',
            text: en ? 'ah' : '아~',
            path: _path!,
            createdAt: now,
            seconds: (_capture!.durationMs / 1000).ceil(),
            durationMs: _capture!.durationMs,
            waveform: List.of(_capture!.envelope),
          ),
        ],
        status: RehabStatus.partial,
        feedback: {
          'kind': 'voiceFlight',
          'version': PhonationFlightEngine.version,
          'longestDetectedMs': _flight.longestMs,
          'totalDetectedMs': _flight.voicedMs,
          'noiseDbfs': _flight.noiseDbfs,
          'baselinePitchHz': _flight.basePitchHz,
          'notMpt': true,
          'hasDetectedVoice': _flight.longestMs > 0,
        },
      );
      await ref.read(rehabRepositoryProvider).save(_pending!);
      ref.invalidate(rehabSessionsProvider);
      if (mounted) {
        setState(() {
          _pending = null;
          _saved = true;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _running = _capture?.hasPendingAudio == true;
          _error = rehabL10n(context).rehabSaveError;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exit() async {
    if (_busy) return;
    if (_running || _pending != null) await _finish();
    if (!mounted || _running || _pending != null) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final en = rehabEnglish(context);
    final status = _flight.calibrating
        ? (en
              ? 'Checking room sound · stay quiet briefly'
              : '주변 소리 확인 중 · 잠깐 조용히 기다려요')
        : _flight.clipping
        ? (en ? 'Microphone input is clipping' : '소리가 찌그러질 수 있어요')
        : !_flight.detecting
        ? (en
              ? 'Resting · movement pauses when pitch is unclear'
              : '쉬는 중 · 높이를 읽기 어려우면 움직임도 쉬어요')
        : (en
              ? 'Comfortable sound · no need to go higher or louder'
              : '편안한 소리 · 더 높이 또는 크게 내지 않아도 돼요');
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_exit());
      },
      child: Scaffold(
        appBar: AppBar(title: Text(en ? 'Gentle voice flight' : '목소리로 천천히 날기')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  en
                      ? 'Say “ah” at a comfortable pitch and loudness. The bird floats with your voice. There are no collisions or failures.'
                      : '편안한 높이와 크기로 “아~” 소리를 내보세요. 목소리를 따라 새가 떠요. 부딪히거나 탈락하지 않아요.',
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: en
                      ? 'Voice controlled bird. ${_running ? status : "Ready"}'
                      : '목소리로 움직이는 새. ${_running ? status : "준비"}',
                  child: SizedBox(
                    height: 220,
                    child: CustomPaint(
                      painter: _FlightPainter(
                        height: _flight.height,
                        distance: _flight.voicedMs / 1000,
                        active: _running && _flight.detecting,
                      ),
                    ),
                  ),
                ),
                if (_running) Text(status),
                Text(
                  en
                      ? 'One round ends within 20 seconds. Stop earlier whenever you wish.'
                      : '한 차례는 최대 20초 안에 끝나요. 원할 때 더 일찍 멈춰도 괜찮아요.',
                ),
                const SizedBox(height: 12),
                Text(
                  en
                      ? (_flight.longestMs == 0
                            ? 'No reliable voice segment detected yet.'
                            : 'Detected continuous segment: ${(_flight.longestMs / 1000).toStringAsFixed(1)} s (estimate)')
                      : (_flight.longestMs == 0
                            ? '아직 확실하게 검출된 발성 구간이 없어요.'
                            : '검출된 가장 긴 연속 구간: ${(_flight.longestMs / 1000).toStringAsFixed(1)}초 (추정)'),
                ),
                Text(
                  en
                      ? 'This is voice play, not an MPT measurement. Noise or a weak/irregular voice can affect detection. Longer is not automatically better.'
                      : 'MPT 측정이 아닌 발성 놀이예요. 소음이나 약하고 불규칙한 목소리는 검출이 어려울 수 있어요. 오래 한다고 더 좋은 것은 아니에요.',
                ),
                if (!_running && !_saved && _pending == null) ...[
                  const SizedBox(height: 16),
                  Text(rehabL10n(context).rehabFatigue),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var n = 1; n <= 5; n++)
                        ChoiceChip(
                          label: Text('$n / 5'),
                          selected: _fatigue == n,
                          onSelected: _busy
                              ? null
                              : (_) => setState(() => _fatigue = n),
                        ),
                    ],
                  ),
                  if ((_fatigue ?? 0) >= 4)
                    Text(rehabL10n(context).rehabRestHint),
                ],
                const SizedBox(height: 12),
                Text(rehabL10n(context).rehabSafety),
                if (_error != null) ...[
                  Text(_error!),
                  if (_pending != null || _capture?.hasPendingAudio == true)
                    TextButton(
                      onPressed: _busy ? null : _finish,
                      child: Text(rehabL10n(context).rehabRetrySave),
                    ),
                ],
                if (_saved) ...[
                  Text(
                    en
                        ? 'Audio and game feedback saved in Records.'
                        : '녹음과 놀이 참고 기록을 저장했어요.',
                  ),
                  PracticeWaveform(
                    values: _capture!.envelope,
                    durationMs: _capture!.durationMs,
                    english: en,
                  ),
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const RehabRecordsScreen(),
                        ),
                      );
                    },
                    child: Text(en ? 'View recordings' : '녹음 기록 보기'),
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
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _busy
                  ? null
                  : _saved
                  ? _exit
                  : _running
                  ? _finish
                  : _pending != null
                  ? _finish
                  : _fatigue == null
                  ? null
                  : _start,
              child: Text(
                en
                    ? (_saved
                          ? 'Done'
                          : _running
                          ? 'Stop and rest'
                          : _pending != null
                          ? 'Retry save'
                          : 'Start gently')
                    : (_saved
                          ? '마치기'
                          : _running
                          ? '멈추고 쉬기'
                          : _pending != null
                          ? '다시 저장'
                          : '편안하게 시작'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlightPainter extends CustomPainter {
  _FlightPainter({
    required this.height,
    required this.distance,
    required this.active,
  });
  final double height, distance;
  final bool active;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      Paint()..color = const Color(0xff102c3f),
    );
    // Broad decorative hoops, deliberately no collision detection or score.
    for (var i = 0; i < 4; i++) {
      final x =
          (size.width + i * size.width / 3 - distance * 18) % (size.width + 90);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, size.height * .5),
          width: 34,
          height: size.height * .78,
        ),
        Paint()
          ..color = const Color(0xff89d9c7).withValues(alpha: .4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final center = Offset(size.width * .26, size.height * height);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 46, height: 34),
      Paint()..color = const Color(0xffffd27b),
    );
    final wing = Path()
      ..moveTo(center.dx - 10, center.dy)
      ..quadraticBezierTo(
        center.dx - 30,
        center.dy - 20 - (active ? math.sin(distance * 4) * 5 : 0),
        center.dx - 18,
        center.dy + 10,
      )
      ..close();
    canvas.drawPath(wing, Paint()..color = const Color(0xffe5a23f));
    canvas.drawCircle(
      center + const Offset(13, -5),
      3,
      Paint()..color = const Color(0xff142332),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + 21, center.dy)
        ..lineTo(center.dx + 32, center.dy + 4)
        ..lineTo(center.dx + 21, center.dy + 8)
        ..close(),
      Paint()..color = const Color(0xfff3aa5a),
    );
  }

  @override
  bool shouldRepaint(covariant _FlightPainter old) =>
      old.height != height || old.distance != distance || old.active != active;
}
