import 'package:flutter/material.dart';
import 'package:speech_rehab/features/chat/view/chat_screen.dart';
import 'package:speech_rehab/features/exercise/view/exercise_menu_screen.dart';
import 'package:speech_rehab/features/practice/view/dashboard_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_history_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_mode_selection_screen.dart';
import 'package:speech_rehab/features/practice/view/recording_library_screen.dart';

/// The shared, width-adaptive navigation shell for phone, tablet, desktop,
/// and web. Product destinations stay the same; only their presentation adapts.
class AdaptiveAppShell extends StatefulWidget {
  const AdaptiveAppShell({super.key});

  @override
  State<AdaptiveAppShell> createState() => _AdaptiveAppShellState();
}

class _AdaptiveAppShellState extends State<AdaptiveAppShell> {
  int _selectedIndex = 0;

  static const _destinations = <_AppDestination>[
    _AppDestination('오늘', Icons.today_outlined, Icons.today),
    _AppDestination('훈련', Icons.fitness_center_outlined, Icons.fitness_center),
    _AppDestination('기록', Icons.calendar_month_outlined, Icons.calendar_month),
    _AppDestination('소통', Icons.forum_outlined, Icons.forum),
    _AppDestination('설정', Icons.settings_outlined, Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return _buildCompact();
        return _buildLarge(extended: constraints.maxWidth >= 1200);
      },
    );
  }

  Widget _buildCompact() {
    final compactIndex = _selectedIndex < 3 ? _selectedIndex : 3;
    final body = _selectedIndex < 3
        ? _destinationBody(_selectedIndex)
        : _MoreHub(onSelect: _select);

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: compactIndex,
        onDestinationSelected: (index) => _select(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '오늘',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: '훈련',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '기록',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more),
            label: '더보기',
          ),
        ],
      ),
    );
  }

  Widget _buildLarge({required bool extended}) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: extended,
              minExtendedWidth: 220,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: extended
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.graphic_eq, color: Colors.blueAccent),
                          SizedBox(width: 10),
                          Text(
                            'Speech Rehab',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      )
                    : const Icon(Icons.graphic_eq, color: Colors.blueAccent),
              ),
              destinations: [
                for (final destination in _destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _destinationBody(_selectedIndex)),
          ],
        ),
      ),
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  Widget _destinationBody(int index) {
    return switch (index) {
      0 => const PracticeModeSelectionScreen(),
      1 => const ExerciseMenuScreen(),
      2 => const _RecordsHub(),
      3 => const _CommunicationHub(),
      _ => const _SettingsHub(),
    };
  }
}

class _RecordsHub extends StatelessWidget {
  const _RecordsHub();

  @override
  Widget build(BuildContext context) {
    return _HubPage(
      title: '기록',
      description: '달력과 훈련 결과를 한곳에서 확인하세요.',
      children: [
        _HubCard(
          title: '훈련 달력 · 이력',
          subtitle: '날짜별 훈련 내용과 점수를 확인합니다.',
          icon: Icons.calendar_month,
          color: Colors.blueAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PracticeHistoryScreen()),
          ),
        ),
        _HubCard(
          title: '성과 대시보드',
          subtitle: '주간 활동, 평균 점수와 연습 추이를 봅니다.',
          icon: Icons.insights,
          color: Colors.greenAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          ),
        ),
        _HubCard(
          title: '녹음 보관함',
          subtitle: '저장된 내 목소리를 다시 듣고 비교합니다.',
          icon: Icons.library_music,
          color: Colors.orangeAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecordingLibraryScreen()),
          ),
        ),
        _HubCard(
          title: '음성 분석 기록',
          subtitle: '음높이, 음량, 발성 분석 결과를 확인합니다.',
          icon: Icons.multiline_chart,
          color: Colors.purpleAccent,
          onTap: () => Navigator.pushNamed(context, '/voice_analysis_history'),
        ),
        _HubCard(
          title: '구강·호흡 훈련 기록',
          subtitle: '완료한 루틴, 반복 횟수와 피로도를 확인합니다.',
          icon: Icons.self_improvement,
          color: Colors.tealAccent,
          onTap: () => Navigator.pushNamed(context, '/guided_training/history'),
        ),
      ],
    );
  }
}

class _CommunicationHub extends StatelessWidget {
  const _CommunicationHub();

  @override
  Widget build(BuildContext context) {
    return _HubPage(
      title: '소통',
      description: '생활 속 말하기와 자유 대화를 연습하세요.',
      children: [
        _HubCard(
          title: '자유 대화 시작',
          subtitle: 'AI와 편안하게 대화하며 말하기를 연습합니다.',
          icon: Icons.forum,
          color: Colors.pinkAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          ),
        ),
        _HubCard(
          title: '생활 문장 훈련',
          subtitle: '짧고 실용적인 문장을 소리 내어 연습합니다.',
          icon: Icons.record_voice_over,
          color: Colors.lightBlueAccent,
          onTap: () => Navigator.pushNamed(context, '/practice'),
        ),
      ],
    );
  }
}

class _SettingsHub extends StatelessWidget {
  const _SettingsHub();

  @override
  Widget build(BuildContext context) {
    return _HubPage(
      title: '설정',
      description: '훈련 목표와 사용 환경을 관리하세요.',
      children: [
        _HubCard(
          title: '재활 목표 다시 설정',
          subtitle: '하루 훈련 횟수와 주요 훈련 목표를 조정합니다.',
          icon: Icons.flag_outlined,
          color: Colors.blueAccent,
          onTap: () => Navigator.pushNamed(context, '/onboarding'),
        ),
        _HubCard(
          title: '구강·호흡 훈련 설정',
          subtitle: '반복 횟수, 재생 속도, 자막과 음성 안내를 설정합니다.',
          icon: Icons.repeat,
          color: Colors.orangeAccent,
          onTap: () => Navigator.pushNamed(context, '/training_settings'),
        ),
        _HubCard(
          title: '마이크 점검',
          subtitle: '훈련 전 입력 장치와 주변 소음을 확인합니다.',
          icon: Icons.mic_outlined,
          color: Colors.greenAccent,
          onTap: () => Navigator.pushNamed(context, '/microphone_check'),
        ),
        const _InfoCard(
          title: '접근성 원칙',
          subtitle: '큰 조작 영역, 명확한 글자 안내, 일관된 훈련 버튼을 제공합니다.',
          icon: Icons.accessibility_new,
        ),
      ],
    );
  }
}

class _MoreHub extends StatelessWidget {
  const _MoreHub({required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return _HubPage(
      title: '더보기',
      description: '소통 기능과 앱 설정을 이용하세요.',
      children: [
        _HubCard(
          title: '소통',
          subtitle: '자유 대화와 생활 문장을 연습합니다.',
          icon: Icons.forum_outlined,
          color: Colors.pinkAccent,
          onTap: () => onSelect(3),
        ),
        _HubCard(
          title: '설정',
          subtitle: '훈련 목표, 마이크와 접근성 설정을 확인합니다.',
          icon: Icons.settings_outlined,
          color: Colors.blueGrey,
          onTap: () => onSelect(4),
        ),
      ],
    );
  }
}

class _HubPage extends StatelessWidget {
  const _HubPage({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(title: Text(title), backgroundColor: Colors.transparent),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                description,
                style: const TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ...children.expand(
                (child) => [child, const SizedBox(height: 14)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withValues(alpha: 0.22)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDestination {
  const _AppDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
