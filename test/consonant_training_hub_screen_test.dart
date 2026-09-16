import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/consonant_training/data/consonant_content_repository.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';
import 'package:speech_rehab/features/consonant_training/services/consonant_training_history_service.dart';
import 'package:speech_rehab/features/consonant_training/view/consonant_training_screens.dart';

void main() {
  testWidgets('초성 및 받침 목표를 전환해 표시한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final pack = PronunciationContentPack.fromJson(
      jsonDecode(_packJson) as Map<String, dynamic>,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: ConsonantTrainingHubScreen(
          repository: _FakeRepository(pack),
          historyService: ConsonantTrainingHistoryService(
            preferences: await SharedPreferences.getInstance(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ㄱ'), findsOneWidget);
    expect(find.text('초성 · 문장 1개'), findsOneWidget);
    await tester.tap(find.text('받침'));
    await tester.pumpAndSettle();
    expect(find.text('ㄴ'), findsOneWidget);
    expect(find.text('받침 · 문장 1개'), findsOneWidget);
  });
}

class _FakeRepository extends ConsonantContentRepository {
  _FakeRepository(this.pack)
    : super(supportDirectoryLoader: (() async => Directory.systemTemp));
  final PronunciationContentPack pack;

  @override
  Future<PronunciationContentPack> load() async => pack;
}

const _packJson = '''
{
  "id":"test", "schemaVersion":1, "version":"1.0.0",
  "targets":[
    {"id":"onset_g","grapheme":"ㄱ","phone":"k","position":"onset","description":""},
    {"id":"coda_n","grapheme":"ㄴ","phone":"nf","position":"coda","description":""}
  ],
  "items":[
    {"id":"a","targetId":"onset_g","level":"sentence","text":"가요","pronunciation":[],"difficulty":1,"category":"test","targetOccurrenceCount":1},
    {"id":"b","targetId":"coda_n","level":"sentence","text":"산","pronunciation":[],"difficulty":1,"category":"test","targetOccurrenceCount":1}
  ]
}
''';
