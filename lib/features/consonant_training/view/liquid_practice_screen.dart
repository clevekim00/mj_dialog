import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../rehab/audio/practice_capture.dart';
import '../../rehab/audio/practice_waveform.dart';
import '../../../services/audio/audio_player_service.dart';
import '../../../services/audio_analysis/wav_file_service.dart';
import '../audio/liquid_recording_audio.dart';
import '../data/liquid_practice_content.dart';
import '../model/consonant_training_models.dart';
import '../services/consonant_training_history_service.dart';
import '../services/pronunciation_analysis_client.dart';
import 'liquid_review_panel.dart';

class LiquidPracticeScreen extends StatefulWidget {
  const LiquidPracticeScreen({
    super.key,
    required this.history,
    this.capture,
    this.analysisClient,
  });
  final ConsonantTrainingHistoryService history;
  final PracticeCapture? capture;
  final PronunciationAnalysisClient? analysisClient;
  @override
  State<LiquidPracticeScreen> createState() => _LiquidPracticeScreenState();
}

class _LiquidPracticeScreenState extends State<LiquidPracticeScreen>
    with WidgetsBindingObserver {
  late final _capture = widget.capture ?? PracticeCapture();
  final _player = AudioPlayerService();
  final _custom = TextEditingController();
  final _server = TextEditingController(
    text: const String.fromEnvironment('PRONUNCIATION_ANALYSIS_URL'),
  );
  final _token = TextEditingController();
  LiquidExercise _exercise = LiquidExercise.repetition;
  String _value = '라';
  int _repetitions = 5, _operation = 0;
  bool _recording = false,
      _busy = false,
      _analyzing = false,
      _consent = false,
      _interrupted = false,
      _loading = true;
  String? _notice;
  ConsonantTrainingAttempt? _attempt, _previous, _unsaved;
  PronunciationContentItem? _recordedItem;
  Timer? _limit;
  CancelToken? _cancel;
  bool get _locked => _recording || _busy || _analyzing;
  PronunciationContentItem get _item => LiquidPracticeContent.item(
    _exercise,
    _exercise == LiquidExercise.custom ? _custom.text : _value,
    repetitions: _repetitions,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _capture.problem.addListener(_captureProblem);
    _capture.limitReached.addListener(_captureLimit);
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kind = prefs.getString('liquid_kind');
      if (!mounted) return;
      final matches = LiquidExercise.values.where((e) => e.name == kind);
      if (matches.isNotEmpty) _exercise = matches.first;
      final saved = prefs.getString('liquid_value');
      _repetitions = [3, 5, 7].contains(prefs.getInt('liquid_repetitions'))
          ? prefs.getInt('liquid_repetitions')!
          : 5;
      final examples = _exercise == LiquidExercise.repetition
          ? LiquidPracticeContent.vowels
          : LiquidPracticeContent.examples[_exercise] ?? const <String>[];
      _value = saved != null && examples.contains(saved)
          ? saved
          : examples.isEmpty
          ? ''
          : examples.first;
      // User-entered text lives in saved attempts, not in settings.
      await _loadPrevious();
    } catch (_) {
      if (mounted) setState(() => _notice = '이전 설정을 불러오지 못했어요. 기본 연습으로 시작합니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _settings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('liquid_kind', _exercise.name);
      await prefs.setString('liquid_value', _value);
      await prefs.setInt('liquid_repetitions', _repetitions);
    } catch (_) {
      if (mounted) setState(() => _notice = '연습 설정을 저장하지 못했어요. 녹음은 별도로 보관됩니다.');
    }
  }

  Future<void> _loadPrevious() async {
    final item = _item;
    final attemptId = _attempt?.id;
    final previous = await widget.history.previousFor(
      targetId: item.targetId,
      contentId: item.id,
      text: item.text,
      language: 'ko-KR',
      excludingId: _attempt?.id,
      createdBefore: _attempt?.createdAt,
      contentVersion: LiquidPracticeContent.version,
    );
    if (mounted && _item.id == item.id && _attempt?.id == attemptId) {
      setState(() => _previous = previous);
    }
  }

  void _choose(LiquidExercise kind, [String? value]) {
    if (_locked || _unsaved != null) return;
    unawaited(_player.stop());
    setState(() {
      _exercise = kind;
      _value =
          value ??
          (kind == LiquidExercise.repetition
              ? LiquidPracticeContent.vowels.first
              : LiquidPracticeContent.examples[kind]?.first ?? '');
      _attempt = null;
      _previous = null;
      _notice = null;
      _consent = false;
    });
    unawaited(_settings());
    unawaited(_loadPrevious());
  }

  void _captureProblem() {
    if (_recording && _capture.problem.value != null) {
      _interrupted = true;
      unawaited(_stop());
    }
  }

  void _captureLimit() {
    if (_recording && _capture.limitReached.value) unawaited(_stop());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _interrupted = true;
      if (_recording) unawaited(_stop());
      _cancelAnalysis('background');
      unawaited(_player.stop());
    }
  }

  Future<void> _start() async {
    if (_locked || _unsaved != null) return;
    if (_capture.hasPendingAudio) {
      await _stop();
      return;
    }
    final item = _item;
    if (item.text.trim().isEmpty) {
      setState(() => _notice = '연습할 문장을 입력하세요.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _notice = null;
      _interrupted = false;
    });
    try {
      await _player.stop();
      await _capture.startRecording(
        'liquid_${DateTime.now().microsecondsSinceEpoch}',
      );
      if (!mounted) return;
      setState(() {
        _recordedItem = item;
        _recording = true;
        _attempt = null;
        _consent = false;
      });
      _limit = Timer(const Duration(seconds: 20), () {
        if (_recording) unawaited(_stop());
      });
    } catch (_) {
      if (mounted) {
        setState(() => _notice = '녹음을 시작하지 못했어요. 마이크 권한을 확인하고 다시 시도하세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_interrupted && _recording) await _stop();
  }

  Future<void> _stop() async {
    if (_busy || (!_recording && !_capture.hasPendingAudio)) return;
    _limit?.cancel();
    setState(() => _busy = true);
    try {
      final path = await _capture.stopRecording();
      if (!mounted) return;
      if (path == null || _capture.durationMs <= 0) {
        setState(() {
          _recording = false;
          _notice = '소리가 저장되지 않았어요. 다시 녹음해 주세요.';
        });
        return;
      }
      final item = _recordedItem!;
      _unsaved = ConsonantTrainingAttempt(
        id: 'liquid_${DateTime.now().microsecondsSinceEpoch}',
        targetId: item.targetId,
        contentId: item.id,
        text: item.text,
        level: item.level,
        audioFilePath: path,
        createdAt: DateTime.now(),
        language: 'ko-KR',
        durationMs: _capture.durationMs,
        waveform: List.of(_capture.envelope),
        exerciseKind: _exercise.name,
        plannedRepetitions: _exercise == LiquidExercise.repetition
            ? _repetitions
            : null,
        contentVersion: LiquidPracticeContent.version,
        analysis: PronunciationAnalysisResult.unavailable(
          _interrupted
              ? '중단된 녹음이에요. 듣고 확인해 주세요.'
              : '녹음은 기기에 저장돼요. 자동 발음 점수는 검증된 평가 모델이 필요해요.',
        ),
      );
      setState(() => _recording = false);
      await _savePending();
    } catch (_) {
      if (mounted) {
        setState(() => _notice = '저장하지 못했어요. 녹음 보존을 위해 저장을 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePending() async {
    final pending = _unsaved;
    if (pending == null) return;
    try {
      await widget.history.add(pending);
      if (!mounted) return;
      setState(() {
        _attempt = pending;
        _unsaved = null;
        _notice = _interrupted
            ? '중단된 녹음을 보관했어요.'
            : '녹음을 보관했어요. 같은 항목을 다시 읽어 비교할 수 있어요.';
      });
      await _loadPrevious();
    } catch (_) {
      if (mounted) setState(() => _notice = '녹음 보관에 실패했어요. 저장 재시도를 눌러 주세요.');
    }
  }

  Future<void> _reference() async {
    if (_locked) return;
    if (_exercise == LiquidExercise.custom) {
      setState(() => _notice = '직접 입력한 문장의 예시 음성은 아직 준비되지 않았어요.');
      return;
    }
    final name = _value;
    final repeatCount = _exercise == LiquidExercise.repetition
        ? _repetitions
        : 1;
    String? referencePath;
    setState(() => _busy = true);
    StreamSubscription<dynamic>? completion;
    try {
      final done = Completer<void>();
      completion = _player.playbackEvents.listen(
        (event) {
          if (event == 'complete' && !done.isCompleted) done.complete();
        },
        onError: (Object error) {
          if (!done.isCompleted) done.completeError(error);
        },
      );
      final bytes = await rootBundle.load(
        LiquidPracticeContent.referenceAsset(name),
      );
      final source = LiquidRecordingAudio.decode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final audio = source.repeated(repeatCount);
      referencePath = await const WavFileService().writePcm16(
        audio.pcm,
        fileName: 'liquid_reference_${DateTime.now().microsecondsSinceEpoch}',
        sampleRate: audio.sampleRate,
        persistent: false,
      );
      if (!mounted || _recording || _analyzing) return;
      await _player.stop();
      await _player.playFile(referencePath);
      await done.future.timeout(const Duration(seconds: 12));
    } catch (_) {
      if (mounted) {
        setState(() => _notice = '이 항목의 예시 음성을 재생하지 못했어요. 녹음·듣기는 사용할 수 있어요.');
      }
    } finally {
      await completion?.cancel();
      await _player.stop();
      if (referencePath != null) {
        try {
          await File(referencePath).delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selfReport(String value) async {
    final current = _attempt;
    if (current == null || _locked) return;
    setState(() => _busy = true);
    try {
      final updated = current.withSelfReport(value);
      await widget.history.add(updated);
      if (mounted) setState(() => _attempt = updated);
    } catch (_) {
      if (mounted) setState(() => _notice = '체크를 저장하지 못했어요. 다시 시도하세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _analyze() async {
    final attempt = _attempt;
    if (attempt == null || _locked || !_consent) return;
    if (_exercise == LiquidExercise.custom) {
      setState(
        () => _notice = '내 연습은 녹음·수동 비교를 제공해요. 발음 환경 검수 후 자동 분석을 지원합니다.',
      );
      return;
    }
    if (attempt.durationMs > 20000) {
      setState(() => _notice = '20초를 넘는 녹음은 짧게 나눠 다시 녹음해 주세요. 원본은 보관됩니다.');
      return;
    }
    final cancel = CancelToken(), operation = ++_operation;
    setState(() {
      _analyzing = true;
      _cancel = cancel;
    });
    try {
      await _player.stop();
      final client =
          widget.analysisClient ??
          PronunciationAnalysisClient(
            baseUrl: _server.text.trim(),
            accessTokenProvider: () async => _token.text.trim(),
          );
      final result = await client.analyze(
        audioFilePath: attempt.audioFilePath,
        item: _recordedItem ?? _item,
        target: LiquidPracticeContent.target(_exercise),
        contentVersion: LiquidPracticeContent.version,
        language: 'ko-KR',
        cancelToken: cancel,
        allOccurrences: true,
      );
      if (!mounted || cancel.isCancelled || operation != _operation) return;
      final updated = attempt.withAnalysis(result);
      await widget.history.add(updated);
      if (mounted && !cancel.isCancelled && operation == _operation) {
        setState(() => _attempt = updated);
      }
    } catch (_) {
      if (mounted && operation == _operation) {
        setState(() => _notice = '분석을 완료하지 못했어요. 녹음은 보관돼 있어요.');
      }
    } finally {
      if (mounted && operation == _operation) {
        setState(() {
          _analyzing = false;
          _cancel = null;
        });
      }
    }
  }

  void _cancelAnalysis([String reason = 'user']) {
    if (!_analyzing) return;
    _operation++;
    _cancel?.cancel(reason);
    setState(() {
      _analyzing = false;
      _cancel = null;
      _notice = '분석을 취소했어요. 녹음은 기기에 보관돼 있어요.';
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _operation++;
    _cancel?.cancel('closed');
    _limit?.cancel();
    _capture.problem.removeListener(_captureProblem);
    _capture.limitReached.removeListener(_captureLimit);
    unawaited(_capture.dispose());
    unawaited(_player.stop());
    _player.dispose();
    _custom.dispose();
    _server.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_locked && _unsaved == null && !_capture.hasPendingAudio,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && mounted) {
        setState(() => _notice = '녹음을 멈추고 저장하거나 분석을 취소한 뒤 돌아가세요.');
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('ㄹ 집중 연습')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            key: const ValueKey('liquid-record'),
            onPressed: _loading || _busy || _analyzing || _unsaved != null
                ? null
                : _recording
                ? _stop
                : _start,
            icon: Icon(_recording ? Icons.stop : Icons.mic),
            label: Text(
              _busy
                  ? '저장·준비 중'
                  : _recording
                  ? '녹음 끝내고 저장'
                  : _attempt != null
                  ? '같은 항목 다시 녹음'
                  : '따라 읽고 녹음',
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  '단어 속 ㄹ · 받침과 이어지는 ㄹ · 반복 후반을 각각 연습해요. 쉬거나 멈춰도 괜찮아요.',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final kind in LiquidExercise.values)
                      ChoiceChip(
                        label: Text(kind.label),
                        selected: _exercise == kind,
                        onSelected: _locked || _unsaved != null
                            ? null
                            : (_) => _choose(kind),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_exercise == LiquidExercise.custom)
                  TextField(
                    controller: _custom,
                    enabled: !_locked && _unsaved == null,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: '내가 어려운 단어·문장',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _attempt = null;
                        _previous = null;
                      });
                      unawaited(_loadPrevious());
                    },
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final text
                          in _exercise == LiquidExercise.repetition
                              ? LiquidPracticeContent.vowels
                              : LiquidPracticeContent.examples[_exercise]!)
                        ChoiceChip(
                          label: Text(text),
                          selected: _value == text,
                          onSelected: _locked || _unsaved != null
                              ? null
                              : (_) => _choose(_exercise, text),
                        ),
                    ],
                  ),
                if (_exercise == LiquidExercise.repetition) ...[
                  const Text('한 번의 녹음에서 읽을 음절 수'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final count in [3, 5, 7])
                        ChoiceChip(
                          label: Text('$count번 반복'),
                          selected: _repetitions == count,
                          onSelected: _locked || _unsaved != null
                              ? null
                              : (_) {
                                  setState(() {
                                    _repetitions = count;
                                    _attempt = null;
                                    _previous = null;
                                  });
                                  unawaited(_settings());
                                  unawaited(_loadPrevious());
                                },
                        ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('모음별 연습표 보기'),
                    children: [
                      for (final syllable in LiquidPracticeContent.vowels)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            List.filled(_repetitions, syllable).join(' '),
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                    ],
                  ),
                ],
                const Text('강조된 ㄹ은 글자의 연습 위치예요. 실제 발음 판정은 아니에요.'),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: LiquidTargetText(
                      text: _item.text.isEmpty ? '연습할 문장을 입력하세요' : _item.text,
                      size:
                          _exercise == LiquidExercise.sentence ||
                              _exercise == LiquidExercise.custom
                          ? 30
                          : 44,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _locked ? null : _reference,
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('예시 듣기 · 합성 음성'),
                ),
                const Text(
                  '합성 음성은 참고용이에요. 예시는 화면의 반복 횟수와 같아요. 듣고 내 속도로 읽으세요. 한 항목은 최대 20초 녹음해요.',
                ),
                if (_recording)
                  ValueListenableBuilder(
                    valueListenable: _capture.frame,
                    builder: (context, frame, _) => PracticeWaveform(
                      values: List.of(_capture.envelope),
                      durationMs: _capture.durationMs,
                      english: false,
                      live: frame,
                    ),
                  ),
                if (_notice != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_notice!, semanticsLabel: _notice),
                  ),
                if (_unsaved != null)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            await _savePending();
                            if (mounted) setState(() => _busy = false);
                          },
                    child: const Text('녹음 저장 재시도'),
                  ),
                if ((_recording || _capture.hasPendingAudio) && _notice != null)
                  TextButton(
                    onPressed: _busy ? null : _stop,
                    child: const Text('저장 재시도'),
                  ),
                if (_attempt != null) ...[
                  LiquidReviewPanel(
                    attempt: _attempt!,
                    previous: _previous,
                    enabled: !_locked,
                  ),
                  const SizedBox(height: 12),
                  const Text('반복 후반이나 목표 ㄹ이 더 어려웠나요? · 내가 느낀 점'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final report in ['비슷해요', '더 어려워요', '모르겠어요'])
                        ChoiceChip(
                          label: Text(report),
                          selected: _attempt!.selfReport == report,
                          onSelected: _locked
                              ? null
                              : (_) => _selfReport(report),
                        ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('동의 후 음성 분석 · 서버 설정'),
                    children: [
                      const Text(
                        '선택한 녹음과 목표 문장을 입력한 서버로 전송해요. 구간 정렬은 발음 정확도 평가와 달라요. 검증된 채점 모델이 없으면 점수를 표시하지 않아요.',
                      ),
                      TextField(
                        controller: _server,
                        enabled: !_locked,
                        decoration: const InputDecoration(
                          labelText: '분석 서버 주소 (HTTPS)',
                        ),
                      ),
                      TextField(
                        controller: _token,
                        enabled: !_locked,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: '로그인 토큰 · 저장 안 함',
                        ),
                      ),
                      CheckboxListTile(
                        value: _consent,
                        onChanged: _locked
                            ? null
                            : (v) => setState(() => _consent = v ?? false),
                        title: const Text('이번 녹음을 이 서버로 보내는 데 동의해요'),
                      ),
                      FilledButton(
                        onPressed:
                            _locked ||
                                !_consent ||
                                _exercise == LiquidExercise.custom
                            ? null
                            : _analyze,
                        child: const Text('음소 구간과 발음 피드백 요청'),
                      ),
                      if (_analyzing) ...[
                        const LinearProgressIndicator(),
                        TextButton(
                          onPressed: () => _cancelAnalysis(),
                          child: const Text('분석 취소'),
                        ),
                      ],
                    ],
                  ),
                ] else if (_previous != null)
                  LiquidReviewPanel(attempt: _previous!, enabled: !_locked),
              ],
            ),
    ),
  );
}

class LiquidTargetText extends StatelessWidget {
  const LiquidTargetText({super.key, required this.text, this.size = 36});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        for (final rune in text.runes)
          TextSpan(
            text: String.fromCharCode(rune),
            style: _hasLiquid(rune)
                ? TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                  )
                : null,
          ),
      ],
    ),
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: size, fontWeight: FontWeight.w600),
  );
  bool _hasLiquid(int rune) {
    final index = rune - 0xac00;
    return rune == 0x3139 ||
        index >= 0 && index <= 11171 && (index ~/ 588 == 5 || index % 28 == 8);
  }
}
