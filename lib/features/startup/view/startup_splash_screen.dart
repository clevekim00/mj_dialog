import 'package:flutter/material.dart';

const startupMotivationMessages = [
  '오늘은 한 단어만 또렷해져도 충분합니다.',
  '천천히 말하는 힘도 좋은 말하기입니다.',
  '작은 반복이 내일의 문장을 편하게 만듭니다.',
  '숨을 고르고, 한 문장씩 차분히 시작해요.',
  '완벽한 발음보다 안전한 연습이 먼저입니다.',
  '오늘의 목소리를 어제보다 조금 더 선명하게.',
  '잠깐의 준비가 긴 문장을 더 편하게 만듭니다.',
];

class StartupSplashScreen extends StatelessWidget {
  const StartupSplashScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.tealAccent.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(
                  Icons.record_voice_over_outlined,
                  color: Colors.tealAccent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Speech Rehab',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '오늘의 말하기 연습을 준비합니다',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '오늘의 한마디',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation(
                          Colors.tealAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    '준비 중',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
