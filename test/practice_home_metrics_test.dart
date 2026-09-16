import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';
import 'package:speech_rehab/features/practice/view/practice_mode_selection_screen.dart';
import 'package:speech_rehab/services/practice_history_service.dart';

class _FixedPractice extends PracticeNotifier {
  _FixedPractice(this.history);
  final List<PracticeSession> history;
  @override
  PracticeProgress build() => PracticeProgress(
    state: PracticeState.idle,
    targetText: '물',
    history: history,
  );
}

PracticeSession _session(
  String id, {
  int? score,
  String method = 'legacy',
  int retries = 0,
  bool recorded = true,
}) => PracticeSession(
  id: id,
  targetText: '대상 문장 $id',
  spokenText: recorded ? '대상 문장' : '',
  audioFilePath: recorded ? '/tmp/$id.m4a' : '',
  score: score,
  evaluationMethod: method,
  evaluationVersion: method == 'textMatch' ? 'text-match-v1' : method,
  feedback: '테스트 기록',
  timestamp: DateTime.now(),
  retryCount: retries,
);

Future<void> _showHome(
  WidgetTester tester,
  List<PracticeSession> history,
) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1000, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [practiceProvider.overrideWith(() => _FixedPractice(history))],
      child: const MaterialApp(home: PracticeModeSelectionScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'legacy or unavailable scores with retries are not new text-match recommendations',
    (tester) async {
      await _showHome(tester, [
        _session('legacy', score: 65, retries: 1),
        _session('unavailable', method: 'unavailable', retries: 1),
      ]);
      expect(find.text('어려웠던 문장 다시 읽기'), findsNothing);
      expect(find.textContaining('null%'), findsNothing);
      expect(find.text('인식 일치 65%'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recordless legacy falling events do not inflate today utterances',
    (tester) async {
      await _showHome(tester, [
        _session('actual', score: 100, method: 'textMatch'),
        _session('fall-1', score: 0, retries: 1, recorded: false),
        _session('fall-2', score: 0, retries: 1, recorded: false),
      ]);
      expect(find.text('오늘 발화 1회'), findsOneWidget);
      expect(find.text('오늘 발화 3회'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a new comparable low text-match score can be reviewed with its method label',
    (tester) async {
      await _showHome(tester, [
        _session('new', score: 45, method: 'textMatch', retries: 1),
      ]);
      expect(find.text('어려웠던 문장 다시 읽기'), findsOneWidget);
      expect(find.text('텍스트 일치도 45%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
