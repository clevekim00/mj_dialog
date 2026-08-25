import 'package:flutter/material.dart';
import 'package:speech_rehab/services/training/training_settings_service.dart';

class TrainingSettingsScreen extends StatefulWidget {
  const TrainingSettingsScreen({super.key});

  @override
  State<TrainingSettingsScreen> createState() => _TrainingSettingsScreenState();
}

class _TrainingSettingsScreenState extends State<TrainingSettingsScreen> {
  int _repeatCount = TrainingSettingsService.defaultRepeatCount;

  @override
  void initState() {
    super.initState();
    TrainingSettingsService.loadDefaultRepeatCount().then((value) {
      if (mounted) setState(() => _repeatCount = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('훈련 설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '기본 반복 횟수',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            '각 훈련에서 별도 값을 지정하지 않았을 때 사용하는 횟수입니다.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton.filled(
                onPressed: _repeatCount > 1
                    ? () => _save(_repeatCount - 1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  '$_repeatCount회',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: _repeatCount < 10
                    ? () => _save(_repeatCount + 1)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '자막 예시: ${TrainingSettingsService.renderCaption('천천히 움직이세요. {repeatCount}회 반복하세요.', _repeatCount)}',
            style: const TextStyle(color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  Future<void> _save(int value) async {
    setState(() => _repeatCount = value);
    await TrainingSettingsService.saveDefaultRepeatCount(value);
  }
}
