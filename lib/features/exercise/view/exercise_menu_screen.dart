import 'package:flutter/material.dart';
import 'package:speech_rehab/features/rehab/game/phonation_flight_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/consonant_training/view/consonant_training_screens.dart';
import 'package:speech_rehab/features/chat/provider/chat_provider.dart';
import 'package:speech_rehab/features/chat/view/chat_screen.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';
import 'package:speech_rehab/features/rehab/model/training_launch_spec.dart';
import 'package:speech_rehab/features/rehab/model/rehab_session.dart';
import 'package:speech_rehab/features/rehab/view/rehab_setup_screen.dart';
import 'package:speech_rehab/features/rehab/view/rehab_ui.dart';

class ExerciseMenuScreen extends StatelessWidget {
  const ExerciseMenuScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = rehabL10n(context);
    void open(String section) => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _TrainingChoices(section: section),
      ),
    );
    return RehabPage(
      title: l.training,
      children: [
        Text(l.rehabTraining, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        RehabCard(
          title: l.rehabArticulation,
          subtitle: l.rehabArticulationHint,
          icon: Icons.record_voice_over,
          onTap: () => open('articulation'),
        ),
        RehabCard(
          title: l.rehabSentences,
          subtitle: l.rehabSentencesHint,
          icon: Icons.short_text,
          onTap: () => open('sentences'),
        ),
        RehabCard(
          title: l.rehabEveryday,
          subtitle: l.rehabEverydayHint,
          icon: Icons.forum_outlined,
          onTap: () => open('everyday'),
        ),
        RehabCard(
          title: l.rehabVoice,
          subtitle: l.rehabVoiceHint,
          icon: Icons.graphic_eq,
          onTap: () => open('voice'),
        ),
        RehabCard(
          title: l.rehabPacing,
          subtitle: l.rehabPacingHint,
          icon: Icons.pause_circle_outline,
          onTap: () => open('pacing'),
        ),
        const SizedBox(height: 20),
        RehabCard(
          title: l.rehabWarmup,
          subtitle: l.rehabWarmupHint,
          icon: Icons.self_improvement,
          onTap: () => Navigator.pushNamed(context, '/guided_training'),
        ),
        const SizedBox(height: 16),
        Text(l.rehabSafety),
      ],
    );
  }
}

class _TrainingChoices extends ConsumerStatefulWidget {
  const _TrainingChoices({required this.section});
  final String section;
  @override
  ConsumerState<_TrainingChoices> createState() => _ChoicesState();
}

class _ChoicesState extends ConsumerState<_TrainingChoices> {
  bool _opening = false;
  Future<void> _practice(TrainingLaunchSpec spec) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final notifier = ref.read(practiceProvider.notifier);
      await notifier.prepareLaunch(spec);
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        spec.mode == PracticeMode.wordGame ? '/word_game' : '/practice',
      );
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
    final l = rehabL10n(context), en = rehabEnglish(context);
    final section = widget.section;
    final title = switch (section) {
      'articulation' => l.rehabArticulation,
      'sentences' => l.rehabSentences,
      'voice' => l.rehabVoice,
      'pacing' => l.rehabPacing,
      _ => l.rehabEveryday,
    };
    return RehabPage(
      title: title,
      children: [
        if (_opening) const LinearProgressIndicator(),
        if (section == 'articulation') ...[
          RehabCard(
            title: l.rehabConsonants,
            subtitle: l.rehabArticulationHint,
            icon: Icons.record_voice_over,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    const ConsonantTrainingHubScreen(autoResume: true),
              ),
            ),
          ),
          RehabCard(
            title: l.rehabWords,
            subtitle: en
                ? 'One word at a time, without a time limit.'
                : '시간 제한 없이 한 단어씩 반복해요.',
            icon: Icons.text_fields,
            onTap: () => _practice(
              const TrainingLaunchSpec(mode: PracticeMode.wordGame),
            ),
          ),
        ],
        if (section == 'sentences') ...[
          RehabCard(
            title: l.rehabShort,
            subtitle: l.rehabSentencesHint,
            icon: Icons.short_text,
            onTap: () => _practice(
              const TrainingLaunchSpec(mode: PracticeMode.shortSentence),
            ),
          ),
          RehabCard(
            title: l.rehabLong,
            subtitle: l.rehabSentencesHint,
            icon: Icons.notes,
            onTap: () => _practice(
              const TrainingLaunchSpec(mode: PracticeMode.longSentence),
            ),
          ),
        ],
        if (section == 'everyday' || section == 'pacing') ...[
          for (final scenario in rehabScenarios)
            RehabCard(
              title: scenario.title(en),
              subtitle: section == 'pacing'
                  ? l.rehabPacingHint
                  : (en ? scenario.enSentence : scenario.koSentence),
              icon: Icons.forum_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RehabSetupScreen(
                    scenarioId: scenario.id,
                    pacing: section == 'pacing',
                  ),
                ),
              ),
            ),
          if (section == 'everyday')
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: OutlinedButton(
                onPressed: () {
                  ref.read(chatControllerProvider.notifier).createNewSession();
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const ChatScreen()),
                  );
                },
                child: Text(l.rehabFree),
              ),
            ),
        ],
        if (section == 'voice') ...[
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
          RehabCard(
            title: en ? 'Comfortable vowel' : '편안한 모음 소리',
            subtitle: l.rehabVoiceHint,
            icon: Icons.graphic_eq,
            onTap: () => Navigator.pushNamed(context, '/voice_pitch'),
          ),
          RehabCard(
            title: en ? 'Speak through a sentence' : '문장 끝까지 말하기',
            subtitle: l.rehabVoiceHint,
            icon: Icons.record_voice_over,
            onTap: () => Navigator.pushNamed(context, '/voice_volume'),
          ),
          const SizedBox(height: 20),
          ExpansionTile(
            title: Text(l.rehabTools),
            children: [
              ListTile(
                title: Text(l.rehabTools),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, '/voice_analysis_menu'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
