import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';

/// Fixed full-scale amplitude, not a pronunciation score or calibrated SPL.
class PracticeWaveform extends StatelessWidget {
  const PracticeWaveform({
    super.key,
    required this.values,
    required this.durationMs,
    required this.english,
    this.live,
    this.title,
  });
  final List<double> values;
  final int durationMs;
  final bool english;
  final VoiceAnalysisFrame? live;
  final String? title;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title ?? (english ? 'Sound over time' : '소리 크기 흐름'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Semantics(
            label: english
                ? 'Recorded audio amplitude over ${(durationMs / 1000).toStringAsFixed(1)} seconds.'
                : '${(durationMs / 1000).toStringAsFixed(1)}초 동안 녹음된 소리 크기 변화',
            child: SizedBox(
              height: 352,
              child: CustomPaint(
                painter: _EnvelopePainter(
                  List.of(values),
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          Text('0 s  —  ${(durationMs / 1000).toStringAsFixed(1)} s'),
          if (live?.clipping == true)
            Text(
              english
                  ? 'Input is clipping. Check microphone distance.'
                  : '소리가 찌그러질 수 있어요. 마이크 거리를 확인하세요.',
            ),
          if (values.isEmpty)
            Text(
              english
                  ? 'The graph appears when audio arrives.'
                  : '소리가 들어오면 그래프가 나타나요.',
            ),
          Text(
            english
                ? 'Microphone level only. A larger wave does not mean better pronunciation.'
                : '마이크에 들어온 크기예요. 파형이 크다고 발음이 더 좋은 것은 아니에요.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _EnvelopePainter extends CustomPainter {
  _EnvelopePainter(this.values, this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()..color = color.withValues(alpha: .25),
    );
    if (values.isEmpty) return;
    final bins = math.min(values.length, math.max(1, size.width.floor()));
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (var i = 0; i < bins; i++) {
      final start = i * values.length ~/ bins;
      final end = math.max(start + 1, (i + 1) * values.length ~/ bins);
      var peak = 0.0;
      for (var k = start; k < end; k++) {
        if (values[k].isFinite) {
          peak = math.max(peak, values[k].abs().clamp(0, 1));
        }
      }
      final x = (i + .5) * size.width / bins;
      canvas.drawLine(
        Offset(x, mid - peak * mid),
        Offset(x, mid + peak * mid),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter old) => true;
}
