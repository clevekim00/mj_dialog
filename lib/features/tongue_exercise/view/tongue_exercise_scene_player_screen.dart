import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_rehab/features/exercise/widgets/animated_exercise_avatar.dart';
import 'package:speech_rehab/features/tongue_exercise/model/tongue_exercise_step.dart';

class TongueExerciseScenePlayerScreen extends StatefulWidget {
  const TongueExerciseScenePlayerScreen({super.key, required this.step});

  final TongueExerciseStep step;

  @override
  State<TongueExerciseScenePlayerScreen> createState() =>
      _TongueExerciseScenePlayerScreenState();
}

class _TongueExerciseScenePlayerScreenState
    extends State<TongueExerciseScenePlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPlaying = true;
  double _speed = 1;

  TongueExerciseStep get _step => widget.step;
  int get _durationSeconds => _step.seconds;
  int get _remainingSeconds =>
      (_durationSeconds - _elapsedSeconds).clamp(0, _durationSeconds);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: (1000 / _speed).round()), (
      _,
    ) {
      if (!_isPlaying || !mounted) return;
      if (_elapsedSeconds >= _durationSeconds) {
        setState(() {
          _isPlaying = false;
        });
        _pulseController.stop();
        return;
      }
      setState(() {
        _elapsedSeconds += 1;
      });
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _pulseController.repeat();
    } else {
      _pulseController.stop();
    }
  }

  void _restart() {
    setState(() {
      _elapsedSeconds = 0;
      _isPlaying = true;
    });
    _pulseController.repeat();
    _startTimer();
  }

  void _setSpeed(double speed) {
    setState(() {
      _speed = speed;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _durationSeconds == 0
        ? 0.0
        : (_elapsedSeconds / _durationSeconds).clamp(0.0, 1.0);
    final viewport = MediaQuery.sizeOf(context);
    final animationHeight = (viewport.height * 0.42).clamp(260.0, 360.0);

    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: Text(_step.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _buildHeader(progress),
            const SizedBox(height: 14),
            SizedBox(
              height: animationHeight,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return AnimatedExerciseAvatar(
                    stepId: _step.id,
                    pulse: _pulseController.value,
                    accentColor: Colors.tealAccent,
                    showChrome: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildInstructionCard(),
            const SizedBox(height: 14),
            _buildControls(),
            const SizedBox(height: 16),
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.tealAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_step.icon, color: Colors.tealAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _step.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _step.subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCountdown(),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(Colors.tealAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.tealAccent, width: 4),
        color: Colors.black.withValues(alpha: 0.18),
      ),
      child: Text(
        '$_remainingSeconds초',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '운동 안내',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            _step.instruction,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                color: Colors.tealAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _step.tip,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('${_step.repetitions}회 반복'),
              _buildChip(_difficultyLabel(_step.difficulty)),
              _buildChip(_targetAreaLabel(_step.targetArea)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.replay),
                label: const Text('다시 보기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _togglePlay,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(_isPlaying ? '일시정지' : '재생'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Text(
                '속도 조절',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  min: 0.5,
                  max: 1.5,
                  divisions: 4,
                  value: _speed,
                  activeColor: Colors.tealAccent,
                  label: '${_speed.toStringAsFixed(1)}x',
                  onChanged: _setSpeed,
                ),
              ),
              Text(
                '${_speed.toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return const Text(
      '본 콘텐츠는 일반적인 구강운동 안내용이며 의학적 진단이나 치료가 아닙니다. 증상이 있거나 재활 목적이라면 의사 또는 언어재활사와 상담하세요.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
    );
  }

  String _difficultyLabel(TongueExerciseDifficulty difficulty) {
    return switch (difficulty) {
      TongueExerciseDifficulty.easy => '쉬움',
      TongueExerciseDifficulty.normal => '보통',
      TongueExerciseDifficulty.hard => '어려움',
    };
  }

  String _targetAreaLabel(TongueExerciseTargetArea targetArea) {
    return switch (targetArea) {
      TongueExerciseTargetArea.tongueTip => '혀끝',
      TongueExerciseTargetArea.tongueBody => '혀몸통',
      TongueExerciseTargetArea.tongueSide => '혀 측면',
      TongueExerciseTargetArea.jawTongueCoordination => '턱-혀 협응',
    };
  }
}
