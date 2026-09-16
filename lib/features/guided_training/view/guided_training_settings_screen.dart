import 'package:flutter/material.dart';
import 'package:speech_rehab/services/training/training_settings_service.dart';

class GuidedTrainingSettingsScreen extends StatefulWidget {
  const GuidedTrainingSettingsScreen({super.key});

  @override
  State<GuidedTrainingSettingsScreen> createState() =>
      _GuidedTrainingSettingsScreenState();
}

class _GuidedTrainingSettingsScreenState
    extends State<GuidedTrainingSettingsScreen> {
  int _repeatCount = TrainingSettingsService.defaultRepeatCount;
  double _speed = TrainingSettingsService.defaultPlaybackSpeed;
  double _captionScale = 1;
  bool _captions = true;
  bool _tts = true;
  bool _haptics = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait<Object>([
      TrainingSettingsService.loadDefaultRepeatCount(),
      TrainingSettingsService.loadPlaybackSpeed(),
      TrainingSettingsService.loadCaptionScale(),
      TrainingSettingsService.loadCaptionsEnabled(),
      TrainingSettingsService.loadTtsEnabled(),
      TrainingSettingsService.loadHapticsEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      final storedRepeat = values[0] as int;
      _repeatCount = const [5, 10, 20].contains(storedRepeat)
          ? storedRepeat
          : 5;
      _speed = values[1] as double;
      _captionScale = values[2] as double;
      _captions = values[3] as bool;
      _tts = values[4] as bool;
      _haptics = values[5] as bool;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('구강·호흡 훈련 설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('기본 반복 횟수'),
          const Text(
            '운동마다 5·10·20회 중 다시 선택할 수 있습니다.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 5, label: Text('5회')),
              ButtonSegment(value: 10, label: Text('10회')),
              ButtonSegment(value: 20, label: Text('20회')),
            ],
            selected: {_repeatCount},
            onSelectionChanged: (values) async {
              final value = values.first;
              setState(() => _repeatCount = value);
              await TrainingSettingsService.saveDefaultRepeatCount(value);
            },
          ),
          const SizedBox(height: 28),
          _sectionTitle('기본 재생 속도'),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 0.5, label: Text('0.5×')),
              ButtonSegment(value: 0.75, label: Text('0.75×')),
              ButtonSegment(value: 1, label: Text('1×')),
            ],
            selected: {_speed},
            onSelectionChanged: (values) async {
              final value = values.first;
              setState(() => _speed = value);
              await TrainingSettingsService.savePlaybackSpeed(value);
            },
          ),
          const SizedBox(height: 28),
          _sectionTitle('안내와 접근성'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _captions,
            title: const Text('자막 표시'),
            subtitle: const Text('영상 위에 현재 동작을 표시합니다.'),
            onChanged: (value) async {
              setState(() => _captions = value);
              await TrainingSettingsService.saveCaptionsEnabled(value);
            },
          ),
          if (_captions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('자막 크기'),
              subtitle: SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('100%')),
                  ButtonSegment(value: 1.25, label: Text('125%')),
                  ButtonSegment(value: 1.5, label: Text('150%')),
                ],
                selected: {_captionScale},
                onSelectionChanged: (values) async {
                  final value = values.first;
                  setState(() => _captionScale = value);
                  await TrainingSettingsService.saveCaptionScale(value);
                },
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _tts,
            title: const Text('음성 안내'),
            subtitle: const Text('첫 반복 전에 지시문을 읽습니다.'),
            onChanged: (value) async {
              setState(() => _tts = value);
              await TrainingSettingsService.saveTtsEnabled(value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _haptics,
            title: const Text('반복 종료 진동'),
            onChanged: (value) async {
              setState(() => _haptics = value);
              await TrainingSettingsService.saveHapticsEnabled(value);
            },
          ),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '통증, 어지럼, 삼킴 곤란 또는 호흡 불편이 생기면 즉시 중단하세요. 전문가 확인 항목은 일반 설정으로 활성화되지 않습니다.',
                style: TextStyle(height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
    ),
  );
}
