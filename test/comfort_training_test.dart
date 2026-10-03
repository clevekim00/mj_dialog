import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/rehab/comfort/comfort_training.dart';

void main() {
  test('all situations have bilingual instructions', () {
    for (final kind in ComfortContext.values) {
      expect(comfortSteps(kind, false).length, 3);
      expect(comfortSteps(kind, true).length, 3);
    }
    expect(comfortSteps(ComfortContext.mpt, false).join(), contains('기록을 억지로'));
    expect(
      comfortSteps(ComfortContext.sentences, false).join(),
      contains('쉴 곳'),
    );
  });
  testWidgets('context opens directly without mandatory timer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ComfortTrainingScreen(situation: ComfortContext.sentences),
      ),
    );
    expect(find.text('긴장 낮추기'), findsOneWidget);
    expect(
      find.text(comfortSteps(ComfortContext.sentences, false).first),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
