import 'package:flutter/material.dart';
import '../view/rehab_ui.dart';

enum ComfortContext {
  general,
  articulation,
  sentences,
  everyday,
  voice,
  oral,
  mpt,
  game,
}

String comfortTitle(ComfortContext kind, bool en) => switch (kind) {
  ComfortContext.general => en ? 'Before speaking' : '말하기 전',
  ComfortContext.articulation => en ? 'Sounds and words' : '자음·단어 연습',
  ComfortContext.sentences => en ? 'Reading a sentence' : '문장 읽기',
  ComfortContext.everyday => en ? 'Everyday conversation' : '일상 대화',
  ComfortContext.voice => en ? 'Voice practice' : '발성 연습',
  ComfortContext.oral => en ? 'Oral and breathing practice' : '구강·호흡 연습',
  ComfortContext.mpt => en ? 'MPT measurement' : 'MPT 측정',
  ComfortContext.game => en ? 'Voice games' : '말하기 게임',
};

List<String> comfortSteps(ComfortContext kind, bool en) => switch (kind) {
  ComfortContext.general =>
    en
        ? [
            'Sit comfortably and let your shoulders and hands soften.',
            'Take a few natural breaths. Do not force a deep breath or hold it.',
            'Try a short phrase when ready. You can skip this preparation.',
          ]
        : [
            '편한 자세에서 어깨와 손의 불필요한 힘을 놓아요.',
            '억지로 깊게 들이마시거나 참지 말고 편하게 몇 번 숨 쉬어요.',
            '준비되면 짧은 말부터 해요. 준비 과정은 건너뛰어도 돼요.',
          ],
  ComfortContext.articulation =>
    en
        ? [
            'Try one sound or one word at a time.',
            'Do not push your jaw or tongue harder to get a score.',
            'Rest between attempts. One recording is enough today.',
          ]
        : [
            '한 소리나 한 단어부터 편하게 시작해요.',
            '점수를 위해 턱이나 혀에 힘을 더 주지 않아도 돼요.',
            '시도 사이에 쉬어요. 오늘은 한 번 녹음해도 충분해요.',
          ],
  ComfortContext.sentences =>
    en
        ? [
            'Read silently first and choose a comfortable place to pause.',
            'Say one meaningful phrase, then breathe when you need to.',
            'Listen back only when ready. You can hide the graph or feedback.',
          ]
        : [
            '먼저 눈으로 읽고 편하게 쉴 곳을 정해요.',
            '뜻이 이어지는 짧은 구절부터 말하고 필요하면 숨 쉬어요.',
            '준비됐을 때 녹음을 들어요. 파형이나 피드백은 숨겨도 돼요.',
          ],
  ComfortContext.everyday =>
    en
        ? [
            'Choose one message you want to communicate.',
            'Practice alone, then with someone you trust, at your own pace.',
            'Let your listener know you need time. You can use text too.',
          ]
        : [
            '전하고 싶은 내용 한 가지만 정해요.',
            '혼자 해 보고, 원하면 믿는 사람 앞에서 내 속도로 말해요.',
            '상대에게 기다려 달라고 해도 돼요. 글을 함께 써도 괜찮아요.',
          ],
  ComfortContext.voice =>
    en
        ? [
            'Use a comfortable voice; a larger wave is not a better voice.',
            'Release unnecessary effort. Do not press or massage your neck.',
            'Pause if speaking feels strained. Follow your clinician’s individual guidance.',
          ]
        : [
            '편한 목소리를 써요. 큰 파형이 더 좋은 목소리는 아니에요.',
            '불필요한 힘을 놓아요. 목을 누르거나 마사지하지 않아요.',
            '힘들게 느껴지면 쉬고 전문가가 정한 개인별 방법을 따라요.',
          ],
  ComfortContext.oral =>
    en
        ? [
            'Use a comfortable range of motion and do not force a stretch.',
            'Keep breathing naturally; do not add breath-holding.',
            'Skip an uncomfortable exercise and discuss it with your clinician.',
          ]
        : [
            '편한 범위에서 움직이고 억지로 늘리지 않아요.',
            '자연스럽게 호흡하고 별도로 숨 참기를 더하지 않아요.',
            '불편한 동작은 건너뛰고 전문가와 상의해요.',
          ],
  ComfortContext.mpt =>
    en
        ? [
            'Settle comfortably before the observer starts the trial.',
            'Follow the measurement instructions; do not chase your previous time.',
            'Rest between trials. Stop if dizzy, breathless or in pain.',
          ]
        : [
            '관찰자가 측정을 시작하기 전에 편한 자세를 잡아요.',
            '측정 안내를 따르되 이전 기록을 억지로 넘기려 하지 않아요.',
            '시도 사이에 충분히 쉬어요. 어지럽거나 아프고 숨차면 멈춰요.',
          ],
  ComfortContext.game =>
    en
        ? [
            'Choose an easy pace. You do not have to win.',
            'Avoid pushing your voice to keep playing.',
            'Pause whenever you need a break.',
          ]
        : [
            '쉬운 속도로 해요. 꼭 이기지 않아도 돼요.',
            '놀이를 이어 가려고 목소리에 힘을 더 주지 않아요.',
            '쉬고 싶으면 언제든 멈춰요.',
          ],
};

class ComfortTrainingScreen extends StatelessWidget {
  const ComfortTrainingScreen({
    super.key,
    this.situation = ComfortContext.general,
  });
  final ComfortContext situation;
  @override
  Widget build(BuildContext context) {
    final en = rehabEnglish(context);
    final kinds = [
      situation,
      ...ComfortContext.values.where((k) => k != situation),
    ];
    return RehabPage(
      title: en ? 'Ease speaking tension' : '긴장 낮추기',
      children: [
        Text(
          en
              ? 'Optional preparation, at your pace. This is not a test.'
              : '내 속도로 선택하는 준비예요. 잘해야 하는 시험이 아니에요.',
        ),
        for (final kind in kinds)
          Card(
            child: ExpansionTile(
              initiallyExpanded: kind == situation,
              title: Text(comfortTitle(kind, en)),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                for (final step in comfortSteps(kind, en))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(step),
                    ),
                  ),
              ],
            ),
          ),
        Text(
          en
              ? 'Stop if dizzy, in pain or short of breath. Persistent vocal strain: ask your clinician or speech-language pathologist. Anxiety that limits daily life: consider professional help such as CBT. These suggestions do not diagnose the cause of tension.'
              : '어지러움·통증·호흡곤란이 있으면 멈추세요. 힘든 발성이 지속되면 의료진·언어재활사와 상의하세요. 불안이 일상을 제한하면 CBT 등 전문적인 도움을 고려하세요. 이 안내는 긴장의 원인을 진단하지 않아요.',
        ),
        const SizedBox(height: 12),
        Text(
          en
              ? 'Based on NHS stress breathing guidance, ASHA dysarthria/voice guidance and NICE CG159. Adapted preparation has not been clinically validated in this app.'
              : 'NHS 스트레스 호흡 안내, ASHA 마비말장애·음성 안내, NICE CG159를 참고했습니다. 앱의 준비 루틴 자체는 임상 검증 전입니다.',
        ),
      ],
    );
  }
}

class ComfortButton extends StatelessWidget {
  const ComfortButton({
    super.key,
    this.situation = ComfortContext.general,
    this.enabled = true,
  });
  final ComfortContext situation;
  final bool enabled;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: rehabEnglish(context) ? 'Ease speaking tension' : '긴장 낮추기',
    icon: const Icon(Icons.spa_outlined),
    onPressed: !enabled
        ? null
        : () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ComfortTrainingScreen(situation: situation),
            ),
          ),
  );
}
