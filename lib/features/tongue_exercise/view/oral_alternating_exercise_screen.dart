import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_rehab/features/exercise/widgets/animated_exercise_avatar.dart';
import 'package:speech_rehab/features/tongue_exercise/model/oral_alternating_step.dart';

class OralAlternatingExerciseScreen extends StatefulWidget {
  const OralAlternatingExerciseScreen({super.key});

  @override
  State<OralAlternatingExerciseScreen> createState() =>
      _OralAlternatingExerciseScreenState();
}

class _OralAlternatingExerciseScreenState
    extends State<OralAlternatingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Timer? _timer;
  int _stepIndex = 0;
  int _remainingSeconds = oralAlternatingSteps.first.seconds;
  bool _isPlaying = false;
  bool _stepMode = false;
  bool _loopMode = true;
  bool _muted = false;
  double _speed = 1;

  OralAlternatingStep get _step => oralAlternatingSteps[_stepIndex];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
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
      _announcePronunciation();
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
      _remainingSeconds = oralAlternatingSteps.first.seconds;
      _isPlaying = false;
    });
    _animationController
      ..reset()
      ..repeat(reverse: true);
  }

  void _nextStep() {
    final isLast = _stepIndex == oralAlternatingSteps.length - 1;
    if (isLast && !_loopMode) {
      setState(() {
        _isPlaying = false;
        _remainingSeconds = 0;
      });
      _timer?.cancel();
      return;
    }
    final nextIndex = (_stepIndex + 1) % oralAlternatingSteps.length;
    setState(() {
      _stepIndex = nextIndex;
      _remainingSeconds = oralAlternatingSteps[nextIndex].seconds;
    });
    _announcePronunciation();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: (1000 / _speed).round()), (
      _,
    ) {
      if (!mounted || !_isPlaying) return;
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

  void _announcePronunciation() {
    if (_muted || _step.pronunciation == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 900),
          content: Text('발음: ${_step.pronunciation}'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text('연속 교대운동'),
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
                  shape: _step.shape,
                  pulse: _animationController.value,
                  accentColor: Colors.lightBlueAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildControls(),
            const SizedBox(height: 16),
            _buildStepList(),
            const SizedBox(height: 16),
            const Text(
              '이 콘텐츠는 일반적인 구강운동 안내용이며 의학적 진단이나 치료가 아닙니다. 증상이 있거나 재활 목적이라면 의사 또는 언어재활사와 상담하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.lightBlueAccent.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.record_voice_over_outlined,
            color: Colors.lightBlueAccent,
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
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _step.description,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                if (_step.pronunciation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _step.pronunciation!,
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '남은 시간 $_remainingSeconds초 · 속도 ${_speed.toStringAsFixed(1)}x',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
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
                  label: Text(_isPlaying ? '일시정지' : '재생'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _restart,
                icon: const Icon(Icons.restart_alt),
                tooltip: '처음부터',
              ),
              IconButton(
                onPressed: _announcePronunciation,
                icon: const Icon(Icons.volume_up_outlined),
                tooltip: '발음 다시 보기',
              ),
              IconButton(
                onPressed: () => setState(() => _muted = !_muted),
                icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                tooltip: _muted ? '소리 켜기' : '음소거',
              ),
            ],
          ),
          Slider(
            value: _speed,
            min: 0.5,
            max: 2,
            divisions: 3,
            activeColor: Colors.lightBlueAccent,
            label: '${_speed.toStringAsFixed(1)}x',
            onChanged: (value) {
              setState(() => _speed = value);
              if (_isPlaying) _startTimer();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _stepMode,
            activeThumbColor: Colors.lightBlueAccent,
            title: const Text('단계별 모드', style: TextStyle(color: Colors.white)),
            onChanged: (value) => setState(() => _stepMode = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _loopMode,
            activeThumbColor: Colors.lightBlueAccent,
            title: const Text('반복 모드', style: TextStyle(color: Colors.white)),
            onChanged: (value) => setState(() => _loopMode = value),
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
        for (var i = 0; i < oralAlternatingSteps.length; i++)
          ChoiceChip(
            selected: i == _stepIndex,
            label: Text(oralAlternatingSteps[i].title),
            selectedColor: Colors.lightBlueAccent,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            labelStyle: TextStyle(
              color: i == _stepIndex ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: i == _stepIndex ? Colors.lightBlueAccent : Colors.white10,
            ),
            onSelected: (_) {
              _timer?.cancel();
              setState(() {
                _stepIndex = i;
                _remainingSeconds = oralAlternatingSteps[i].seconds;
                _isPlaying = false;
              });
              _announcePronunciation();
            },
          ),
      ],
    );
  }
}
