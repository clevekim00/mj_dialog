import 'package:speech_rehab/features/guided_training/view/guided_training_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/exercise/view/exercise_menu_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_mode_selection_screen.dart';
import 'package:speech_rehab/features/rehab/view/rehab_records_screen.dart';
import 'package:speech_rehab/features/rehab/view/rehab_ui.dart';
import 'package:speech_rehab/features/rehab/services/rehab_session_repository.dart';
import 'package:speech_rehab/services/accessibility_settings_service.dart';
import 'package:speech_rehab/services/app_language_service.dart';
import 'package:speech_rehab/services/resources/app_strings.dart';
import 'package:speech_rehab/services/resources/resource_providers.dart';

enum AppDestination { today, training, oralBreathing, records, settings }

class AdaptiveAppShell extends ConsumerStatefulWidget {
  const AdaptiveAppShell({super.key});
  @override
  ConsumerState<AdaptiveAppShell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<AdaptiveAppShell> {
  AppDestination _selected = AppDestination.today;
  // Preserve the active page when only the layout changes at a breakpoint.
  final _contentKey = GlobalKey();
  void _select(int index) {
    if (AppDestination.values[index] == AppDestination.today) {
      ref.invalidate(rehabSessionsProvider);
    }
    setState(() => _selected = AppDestination.values[index]);
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final overrides = ref
        .watch(runtimeStringsProvider(language.languageTag))
        .asData
        ?.value;
    final s = AppStrings(rehabL10n(context), overrides ?? const {});
    final labels = [
      s.today,
      s.training,
      rehabEnglish(context) ? 'Oral & breathing' : '구강·호흡 훈련',
      s.records,
      s.settings,
    ];
    const icons = [
      Icons.today_outlined,
      Icons.record_voice_over,
      Icons.air,
      Icons.history,
      Icons.settings_outlined,
    ];
    final page = KeyedSubtree(
      key: _contentKey,
      child: switch (_selected) {
        AppDestination.today => const PracticeModeSelectionScreen(),
        AppDestination.training => const ExerciseMenuScreen(),
        AppDestination.oralBreathing => const GuidedTrainingHubScreen(),
        AppDestination.records => const RehabRecordsScreen(),
        AppDestination.settings => const _SettingsScreen(),
      },
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
        if (constraints.maxWidth < 600 ||
            (largeText && constraints.maxWidth < 1000)) {
          return Scaffold(
            body: page,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selected.index,
              onDestinationSelected: _select,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
              ],
            ),
          );
        }
        final extended = constraints.maxWidth >= 1200;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  minExtendedWidth: 220,
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  selectedIndex: _selected.index,
                  onDestinationSelected: _select,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Icon(Icons.graphic_eq),
                  ),
                  destinations: [
                    for (var i = 0; i < labels.length; i++)
                      NavigationRailDestination(
                        icon: Icon(icons[i]),
                        label: Text(labels[i]),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsScreen extends ConsumerWidget {
  const _SettingsScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = rehabL10n(context), en = rehabEnglish(context);
    final size = ref.watch(textSizeProvider);
    return RehabPage(
      title: l.settings,
      children: [
        RehabCard(
          title: l.resetGoals,
          subtitle: l.resetGoalsDescription,
          icon: Icons.flag_outlined,
          onTap: () => Navigator.pushNamed(context, '/onboarding'),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.rehabAccessibility,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final factor in [1.0, 1.25, 1.5, 2.0])
                      ChoiceChip(
                        label: Text('${(factor * 100).round()}%'),
                        selected: size == factor,
                        onSelected: (_) async {
                          try {
                            await ref
                                .read(textSizeProvider.notifier)
                                .setSize(factor);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.rehabSaveError)),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        RehabCard(
          title: l.rehabRecordings,
          subtitle: en
              ? 'Review recordings and delete daily practice sessions.'
              : '녹음을 듣고 오늘의 연습 기록을 삭제할 수 있어요.',
          icon: Icons.library_music,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const RehabRecordsScreen()),
          ),
        ),
        RehabCard(
          title: l.rehabManageRecordings,
          subtitle: l.rehabManageHint,
          icon: Icons.folder_outlined,
          onTap: () => Navigator.pushNamed(context, '/recording_library'),
        ),
        RehabCard(
          title: l.oralTrainingSettings,
          subtitle: l.oralTrainingSettingsDescription,
          icon: Icons.repeat,
          onTap: () => Navigator.pushNamed(context, '/training_settings'),
        ),
        RehabCard(
          title: l.microphoneCheck,
          subtitle: l.microphoneCheckDescription,
          icon: Icons.mic_outlined,
          onTap: () => Navigator.pushNamed(context, '/microphone_check'),
        ),
        RehabCard(
          title: l.language,
          subtitle: l.languageDescription,
          icon: Icons.language,
          onTap: () => Navigator.pushNamed(context, '/language_settings'),
        ),
        RehabCard(
          title: l.rehabOffline,
          subtitle: en
              ? 'Manage downloaded language and training content.'
              : '언어와 연습 콘텐츠의 다운로드 상태를 확인해요.',
          icon: Icons.download_for_offline,
          onTap: () => Navigator.pushNamed(context, '/resource_center'),
        ),
        const SizedBox(height: 20),
        Text(l.rehabSafety),
      ],
    );
  }
}
