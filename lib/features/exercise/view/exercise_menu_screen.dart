import 'package:flutter/material.dart';

class ExerciseMenuScreen extends StatelessWidget {
  const ExerciseMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text('운동'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          _buildExerciseCard(
            context,
            title: '혀운동',
            subtitle: '혀운동 루틴과 연속 교대운동',
            icon: Icons.self_improvement,
            color: Colors.tealAccent,
            routeName: '/tongue_exercise_menu',
          ),
          const SizedBox(height: 14),
          _buildExerciseCard(
            context,
            title: '얼굴운동',
            subtitle: '입 크게 벌리기, 입술 모으기, 웃기, 턱 좌우, 볼 부풀리기',
            icon: Icons.face_retouching_natural,
            color: Colors.pinkAccent,
            routeName: '/face_exercise',
          ),
          const SizedBox(height: 14),
          _buildExerciseCard(
            context,
            title: '호흡훈련',
            subtitle: '깊은 호흡 준비, 입·입술·혀·볼 움직임을 천천히 따라 하기',
            icon: Icons.air,
            color: Colors.lightBlueAccent,
            routeName: '/breathing_training',
          ),
          const SizedBox(height: 14),
          _buildExerciseCard(
            context,
            title: '발성 훈련 · 음성 도구',
            subtitle: '목소리 높이, 크기, 목표음, 음파와 10초 녹음 분석',
            icon: Icons.multiline_chart,
            color: Colors.blueAccent,
            routeName: '/voice_analysis_menu',
          ),
          const SizedBox(height: 18),
          const Text(
            'This is a general exercise guide, not medical advice.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '발음 전 준비운동',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '혀와 얼굴을 천천히 움직이며 말하기 연습 전 몸을 가볍게 준비합니다.',
            style: TextStyle(color: Colors.white60, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
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
        width: double.infinity,
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
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
