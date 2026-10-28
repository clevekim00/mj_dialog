import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../services/audio/audio_player_service.dart';
import '../audio/liquid_recording_audio.dart';
import '../model/consonant_training_models.dart';

typedef LiquidPlayRange =
    Future<void> Function(ConsonantTrainingAttempt, int, int);

class LiquidReviewPanel extends StatefulWidget {
  const LiquidReviewPanel({
    super.key,
    required this.attempt,
    this.previous,
    this.enabled = true,
  });
  final ConsonantTrainingAttempt attempt;
  final ConsonantTrainingAttempt? previous;
  final bool enabled;
  @override
  State<LiquidReviewPanel> createState() => _LiquidReviewPanelState();
}

class _LiquidReviewPanelState extends State<LiquidReviewPanel> {
  final _player = AudioPlayerService();
  StreamSubscription<dynamic>? _events;
  Completer<void>? _done;
  Timer? _ticker;
  int _generation = 0, _position = 0;
  String? _playing, _error;
  final _clips = <String>{};

  @override
  void initState() {
    super.initState();
    _events = _player.playbackEvents.listen(
      (event) {
        if (event == 'complete' && _done?.isCompleted == false) {
          _done!.complete();
        }
      },
      onError: (Object error) {
        if (_done?.isCompleted == false) _done!.completeError(error);
      },
    );
  }

  @override
  void didUpdateWidget(covariant LiquidReviewPanel old) {
    super.didUpdateWidget(old);
    if ((!widget.enabled && old.enabled) ||
        old.attempt.id != widget.attempt.id) {
      unawaited(_stop());
    }
  }

  Future<void> _stop() async {
    _generation++;
    final oldClips = _clips.toList();
    _ticker?.cancel();
    if (_done?.isCompleted == false) _done!.complete();
    _done = null;
    if (mounted) setState(() => _playing = null);
    try {
      await _player.stop();
    } catch (_) {}
    for (final path in oldClips) {
      try {
        await File(path).delete();
        _clips.remove(path);
      } catch (_) {}
    }
  }

  Future<void> _sequence(
    List<(ConsonantTrainingAttempt, int, int)> ranges,
  ) async {
    final generation = _generation + 1;
    await _stop();
    if (!mounted || !widget.enabled || generation != _generation) return;
    try {
      for (final (attempt, start, end) in ranges) {
        if (generation != _generation || !mounted || !widget.enabled) return;
        final audio = await LiquidRecordingAudio.load(attempt.audioFilePath);
        if (generation != _generation || !mounted) return;
        final path = await audio.writeClip(
          start,
          end,
          'liquid_clip_${DateTime.now().microsecondsSinceEpoch}',
        );
        _clips.add(path);
        if (generation != _generation || !mounted) {
          await File(path).delete();
          _clips.remove(path);
          return;
        }
        final done = Completer<void>();
        _done = done;
        setState(() {
          _playing = attempt.id;
          _position = start;
          _error = null;
        });
        final clock = Stopwatch()..start();
        await _player.playFile(path);
        if (generation != _generation || !mounted) return;
        _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
          if (mounted && generation == _generation) {
            setState(
              () =>
                  _position = math.min(end, start + clock.elapsedMilliseconds),
            );
          }
        });
        try {
          await done.future.timeout(Duration(milliseconds: end - start + 5000));
        } finally {
          _ticker?.cancel();
        }
        if (generation != _generation || !mounted) return;
        await _player.stop();
        await File(path).delete();
        _clips.remove(path);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = '이 녹음 구간을 재생하지 못했어요. 파일을 확인하고 다시 시도하세요.');
      }
      if (generation == _generation) await _player.stop();
    } finally {
      if (mounted && generation == _generation) {
        setState(() {
          _playing = null;
          _done = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _ticker?.cancel();
    if (_done?.isCompleted == false) _done!.complete();
    unawaited(_events?.cancel());
    unawaited(_player.stop());
    for (final path in _clips) {
      unawaited(File(path).delete().catchError((_) => File(path)));
    }
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.attempt.analysis;
    final previous =
        widget.previous?.contentId == widget.attempt.contentId &&
            widget.previous?.text == widget.attempt.text &&
            widget.previous?.language == widget.attempt.language &&
            widget.previous?.contentVersion == widget.attempt.contentVersion
        ? widget.previous
        : null;
    final comparableScores =
        previous != null &&
        result.hasReliableScore &&
        previous.analysis.hasReliableScore &&
        result.modelVersion == previous.analysis.modelVersion &&
        widget.attempt.contentVersion == previous.contentVersion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('음성 평가와 비교', style: Theme.of(context).textTheme.titleLarge),
        Text(
          result.hasReliableScore
              ? '연습 점수 ${result.overallPracticeScore}점'
              : '발음 점수 · 평가 준비 전',
        ),
        Text(result.message ?? '내 목소리를 듣고 어려웠던 ㄹ 구간을 확인해 보세요.'),
        if (comparableScores)
          Text(
            '이전 대비 ${result.overallPracticeScore! - previous.analysis.overallPracticeScore!}점 · 같은 분석 모델',
          ),
        const Text('파형은 입력 크기예요. 파형이나 음성인식 글자만으로 발음 정확도를 판단하지 않아요.'),
        if (_playing != null)
          TextButton.icon(
            onPressed: _stop,
            icon: const Icon(Icons.stop),
            label: const Text('듣기 멈추기'),
          ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _WaveCard(
                key: ValueKey(widget.attempt.id),
                attempt: widget.attempt,
                title: '이번 녹음',
                enabled: widget.enabled,
                cursorMs: _playing == widget.attempt.id ? _position : null,
                onPlay: (a, start, end) => _sequence([(a, start, end)]),
              ),
              if (previous != null)
                _WaveCard(
                  key: ValueKey(previous.id),
                  attempt: previous,
                  title: '이전 같은 조건 녹음',
                  enabled: widget.enabled,
                  cursorMs: _playing == previous.id ? _position : null,
                  onPlay: (a, start, end) => _sequence([(a, start, end)]),
                ),
            ];
            return constraints.maxWidth >= 900 && cards.length == 2
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final card in cards) Expanded(child: card)],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: cards,
                  );
          },
        ),
        if (previous != null) ...[
          OutlinedButton.icon(
            onPressed: widget.enabled && previous.durationMs > 0
                ? () => _sequence([
                    (previous, 0, previous.durationMs),
                    (widget.attempt, 0, widget.attempt.durationMs),
                  ])
                : null,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('이전 → 이번 순서대로 듣기'),
          ),
        ] else
          const Text('같은 항목을 다시 녹음하면 이전 녹음과 비교할 수 있어요.'),
      ],
    );
  }
}

class _WaveCard extends StatefulWidget {
  const _WaveCard({
    super.key,
    required this.attempt,
    required this.title,
    required this.enabled,
    required this.onPlay,
    this.cursorMs,
  });
  final ConsonantTrainingAttempt attempt;
  final String title;
  final bool enabled;
  final LiquidPlayRange onPlay;
  final int? cursorMs;
  @override
  State<_WaveCard> createState() => _WaveCardState();
}

class _WaveCardState extends State<_WaveCard> {
  RangeValues _range = const RangeValues(0, 1);
  @override
  Widget build(BuildContext context) {
    final attempt = widget.attempt, duration = widget.attempt.durationMs;
    final phones =
        attempt.analysis.signalAccepted &&
            attempt.analysis.status == PronunciationAnalysisStatus.completed
        ? attempt.analysis.phonemes
              .where(
                (p) =>
                    p.startMs >= 0 &&
                    p.endMs > p.startMs &&
                    p.endMs <= duration,
              )
              .toList()
        : <PhonemeAnalysisResult>[];
    void select(int start, int end) {
      setState(() => _range = RangeValues(start / duration, end / duration));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.title} · ${(duration / 1000).toStringAsFixed(1)}초',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (attempt.selfReport != null)
              Text('내가 느낀 점: ${attempt.selfReport}'),
            if (duration > 0) ...[
              Semantics(
                label: '${widget.title} 소리 크기 파형. 아래 구간 선택으로 다시 들을 수 있어요.',
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    onTapDown: !widget.enabled
                        ? null
                        : (details) {
                            final fraction =
                                (details.localPosition.dx /
                                        constraints.maxWidth)
                                    .clamp(0.0, 1.0);
                            final start = math.max(0.0, fraction - .08),
                                end = math.min(1.0, fraction + .08);
                            setState(() => _range = RangeValues(start, end));
                          },
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _LiquidWavePainter(
                          attempt.waveform,
                          _range,
                          widget.cursorMs == null
                              ? null
                              : widget.cursorMs! / duration,
                          Theme.of(context).colorScheme.primary,
                          phones
                              .map(
                                (p) => RangeValues(
                                  p.startMs / duration,
                                  p.endMs / duration,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                '0초 — ${(duration / 1000).toStringAsFixed(1)}초 · 원본 시간 / 동일 진폭 눈금',
              ),
              RangeSlider(
                values: _range,
                min: 0,
                max: 1,
                labels: RangeLabels(
                  '${(_range.start * duration / 1000).toStringAsFixed(2)}초',
                  '${(_range.end * duration / 1000).toStringAsFixed(2)}초',
                ),
                onChanged: widget.enabled
                    ? (v) {
                        if ((v.end - v.start) * duration >= 30) {
                          setState(() => _range = v);
                        }
                      }
                    : null,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: widget.enabled
                        ? () => widget.onPlay(attempt, 0, duration)
                        : null,
                    child: const Text('전체 듣기'),
                  ),
                  FilledButton.tonal(
                    onPressed: widget.enabled
                        ? () => widget.onPlay(
                            attempt,
                            (_range.start * duration).floor(),
                            (_range.end * duration).floor(),
                          )
                        : null,
                    child: Text(
                      '선택 구간 듣기 · ${(_range.start * duration / 1000).toStringAsFixed(1)}–${(_range.end * duration / 1000).toStringAsFixed(1)}초',
                    ),
                  ),
                  TextButton(
                    onPressed: widget.enabled
                        ? () {
                            select(0, math.max(1, duration ~/ 2));
                            widget.onPlay(
                              attempt,
                              0,
                              math.max(1, duration ~/ 2),
                            );
                          }
                        : null,
                    child: const Text('앞 시간 구간 듣기'),
                  ),
                  TextButton(
                    onPressed: widget.enabled
                        ? () {
                            select(duration ~/ 2, duration);
                            widget.onPlay(attempt, duration ~/ 2, duration);
                          }
                        : null,
                    child: const Text('뒤 시간 구간 듣기'),
                  ),
                ],
              ),
              const Text('앞·뒤는 녹음 시간의 절반씩이에요. 실제 반복 횟수나 발음 향상을 판정한 결과가 아니에요.'),
            ] else
              const Text('이 기록에는 파형·시간 정보가 없어요.'),
            if (phones.isNotEmpty) ...[
              const Text('ㄹ 정렬 구간 · 눌러서 앞뒤 문맥과 함께 듣기'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < phones.length; i++)
                    ActionChip(
                      label: Text(
                        '구간 ${i + 1} · ${phones[i].startMs}–${phones[i].endMs}ms${attempt.analysis.hasReliableScore && phones[i].confidence >= .55 && phones[i].practiceScore != null ? ' · ${phones[i].practiceScore}점' : ''}',
                      ),
                      onPressed: widget.enabled
                          ? () {
                              final start = math.max(
                                    0,
                                    phones[i].startMs - 150,
                                  ),
                                  end = math.min(
                                    duration,
                                    phones[i].endMs + 200,
                                  );
                              select(start, end);
                              widget.onPlay(attempt, start, end);
                            }
                          : null,
                    ),
                ],
              ),
              const Text('정렬은 목표 소리의 추정 위치예요. 올바른 발음이나 실제 반복 개수를 보장하지 않아요.'),
            ] else
              const Text('자동 ㄹ 구간은 서버 분석 후 표시돼요. 지금은 파형에서 직접 구간을 골라 들을 수 있어요.'),
          ],
        ),
      ),
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  _LiquidWavePainter(
    this.values,
    this.selection,
    this.cursor,
    this.color,
    this.phones,
  );
  final List<double> values;
  final RangeValues selection;
  final double? cursor;
  final Color color;
  final List<RangeValues> phones;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTRB(
        selection.start * size.width,
        0,
        selection.end * size.width,
        size.height,
      ),
      Paint()..color = color.withValues(alpha: .12),
    );
    for (final range in phones) {
      canvas.drawRect(
        Rect.fromLTRB(
          range.start * size.width,
          0,
          range.end * size.width,
          size.height,
        ),
        Paint()..color = Colors.orange.withValues(alpha: .22),
      );
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final mid = size.height / 2;
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()..color = color.withValues(alpha: .3),
    );
    final bins = math.min(values.length, size.width.floor());
    for (var i = 0; i < bins; i++) {
      var peak = 0.0;
      for (
        var j = i * values.length ~/ bins;
        j < (i + 1) * values.length ~/ bins;
        j++
      ) {
        if (values[j].isFinite) {
          peak = math.max(peak, values[j].abs().clamp(0, 1));
        }
      }
      final x = (i + .5) * size.width / bins;
      canvas.drawLine(
        Offset(x, mid - peak * mid),
        Offset(x, mid + peak * mid),
        paint,
      );
    }
    if (cursor != null) {
      canvas.drawLine(
        Offset(cursor! * size.width, 0),
        Offset(cursor! * size.width, size.height),
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter old) => true;
}
