import 'package:flutter/material.dart';
import 'package:speech_rehab/features/chat/view/history_screen.dart';
import 'package:speech_rehab/services/rehab_profile_service.dart';

class RehabOnboardingScreen extends StatefulWidget {
  const RehabOnboardingScreen({super.key});

  @override
  State<RehabOnboardingScreen> createState() => _RehabOnboardingScreenState();
}

class _RehabOnboardingScreenState extends State<RehabOnboardingScreen> {
  String _practiceStage = '3-6개월';
  String _primaryGoal = '또렷하게 말하기';
  int _dailyPracticeMinutes = 5;
  bool _hasCaregiverSupport = false;
  bool _acceptedSafetyNotice = false;

  Future<void> _completeOnboarding() async {
    await RehabProfileService.saveProfile(
      RehabProfile(
        practiceStage: _practiceStage,
        primaryGoal: _primaryGoal,
        dailyPracticeMinutes: _dailyPracticeMinutes,
        hasCaregiverSupport: _hasCaregiverSupport,
        acceptedSafetyNoticeAt: DateTime.now(),
      ),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            const Text(
              '말하기 연습을 안전하게 시작해요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '말하기 연습을 돕는 보조 도구입니다. 필요할 때는 전문가와 상의해 연습 계획을 조정해 주세요.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            _buildSafetyNotice(),
            const SizedBox(height: 24),
            _buildSectionTitle('연습을 이어온 기간'),
            _buildChoiceWrap(
              values: const ['1개월 미만', '1-3개월', '3-6개월', '6개월 이상'],
              selected: _practiceStage,
              onSelected: (value) => setState(() => _practiceStage = value),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('오늘의 주 목표'),
            _buildChoiceWrap(
              values: const ['또렷하게 말하기', '천천히 말하기', '크게 말하기', '숨 조절하기'],
              selected: _primaryGoal,
              onSelected: (value) => setState(() => _primaryGoal = value),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('하루 연습 시간'),
            _buildChoiceWrap(
              values: const ['5분', '10분', '15분'],
              selected: '$_dailyPracticeMinutes분',
              onSelected: (value) {
                setState(() {
                  _dailyPracticeMinutes = int.parse(value.replaceAll('분', ''));
                });
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.blueAccent,
              title: const Text(
                '보호자와 함께 연습합니다',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                '보호자 모드와 공유 리포트 개선에 활용할 수 있습니다.',
                style: TextStyle(color: Colors.white38),
              ),
              value: _hasCaregiverSupport,
              onChanged: (value) =>
                  setState(() => _hasCaregiverSupport = value),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.blueAccent,
              value: _acceptedSafetyNotice,
              onChanged: (value) {
                setState(() => _acceptedSafetyNotice = value ?? false);
              },
              title: const Text(
                '안전 안내를 확인했습니다.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                '말이 갑자기 달라지거나 삼킴 곤란, 사레, 호흡 불편이 있으면 연습을 멈추고 전문가에게 문의하세요.',
                style: TextStyle(color: Colors.white38, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: _acceptedSafetyNotice ? _completeOnboarding : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '말하기 연습 시작하기',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyNotice() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_information_outlined, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                '안전 안내',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '이 앱은 말하기 연습을 돕는 보조 도구이며 전문적인 평가나 도움을 대체하지 않습니다. 삼킴 곤란, 사레, 호흡 불편, 갑작스러운 말 변화가 있으면 연습을 중단하고 전문가에게 문의하세요.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChoiceWrap({
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final isSelected = value == selected;
        return ChoiceChip(
          label: Text(value),
          selected: isSelected,
          selectedColor: Colors.blueAccent,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? Colors.blueAccent : Colors.white12,
          ),
          onSelected: (_) => onSelected(value),
        );
      }).toList(),
    );
  }
}
