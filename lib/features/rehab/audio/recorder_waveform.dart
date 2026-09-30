import 'package:flutter/material.dart';
import 'package:speech_rehab/services/audio/audio_recorder_service.dart';
import 'practice_waveform.dart';

/// Reads the existing recorder's meter; never opens a second microphone.
class RecorderWaveform extends StatefulWidget {
  const RecorderWaveform({super.key, required this.recorder});
  final AudioRecorderService recorder;

  @override
  State<RecorderWaveform> createState() => _RecorderWaveformState();
}

class _RecorderWaveformState extends State<RecorderWaveform> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('음파 보기'),
        value: _visible,
        onChanged: (value) => setState(() => _visible = value),
      ),
      if (_visible)
        ValueListenableBuilder<int>(
          valueListenable: widget.recorder.waveformRevision,
          builder: (context, _, child) => PracticeWaveform(
            values: widget.recorder.waveform,
            durationMs: widget.recorder.waveformDurationMs,
            english: false,
            title: '최근 녹음 · 소리 크기 흐름',
          ),
        ),
    ],
  );
}
