import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../practice/model/practice_mode.dart';
import '../../practice/provider/practice_provider.dart';
import '../../rehab/game/phonation_flight_screen.dart';
import '../../rehab/model/training_launch_spec.dart';
import '../../rehab/view/rehab_ui.dart';

class GameMenuScreen extends ConsumerStatefulWidget {
  const GameMenuScreen({super.key});
  @override
  ConsumerState<GameMenuScreen> createState() => _GameMenuState();
}

class _GameMenuState extends ConsumerState<GameMenuScreen> {
  bool _opening = false;
  Future<void> _openWords() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await ref
          .read(practiceProvider.notifier)
          .prepareLaunch(const TrainingLaunchSpec(mode: PracticeMode.wordGame));
      if (!mounted) return;
      await Navigator.pushNamed(context, '/word_game');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(rehabL10n(context).rehabLoadingError)),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = rehabEnglish(context);
    return RehabPage(
      title: en ? 'Games' : '게임',
      children: [
        Text(
          en ? 'Practise speaking through play.' : '말하기를 놀이로 연습해요.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        if (_opening) const LinearProgressIndicator(),
        IgnorePointer(
          ignoring: _opening,
          child: Column(
            children: [
              RehabCard(
                title: en ? 'Word speaking game' : '단어 말하기 게임',
                subtitle: en
                    ? 'One word at a time. No time limit by default.'
                    : '한 단어씩 말해요. 기본은 시간 제한이 없어요.',
                icon: Icons.text_fields,
                onTap: _openWords,
              ),
              RehabCard(
                title: en ? 'Gentle voice flight' : '목소리로 천천히 날기',
                subtitle: en
                    ? 'Easy voice play · no collisions · not an MPT test'
                    : '아주 쉬운 발성 놀이 · 충돌 없음 · MPT 검사 아님',
                icon: Icons.air,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PhonationFlightScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          en
              ? 'MPT measurement is under Training → Comfortable voice practice.'
              : 'MPT 측정은 훈련 → 편안하게 소리 내기에 있어요.',
        ),
        const SizedBox(height: 12),
        Text(rehabL10n(context).rehabSafety),
      ],
    );
  }
}
