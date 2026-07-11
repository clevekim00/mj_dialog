import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_rehab/features/exercise/widgets/animated_exercise_avatar.dart';
import 'package:speech_rehab/features/face_exercise/model/face_exercise_step.dart';

class FaceExerciseScreen extends StatefulWidget {
  const FaceExerciseScreen({super.key});

  @override
  State<FaceExerciseScreen> createState() => _FaceExerciseScreenState();
}

class _FaceExerciseScreenState extends State<FaceExerciseScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Timer? _timer;
  int _stepIndex = 0;
  int _remainingSeconds = faceExerciseSteps.first.seconds;
  bool _isPlaying = false;
  bool _stepMode = false;
  double _speed = 1;

  FaceExerciseStep get _step => faceExerciseSteps[_stepIndex];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _startTimer();
      _animationController.repeat(reverse: true);
    } else {
      _timer?.cancel();
      _animationController.stop();
    }
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _stepIndex = 0;
      _remainingSeconds = faceExerciseSteps.first.seconds;
      _isPlaying = false;
    });
    _animationController
      ..reset()
      ..repeat(reverse: true);
  }

  void _nextStep() {
    final nextIndex = (_stepIndex + 1) % faceExerciseSteps.length;
    setState(() {
      _stepIndex = nextIndex;
      _remainingSeconds = faceExerciseSteps[nextIndex].seconds;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: (1000 / _speed).round()), (
      _,
    ) {
      if (!mounted || !_isPlaying) {
        return;
      }
      if (_remainingSeconds > 1) {
        setState(() => _remainingSeconds -= 1);
        return;
      }
      if (_stepMode) {
        setState(() {
          _remainingSeconds = _step.seconds;
          _isPlaying = false;
        });
        _timer?.cancel();
        return;
      }
      _nextStep();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text('얼굴운동'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, _) => AnimatedExerciseAvatar(
                  stepId: _step.id,
                  pulse: _animationController.value,
                  accentColor: Colors.pinkAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildControls(),
            const SizedBox(height: 16),
            _buildStepList(),
            const SizedBox(height: 16),
            const Text(
              'This is a general exercise guide, not medical advice.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.face_retouching_natural, color: Colors.pinkAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _step.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '남은 시간 $_remainingSeconds초 · 속도 ${_speed.toStringAsFixed(1)}x',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _togglePlay,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(_isPlaying ? '일시정지' : '시작'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _restart,
                icon: const Icon(Icons.restart_alt),
                tooltip: '다시 시작',
              ),
              IconButton(
                onPressed: () {
                  _timer?.cancel();
                  setState(() => _isPlaying = false);
                  _nextStep();
                },
                icon: const Icon(Icons.skip_next),
                tooltip: '다음 단계',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('속도', style: TextStyle(color: Colors.white70)),
              Expanded(
                child: Slider(
                  value: _speed,
                  min: 0.5,
                  max: 2,
                  divisions: 3,
                  activeColor: Colors.pinkAccent,
                  label: '${_speed.toStringAsFixed(1)}x',
                  onChanged: (value) {
                    setState(() => _speed = value);
                    if (_isPlaying) {
                      _startTimer();
                    }
                  },
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _stepMode,
            activeThumbColor: Colors.pinkAccent,
            title: const Text('단계별 모드', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              '한 단계가 끝나면 자동으로 멈춥니다.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            onChanged: (value) => setState(() => _stepMode = value),
          ),
        ],
      ),
    );
  }

  Widget _buildStepList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < faceExerciseSteps.length; i++)
          ChoiceChip(
            selected: i == _stepIndex,
            label: Text(faceExerciseSteps[i].title),
            selectedColor: Colors.pinkAccent,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            labelStyle: TextStyle(
              color: i == _stepIndex ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: i == _stepIndex ? Colors.pinkAccent : Colors.white10,
            ),
            onSelected: (_) {
              _timer?.cancel();
              setState(() {
                _stepIndex = i;
                _remainingSeconds = faceExerciseSteps[i].seconds;
                _isPlaying = false;
              });
            },
          ),
      ],
    );
  }
}
