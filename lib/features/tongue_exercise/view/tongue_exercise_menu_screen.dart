import 'package:flutter/material.dart';
import 'package:speech_rehab/features/tongue_exercise/model/tongue_exercise_step.dart';
import 'package:speech_rehab/features/tongue_exercise/view/tongue_exercise_scene_player_screen.dart';

class TongueExerciseMenuScreen extends StatefulWidget {
  const TongueExerciseMenuScreen({super.key});

  @override
  State<TongueExerciseMenuScreen> createState() =>
      _TongueExerciseMenuScreenState();
}

class _TongueExerciseMenuScreenState extends State<TongueExerciseMenuScreen> {
  bool _showIndividualExercises = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text('혀운동'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: '혀운동 루틴',
            subtitle: '12개 혀운동을 전체 순서대로 진행',
            icon: Icons.self_improvement,
            color: Colors.tealAccent,
            routeName: '/tongue_exercise',
          ),
          const SizedBox(height: 14),
          _buildCard(
            context,
            title: '연속 교대운동',
            subtitle: '아·이·우, 파·타·카, 라·라·라 발음과 입·혀 움직임',
            icon: Icons.record_voice_over_outlined,
            color: Colors.lightBlueAccent,
            routeName: '/oral_alternating_exercise',
          ),
          const SizedBox(height: 22),
          _buildIndividualExerciseToggle(),
          if (_showIndividualExercises) ...[
            const SizedBox(height: 12),
            ...tongueExerciseSteps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildExerciseSceneCard(context, step),
              ),
            ),
          ],
          if (!_showIndividualExercises)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '필요한 동작만 골라서 짧게 반복하려면 위 버튼을 눌러 목록을 펼쳐주세요.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            '이 콘텐츠는 일반적인 구강운동 안내용이며 의학적 진단이나 치료가 아닙니다. 증상이 있거나 재활 목적이라면 의사 또는 언어재활사와 상담하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualExerciseToggle() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          _showIndividualExercises = !_showIndividualExercises;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.tealAccent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _showIndividualExercises
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: Colors.tealAccent,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '개별 혀운동 실행',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '12개 운동을 하나씩 골라 재생',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              _showIndividualExercises ? '접기' : '펼치기',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.tealAccent.withValues(alpha: 0.12),
            Colors.lightBlueAccent.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 혀운동',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '영상 참고형 운동 구조를 앱 안의 독립 2D 장면으로 나누어 실행합니다.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String routeName,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(context, routeName),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSceneCard(
    BuildContext context,
    TongueExerciseStep step,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TongueExerciseScenePlayerScreen(step: step),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.tealAccent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(step.icon, color: Colors.tealAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${step.seconds}초',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.play_circle_outline, color: Colors.white38),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
