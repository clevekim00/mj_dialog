import 'package:flutter/material.dart';
import 'package:speech_rehab/features/onboarding/view/rehab_onboarding_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_mode_selection_screen.dart';
import 'package:speech_rehab/services/permission_service.dart';
import 'package:speech_rehab/services/rehab_profile_service.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isRequesting = false;

  Future<void> _handleRequest() async {
    setState(() => _isRequesting = true);

    final granted = await PermissionService.requestAllPermissions();

    if (mounted) {
      if (granted) {
        final completedOnboarding =
            await RehabProfileService.hasCompletedOnboarding();
        if (!mounted) {
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => completedOnboarding
                ? const PracticeModeSelectionScreen()
                : const RehabOnboardingScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('발음 녹음과 평가를 위해 권한을 허용해 주세요.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Animated Icon Header
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Icon(
                  Icons.lock_person_outlined,
                  size: 48,
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                '권한 설정 안내',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                '발음을 녹음하고 말한 내용을 확인하려면\n아래 권한이 필요합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white38,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 60),

              // Permission Items
              _PermissionItem(
                icon: Icons.mic_rounded,
                title: '마이크 사용',
                description: '연습 음성을 녹음하고 내 목소리를 다시 듣기 위해 필요합니다.',
                color: Colors.blueAccent,
              ),

              const SizedBox(height: 32),

              _PermissionItem(
                icon: Icons.graphic_eq_rounded,
                title: '음성 인식',
                description: '말한 내용을 문장과 비교해 발음 피드백을 만들기 위해 필요합니다.',
                color: Colors.tealAccent,
              ),

              const Spacer(flex: 3),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _handleRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          '권한 허용하기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: () => PermissionService.openSystemSettings(),
                child: const Text(
                  '이미 거부하셨다면? 시스템 설정으로 이동',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white38,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
