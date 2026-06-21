import 'package:flutter/material.dart';

class TongueExerciseMenuScreen extends StatelessWidget {
  const TongueExerciseMenuScreen({super.key});

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
          _buildCard(
            context,
            title: '혀운동 루틴',
            subtitle: '혀 내밀기, 위아래, 좌우, 입천장 대기',
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
}
