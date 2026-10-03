import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:speech_rehab/features/sentence_practice/sentence_repository.dart';

void main() {
  late Directory root;
  late SentenceRepository repo;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('sentence_test');
    repo = SentenceRepository(sqlite3.open('${root.path}/test.sqlite'), root);
  });
  tearDown(() async {
    repo.db.close();
    await root.delete(recursive: true);
  });
  Future<String> audio(String name) async {
    final f = File('${root.path}/$name.source');
    await f.writeAsBytes(List.filled(640, 1));
    return f.path;
  }

  test('pairs persist with independent assessments', () async {
    final sentence = repo.addSentence('물을 주세요', 'ko-KR');
    final pair = repo.startPair(sentence);
    await repo.saveRecording(pair, 0, await audio('a'), 20, [.1, .2]);
    await repo.saveRecording(pair, 1, await audio('b'), 20, [.2, .3]);
    final takes = repo.recordings(pair);
    expect(takes.map((t) => t['slot']), [0, 1]);
    final a =
        jsonDecode(takes[0]['assessment'] as String) as Map<String, dynamic>;
    final b =
        jsonDecode(takes[1]['assessment'] as String) as Map<String, dynamic>;
    expect(a['id'], isNot(b['id']));
    repo.assessment(takes[0]['id'] as String, {
      ...a,
      'status': 'completed',
      'transcript': '물을 주세요',
    });
    repo.db.close();
    repo = SentenceRepository(sqlite3.open('${root.path}/test.sqlite'), root);
    expect(repo.recordings(pair).length, 2);
    expect(
      jsonDecode(repo.recordings(pair)[1]['assessment'] as String)['status'],
      'notRequested',
    );
    expect(await File(repo.audioPath(takes[0])).exists(), true);
  });
  test('occupied slots never overwrite', () async {
    final s = repo.addSentence('Hello', 'en-US'), p = repo.startPair(s);
    await repo.saveRecording(p, 0, await audio('a'), 20, [.1]);
    final previous = repo.recordings(p).single;
    await expectLater(
      repo.saveRecording(p, 0, await audio('b'), 20, [.2]),
      throwsStateError,
    );
    expect(repo.startPair(s), isNot(p));
    expect(repo.recordings(p).single['hash'], previous['hash']);
  });
  test('failed save is recovered without duplicate', () async {
    final s = repo.addSentence('연습', 'ko-KR'),
        p = repo.startPair(s),
        missing = '${root.path}/missing.source';
    await expectLater(
      repo.saveRecording(p, 0, missing, 20, [.1]),
      throwsA(isA<FileSystemException>()),
    );
    expect(repo.recordings(p), isEmpty);
    await File(missing).writeAsBytes([1, 2, 3, 4]);
    await repo.recover();
    await repo.recover();
    expect(repo.recordings(p).length, 1);
    expect(repo.db.select('SELECT * FROM pending'), isEmpty);
  });
  test('unrecoverable audio does not block unrelated history', () async {
    final s = repo.addSentence('Hello', 'en-US'), pair = repo.startPair(s);
    await expectLater(
      repo.saveRecording(pair, 0, '${root.path}/missing', 20, [.1]),
      throwsA(isA<FileSystemException>()),
    );
    await repo.recover();
    expect(repo.sentences().single['id'], s);
    expect(repo.db.select('SELECT * FROM pending'), hasLength(1));
  });
  test('deletion blocks late results', () async {
    final s = repo.addSentence('연습', 'ko-KR'), p = repo.startPair(s);
    await repo.saveRecording(p, 0, await audio('a'), 20, [.1]);
    final r = repo.recordings(p).single;
    await repo.deleteSentence(s);
    repo.assessment(r['id'] as String, {'status': 'completed'});
    expect(repo.sentences(), isEmpty);
    expect(repo.recordings(p), isEmpty);
    expect(await File(repo.audioPath(r)).exists(), false);
    expect(() => repo.startPair(s), throwsStateError);
  });
  test('batch insertion is atomic', () {
    expect(() => repo.addSentence('', 'ko-KR'), throwsArgumentError);
    expect(
      () => repo.transaction(() {
        repo.addSentence('hello', 'en-US');
        repo.addSentence('', 'en-US');
      }),
      throwsArgumentError,
    );
    expect(repo.sentences(), isEmpty);
  });
}
