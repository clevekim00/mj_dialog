import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';
import 'package:speech_rehab/features/voice_analysis/provider/voice_analysis_controller.dart';
import 'package:speech_rehab/services/audio/audio_player_service.dart';
import 'package:speech_rehab/services/audio_analysis/voice_analysis_repository.dart';
import 'package:speech_rehab/services/audio_analysis/wav_file_service.dart';
import 'package:uuid/uuid.dart';

class VoiceAnalysisMenuScreen extends StatelessWidget {
  const VoiceAnalysisMenuScreen({super.key});

  static const _items = <_VoiceMenuItem>[
    _VoiceMenuItem(
      '실시간 목소리 높이',
      '개인 기준 범위에서 높이와 안정성을 확인해요',
      Icons.show_chart,
      '/voice_pitch',
    ),
    _VoiceMenuItem(
      '목표음 따라 내기',
      '기준음을 듣고 편안하게 같은 높이를 내요',
      Icons.music_note,
      '/target_tone',
    ),
    _VoiceMenuItem(
      '목소리 크기',
      '상대 음량과 문장 끝의 크기를 확인해요',
      Icons.graphic_eq,
      '/voice_volume',
    ),
    _VoiceMenuItem(
      '발성 음파 분석',
      '파형과 주파수 분포를 참고용으로 살펴봐요',
      Icons.multiline_chart,
      '/voice_spectrogram',
    ),
    _VoiceMenuItem(
      '한국어 발음 균형 문장',
      '여러 자음과 모음을 포함한 문장을 읽어요',
      Icons.record_voice_over,
      '/balanced_sentences',
    ),
    _VoiceMenuItem(
      '10초 즉시 녹음',
      '최근 목소리를 바로 듣고 다시 시도해요',
      Icons.replay_10,
      '/quick_voice_recording',
    ),
    _VoiceMenuItem(
      '발성 분석 결과',
      '최근 측정값과 신뢰도를 확인해요',
      Icons.analytics_outlined,
      '/voice_analysis_result',
    ),
    _VoiceMenuItem(
      '나의 기준 음성',
      '선택한 기준 기록을 모아 비교해요',
      Icons.bookmark_outline,
      '/voice_bank',
    ),
    _VoiceMenuItem(
      '발성 분석 기록',
      '날짜와 훈련 종류별 기록을 확인해요',
      Icons.history,
      '/voice_analysis_history',
    ),
    _VoiceMenuItem(
      '마이크·소음 점검',
      '분석 전 입력과 주변 소음을 점검해요',
      Icons.mic_external_on_outlined,
      '/microphone_check',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('발성 훈련 · 음성 도구')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SafetyCard(),
          const SizedBox(height: 18),
          for (final item in _items)
            Card(
              child: ListTile(
                minTileHeight: 76,
                leading: Icon(item.icon, color: Colors.lightBlueAccent),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, item.route),
              ),
            ),
        ],
      ),
    );
  }
}

class PitchTrainingScreen extends StatelessWidget {
  const PitchTrainingScreen({super.key});
  @override
  Widget build(BuildContext context) => const VoiceLiveAnalysisScreen(
    title: '실시간 목소리 높이',
    instruction: '어깨와 턱의 힘을 빼고 편안한 “아” 소리를 내 보세요.',
    taskType: VoiceAnalysisTaskType.pitch,
    chartMode: VoiceChartMode.pitch,
  );
}

class VolumeTrainingScreen extends StatelessWidget {
  const VolumeTrainingScreen({super.key});
  @override
  Widget build(BuildContext context) => const VoiceLiveAnalysisScreen(
    title: '목소리 크기',
    instruction: '편안한 크기로 말하고 문장 끝까지 일정하게 유지해 보세요.',
    taskType: VoiceAnalysisTaskType.volume,
    chartMode: VoiceChartMode.volume,
  );
}

class SpectrogramTrainingScreen extends StatelessWidget {
  const SpectrogramTrainingScreen({super.key});
  @override
  Widget build(BuildContext context) => const VoiceLiveAnalysisScreen(
    title: '발성 음파 분석',
    instruction: '그래프는 참고용입니다. 모양을 맞추려고 힘주어 소리 내지 마세요.',
    taskType: VoiceAnalysisTaskType.spectrogram,
    chartMode: VoiceChartMode.spectrogram,
  );
}

class QuickRecordingScreen extends StatelessWidget {
  const QuickRecordingScreen({super.key});
  @override
  Widget build(BuildContext context) => const VoiceLiveAnalysisScreen(
    title: '10초 즉시 녹음',
    instruction: '최대 10초 동안 말한 뒤 중지하고 바로 들어보세요.',
    taskType: VoiceAnalysisTaskType.quickRecording,
    chartMode: VoiceChartMode.waveform,
    showPlayback: true,
  );
}

class MicrophoneCheckScreen extends StatelessWidget {
  const MicrophoneCheckScreen({super.key});
  @override
  Widget build(BuildContext context) => const VoiceLiveAnalysisScreen(
    title: '마이크·소음 점검',
    instruction: '먼저 2초간 조용히 있다가 편안한 목소리로 짧게 말해 보세요.',
    taskType: VoiceAnalysisTaskType.volume,
    chartMode: VoiceChartMode.quality,
    saveEnabled: false,
  );
}

class TargetToneScreen extends StatefulWidget {
  const TargetToneScreen({super.key});
  @override
  State<TargetToneScreen> createState() => _TargetToneScreenState();
}

class _TargetToneScreenState extends State<TargetToneScreen> {
  double _target = 180;
  final _wav = const WavFileService();
  final _player = AudioPlayerService();
  bool _playing = false;

  Future<void> _playTone() async {
    setState(() => _playing = true);
    try {
      final path = await _wav.writeTone(frequencyHz: _target);
      await _player.playFile(path);
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VoiceLiveAnalysisScreen(
      title: '목표음 따라 내기',
      instruction: '기준음을 듣고 목에 힘을 주지 않은 채 “아”로 따라 해 보세요.',
      taskType: VoiceAnalysisTaskType.targetTone,
      chartMode: VoiceChartMode.pitch,
      targetPitchHz: _target,
      header: Column(
        children: [
          Text(
            '${_target.round()} Hz',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Slider(
            min: 100,
            max: 300,
            divisions: 40,
            value: _target,
            label: '${_target.round()} Hz',
            onChanged: (value) => setState(() => _target = value),
          ),
          FilledButton.icon(
            onPressed: _playing ? null : _playTone,
            icon: const Icon(Icons.volume_up),
            label: const Text('기준음 듣기'),
          ),
        ],
      ),
    );
  }
}

class BalancedSentenceScreen extends StatefulWidget {
  const BalancedSentenceScreen({super.key});
  @override
  State<BalancedSentenceScreen> createState() => _BalancedSentenceScreenState();
}

class _BalancedSentenceScreenState extends State<BalancedSentenceScreen> {
  static const sentences = [
    '바람 부는 파란 바다에서 작은 배가 천천히 갑니다.',
    '나리와 다람쥐는 맑은 날 공원 길을 걸었습니다.',
    '커다란 기차가 터널을 지나 서울역에 도착합니다.',
    '오늘은 가족에게 또렷하고 편안하게 인사합니다.',
  ];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return VoiceLiveAnalysisScreen(
      key: ValueKey(_index),
      title: '한국어 발음 균형 문장',
      instruction: sentences[_index],
      taskType: VoiceAnalysisTaskType.balancedSentence,
      chartMode: VoiceChartMode.waveform,
      promptId: 'balanced_$_index',
      header: Row(
        children: [
          Expanded(child: Text('문장 ${_index + 1}/${sentences.length}')),
          IconButton(
            tooltip: '이전 문장',
            onPressed: _index == 0 ? null : () => setState(() => _index--),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: '다음 문장',
            onPressed: _index == sentences.length - 1
                ? null
                : () => setState(() => _index++),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

enum VoiceChartMode { pitch, volume, waveform, spectrogram, quality }

class VoiceLiveAnalysisScreen extends StatefulWidget {
  const VoiceLiveAnalysisScreen({
    super.key,
    required this.title,
    required this.instruction,
    required this.taskType,
    required this.chartMode,
    this.header,
    this.targetPitchHz,
    this.promptId,
    this.showPlayback = false,
    this.saveEnabled = true,
  });

  final String title;
  final String instruction;
  final VoiceAnalysisTaskType taskType;
  final VoiceChartMode chartMode;
  final Widget? header;
  final double? targetPitchHz;
  final String? promptId;
  final bool showPlayback;
  final bool saveEnabled;

  @override
  State<VoiceLiveAnalysisScreen> createState() =>
      _VoiceLiveAnalysisScreenState();
}

class _VoiceLiveAnalysisScreenState extends State<VoiceLiveAnalysisScreen> {
  late final VoiceAnalysisController _controller;
  final _repository = VoiceAnalysisRepository();
  final _wav = const WavFileService();
  final _player = AudioPlayerService();
  DateTime? _startedAt;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _controller = VoiceAnalysisController()..addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_controller.status == VoiceAnalysisStatus.listening) {
      await _controller.stop();
    } else {
      _startedAt = DateTime.now();
      _saved = false;
      await _controller.start();
    }
  }

  Future<String?> _writeRecentAudio() async {
    final pcm = _controller.recentPcm();
    if (pcm.isEmpty) return null;
    return _wav.writePcm16(
      pcm,
      fileName: 'voice_recent_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> _playRecent() async {
    final path = await _writeRecentAudio();
    if (path != null) await _player.playFile(path);
  }

  Future<void> _save({bool reference = false}) async {
    final startedAt = _startedAt;
    if (startedAt == null || _controller.frames.isEmpty) return;
    final path = reference ? await _writeRecentAudio() : null;
    final session = VoiceAnalysisSession(
      id: const Uuid().v4(),
      taskType: widget.taskType,
      startedAt: startedAt,
      durationSeconds: _controller.metrics.phonationDurationMs ~/ 1000,
      metrics: _controller.metrics,
      analysisVersion: '1.0.0',
      promptId: widget.promptId,
      audioPath: path,
      isReference: reference,
    );
    await _repository.save(session);
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(reference ? '기준 음성으로 저장했습니다.' : '분석 기록을 저장했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = _controller.latestFrame;
    final listening = _controller.status == VoiceAnalysisStatus.listening;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.header != null) ...[
            widget.header!,
            const SizedBox(height: 16),
          ],
          _InstructionCard(text: widget.instruction),
          const SizedBox(height: 16),
          _AnalysisChart(
            mode: widget.chartMode,
            frames: _controller.frames,
            latest: frame,
            targetPitchHz: widget.targetPitchHz,
          ),
          const SizedBox(height: 14),
          _LiveMetrics(frame: frame, metrics: _controller.metrics),
          if (_controller.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _controller.errorMessage!,
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed:
                  _controller.status == VoiceAnalysisStatus.requestingPermission
                  ? null
                  : _toggle,
              icon: Icon(listening ? Icons.stop : Icons.mic),
              label: Text(listening ? '분석 중지' : '분석 시작'),
            ),
          ),
          if (!listening && _controller.frames.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (widget.showPlayback)
              OutlinedButton.icon(
                onPressed: _playRecent,
                icon: const Icon(Icons.play_arrow),
                label: const Text('최근 10초 듣기'),
              ),
            if (widget.saveEnabled)
              OutlinedButton.icon(
                onPressed: _saved ? null : () => _save(),
                icon: const Icon(Icons.save_outlined),
                label: const Text('분석 기록 저장'),
              ),
            if (widget.saveEnabled)
              TextButton.icon(
                onPressed: () => _save(reference: true),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('기준 음성으로 저장'),
              ),
          ],
          const SizedBox(height: 16),
          const _SafetyCard(),
        ],
      ),
    );
  }
}

class VoiceAnalysisHistoryScreen extends StatefulWidget {
  const VoiceAnalysisHistoryScreen({super.key, this.referencesOnly = false});
  final bool referencesOnly;
  @override
  State<VoiceAnalysisHistoryScreen> createState() =>
      _VoiceAnalysisHistoryScreenState();
}

class _VoiceAnalysisHistoryScreenState
    extends State<VoiceAnalysisHistoryScreen> {
  final _repository = VoiceAnalysisRepository();
  final _player = AudioPlayerService();
  late Future<List<VoiceAnalysisSession>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = _repository.load();

  Future<void> _delete(String id) async {
    await _repository.delete(id);
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.referencesOnly ? '나의 기준 음성' : '발성 분석 기록'),
      ),
      body: FutureBuilder<List<VoiceAnalysisSession>>(
        future: _future,
        builder: (context, snapshot) {
          final values = (snapshot.data ?? const <VoiceAnalysisSession>[])
              .where((value) => !widget.referencesOnly || value.isReference)
              .toList();
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (values.isEmpty) return const Center(child: Text('저장된 기록이 없습니다.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: values.length,
            itemBuilder: (context, index) {
              final session = values[index];
              final pitch = session.metrics.medianPitchHz;
              return Card(
                child: ListTile(
                  title: Text(_taskLabel(session.taskType)),
                  subtitle: Text(
                    '${DateFormat('yyyy.MM.dd HH:mm').format(session.startedAt)} · '
                    '${pitch == null ? '피치 없음' : '${pitch.round()} Hz'} · '
                    '${session.metrics.medianDbfs.toStringAsFixed(1)} dBFS',
                  ),
                  leading: Icon(
                    session.isReference
                        ? Icons.bookmark
                        : Icons.analytics_outlined,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (session.audioPath != null)
                        IconButton(
                          tooltip: '재생',
                          onPressed: () => _player.playFile(session.audioPath!),
                          icon: const Icon(Icons.play_arrow),
                        ),
                      IconButton(
                        tooltip: '삭제',
                        onPressed: () => _delete(session.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class VoiceBankScreen extends StatelessWidget {
  const VoiceBankScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const VoiceAnalysisHistoryScreen(referencesOnly: true);
}

class VoiceAnalysisResultScreen extends StatelessWidget {
  const VoiceAnalysisResultScreen({super.key});
  @override
  Widget build(BuildContext context) => const VoiceAnalysisHistoryScreen();
}

String _taskLabel(VoiceAnalysisTaskType type) => switch (type) {
  VoiceAnalysisTaskType.pitch => '목소리 높이',
  VoiceAnalysisTaskType.targetTone => '목표음 따라 내기',
  VoiceAnalysisTaskType.volume => '목소리 크기',
  VoiceAnalysisTaskType.spectrogram => '발성 음파 분석',
  VoiceAnalysisTaskType.balancedSentence => '발음 균형 문장',
  VoiceAnalysisTaskType.quickRecording => '10초 즉시 녹음',
};

class _AnalysisChart extends StatelessWidget {
  const _AnalysisChart({
    required this.mode,
    required this.frames,
    required this.latest,
    this.targetPitchHz,
  });
  final VoiceChartMode mode;
  final List<VoiceAnalysisFrame> frames;
  final VoiceAnalysisFrame? latest;
  final double? targetPitchHz;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(18),
      ),
      child: CustomPaint(
        painter: _VoiceChartPainter(
          mode: mode,
          frames: frames,
          latest: latest,
          targetPitchHz: targetPitchHz,
        ),
        child: frames.isEmpty
            ? const Center(child: Text('분석을 시작하면 그래프가 표시됩니다.'))
            : null,
      ),
    );
  }
}

class _VoiceChartPainter extends CustomPainter {
  _VoiceChartPainter({
    required this.mode,
    required this.frames,
    required this.latest,
    this.targetPitchHz,
  });
  final VoiceChartMode mode;
  final List<VoiceAnalysisFrame> frames;
  final VoiceAnalysisFrame? latest;
  final double? targetPitchHz;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        grid,
      );
    }
    if (mode == VoiceChartMode.spectrogram) {
      _paintSpectrum(canvas, size);
    } else if (mode == VoiceChartMode.waveform) {
      _paintWaveform(canvas, size);
    } else {
      _paintTimeline(canvas, size);
    }
  }

  void _paintTimeline(Canvas canvas, Size size) {
    final values = frames.length > 100
        ? frames.sublist(frames.length - 100)
        : frames;
    if (values.length < 2) return;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = index * size.width / (values.length - 1);
      final value = switch (mode) {
        VoiceChartMode.pitch => values[index].pitchHz ?? 60,
        VoiceChartMode.volume || VoiceChartMode.quality => values[index].dbfs,
        _ => 0,
      };
      final normalized =
          (mode == VoiceChartMode.pitch
                  ? ((value - 60) / 440).clamp(0, 1)
                  : ((value + 80) / 80).clamp(0, 1))
              .toDouble();
      final y = size.height * (1 - normalized);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.lightBlueAccent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    if (targetPitchHz != null && mode == VoiceChartMode.pitch) {
      final y =
          size.height *
          (1 - ((targetPitchHz! - 60) / 440).clamp(0, 1).toDouble());
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.greenAccent
          ..strokeWidth = 2,
      );
    }
  }

  void _paintWaveform(Canvas canvas, Size size) {
    final waveform = latest?.waveform ?? const <double>[];
    if (waveform.length < 2) return;
    final path = Path();
    for (var index = 0; index < waveform.length; index++) {
      final x = index * size.width / (waveform.length - 1);
      final y = size.height / 2 - waveform[index] * size.height * 0.45;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.tealAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintSpectrum(Canvas canvas, Size size) {
    final values = latest?.spectrum ?? const <double>[];
    if (values.isEmpty) return;
    final width = size.width / values.length;
    for (var index = 0; index < values.length; index++) {
      final normalized = ((values[index] + 100) / 100).clamp(0, 1).toDouble();
      final color = Color.lerp(
        Colors.indigo.shade900,
        Colors.orangeAccent,
        normalized,
      )!;
      canvas.drawRect(
        Rect.fromLTWH(
          index * width,
          size.height * (1 - normalized),
          width + 1,
          size.height * normalized,
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceChartPainter oldDelegate) => true;
}

class _LiveMetrics extends StatelessWidget {
  const _LiveMetrics({required this.frame, required this.metrics});
  final VoiceAnalysisFrame? frame;
  final VoiceAnalysisMetrics metrics;
  @override
  Widget build(BuildContext context) {
    final pitch = frame?.hasReliablePitch == true
        ? '${frame!.pitchHz!.round()} Hz'
        : '측정 대기';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetricChip(label: '높이', value: pitch),
        _MetricChip(
          label: '상대 음량',
          value: '${(frame?.dbfs ?? -80).toStringAsFixed(1)} dBFS',
        ),
        _MetricChip(
          label: '유성 비율',
          value: '${(metrics.voicedFrameRatio * 100).round()}%',
        ),
        _MetricChip(
          label: '신뢰도',
          value: '${(metrics.analysisConfidence * 100).round()}%',
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Chip(label: Text('$label  $value'));
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.blueAccent.withValues(alpha: 0.12),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, color: Colors.orangeAccent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '편안한 범위에서 연습하세요. 통증, 목 조임, 어지러움, 호흡 불편 또는 갑작스러운 말 변화가 있으면 즉시 중단하세요. 분석값은 진단이나 치료 효과 판정이 아닙니다.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _VoiceMenuItem {
  const _VoiceMenuItem(this.title, this.subtitle, this.icon, this.route);
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
