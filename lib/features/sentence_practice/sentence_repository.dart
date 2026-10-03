import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

final sentenceRepositoryProvider = FutureProvider<SentenceRepository>(
  (ref) => SentenceRepository.open(),
);

/// UUID-owned audio and transactional metadata; existing stores are untouched.
class SentenceRepository {
  SentenceRepository(this.db, this.root) {
    _schema();
  }
  final Database db;
  final Directory root;
  static Future<SentenceRepository>? _shared;
  static Future<SentenceRepository> open() =>
      _shared ??= _open().catchError((Object e) {
        _shared = null;
        throw e;
      });
  static Future<SentenceRepository> _open() async {
    final root = Directory(
      p.join(
        (await getApplicationSupportDirectory()).path,
        'sentence_practice',
      ),
    );
    await root.create(recursive: true);
    final repo = SentenceRepository(
      sqlite3.open(p.join(root.path, 'history.sqlite')),
      root,
    );
    await repo.recover();
    return repo;
  }

  void _schema() {
    db.execute('PRAGMA foreign_keys=ON');
    db.execute('PRAGMA journal_mode=WAL');
    db.execute('PRAGMA secure_delete=ON');
    db.execute(
      '''CREATE TABLE IF NOT EXISTS sentences(id TEXT PRIMARY KEY, text TEXT NOT NULL, language TEXT NOT NULL, source TEXT NOT NULL, created TEXT NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);
    CREATE TABLE IF NOT EXISTS pairs(id TEXT PRIMARY KEY, sentence_id TEXT NOT NULL REFERENCES sentences(id), created TEXT NOT NULL, tension_before INTEGER, tension_after INTEGER);
    CREATE TABLE IF NOT EXISTS recordings(id TEXT PRIMARY KEY, pair_id TEXT NOT NULL REFERENCES pairs(id), slot INTEGER NOT NULL CHECK(slot IN (0,1)), path TEXT NOT NULL, hash TEXT NOT NULL, duration INTEGER NOT NULL, envelope TEXT NOT NULL, assessment TEXT NOT NULL, UNIQUE(pair_id,slot));
    CREATE TABLE IF NOT EXISTS pending(id TEXT PRIMARY KEY, pair_id TEXT NOT NULL, slot INTEGER NOT NULL, source TEXT NOT NULL, duration INTEGER NOT NULL, envelope TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS cleanup(path TEXT PRIMARY KEY);
    PRAGMA user_version=1;''',
    );
  }

  T transaction<T>(T Function() action) {
    db.execute('BEGIN IMMEDIATE');
    try {
      final value = action();
      db.execute('COMMIT');
      return value;
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  List<Map<String, dynamic>> sentences() => db
      .select(
        'SELECT s.*, (SELECT count(*) FROM pairs p WHERE p.sentence_id=s.id) AS count FROM sentences s WHERE deleted=0 ORDER BY created DESC',
      )
      .map((r) => Map<String, dynamic>.from(r))
      .toList();
  List<Map<String, dynamic>> pairs(String id) => db
      .select('SELECT * FROM pairs WHERE sentence_id=? ORDER BY created DESC', [
        id,
      ])
      .map((r) => Map<String, dynamic>.from(r))
      .toList();
  List<Map<String, dynamic>> recordings(String pair) => db
      .select('SELECT * FROM recordings WHERE pair_id=? ORDER BY slot', [pair])
      .map((r) => Map<String, dynamic>.from(r))
      .toList();
  String addSentence(String text, String language, {String source = 'text'}) {
    if (text.trim().isEmpty || !{'ko-KR', 'en-US'}.contains(language)) {
      throw ArgumentError('Invalid sentence');
    }
    final id = const Uuid().v4();
    db.execute(
      'INSERT INTO sentences(id,text,language,source,created) VALUES(?,?,?,?,?)',
      [id, text.trim(), language, source, DateTime.now().toIso8601String()],
    );
    return id;
  }

  /// A sentence is an immutable revision. Editing creates a new library entry.
  String startPair(String sentence, {int? tension}) {
    if (db.select('SELECT id FROM sentences WHERE id=? AND deleted=0', [
      sentence,
    ]).isEmpty) {
      throw StateError('Deleted sentence');
    }
    final id = const Uuid().v4();
    db.execute(
      'INSERT INTO pairs(id,sentence_id,created,tension_before) VALUES(?,?,?,?)',
      [id, sentence, DateTime.now().toIso8601String(), tension],
    );
    return id;
  }

  void tensionAfter(String pair, int? value) =>
      db.execute('UPDATE pairs SET tension_after=? WHERE id=?', [value, pair]);
  Future<void> saveRecording(
    String pair,
    int slot,
    String source,
    int duration,
    List<double> envelope,
  ) async {
    if (slot < 0 || slot > 1 || duration <= 0) {
      throw ArgumentError('Invalid recording');
    }
    final id = const Uuid().v4();
    transaction(() {
      if (db.select('SELECT id FROM recordings WHERE pair_id=? AND slot=?', [
            pair,
            slot,
          ]).isNotEmpty ||
          db.select('SELECT id FROM pending WHERE pair_id=?', [
            pair,
          ]).isNotEmpty) {
        throw StateError('Slot occupied');
      }
      db.execute('INSERT INTO pending VALUES(?,?,?,?,?,?)', [
        id,
        pair,
        slot,
        source,
        duration,
        jsonEncode(envelope),
      ]);
    });
    await _finishPending(id);
  }

  Future<void> _finishPending(String id) async {
    final rows = db.select('SELECT * FROM pending WHERE id=?', [id]);
    if (rows.isEmpty) return;
    final row = rows.single;
    final target = File(p.join(root.path, '$id.wav'));
    final active = db.select(
      'SELECT p.id FROM pairs p JOIN sentences s ON s.id=p.sentence_id WHERE p.id=? AND s.deleted=0',
      [row['pair_id']],
    );
    if (active.isEmpty) {
      if (await target.exists()) await target.delete();
      db.execute('DELETE FROM pending WHERE id=?', [id]);
      return;
    }
    if (!await target.exists()) {
      final temp = File('${target.path}.tmp');
      await File(row['source'] as String).copy(temp.path);
      await temp.rename(target.path);
    }
    final hash = sha256.convert(await target.readAsBytes()).toString();
    transaction(() {
      db.execute('INSERT OR IGNORE INTO recordings VALUES(?,?,?,?,?,?,?,?)', [
        id,
        row['pair_id'],
        row['slot'],
        '$id.wav',
        hash,
        row['duration'],
        row['envelope'],
        jsonEncode({'id': const Uuid().v4(), 'status': 'notRequested'}),
      ]);
      db.execute('INSERT OR IGNORE INTO cleanup VALUES(?)', [row['source']]);
      db.execute('DELETE FROM pending WHERE id=?', [id]);
    });
    await _cleanup();
  }

  Future<void> _cleanup() async {
    for (final row in db.select('SELECT path FROM cleanup')) {
      try {
        final file = File(row['path'] as String);
        if (await file.exists()) await file.delete();
        db.execute('DELETE FROM cleanup WHERE path=?', [file.path]);
      } on FileSystemException {
        /* Retry on the next open. */
      }
    }
  }

  Future<void> recover() async {
    for (final row in db.select('SELECT id FROM pending')) {
      try {
        await _finishPending(row['id'] as String);
      } on FileSystemException {
        // Preserve the journal for retry without blocking unrelated history.
      }
    }
    for (final row in db.select('SELECT id FROM sentences WHERE deleted=1')) {
      try {
        await deleteSentence(row['id'] as String);
      } on FileSystemException {
        // The hidden tombstone remains available for cleanup on next open.
      }
    }
    await _cleanup();
  }

  String audioPath(Map<String, dynamic> recording) =>
      p.join(root.path, recording['path'] as String);
  void assessment(String id, Map<String, dynamic> value) {
    db.execute(
      'UPDATE recordings SET assessment=? WHERE id=? AND pair_id IN (SELECT p.id FROM pairs p JOIN sentences s ON s.id=p.sentence_id WHERE s.deleted=0)',
      [jsonEncode(value), id],
    );
  }

  Future<void> deleteSentence(String id) async {
    db.execute("UPDATE sentences SET deleted=1, text='' WHERE id=?", [id]);
    for (final row in db.select(
      'SELECT id, source FROM pending WHERE pair_id IN (SELECT id FROM pairs WHERE sentence_id=?)',
      [id],
    )) {
      db.execute('INSERT OR IGNORE INTO cleanup VALUES(?)', [row['source']]);
      db.execute('INSERT OR IGNORE INTO cleanup VALUES(?)', [
        p.join(root.path, "${row['id']}.wav"),
      ]);
      db.execute('INSERT OR IGNORE INTO cleanup VALUES(?)', [
        p.join(root.path, "${row['id']}.wav.tmp"),
      ]);
      db.execute('DELETE FROM pending WHERE id=?', [row['id']]);
    }
    await _cleanup();
    for (final pair in pairs(id)) {
      for (final rec in recordings(pair['id'] as String)) {
        final f = File(audioPath(rec));
        if (await f.exists()) await f.delete();
      }
    }
    // Keep the tombstone so late network responses cannot reattach results.
    transaction(() {
      db.execute(
        'DELETE FROM recordings WHERE pair_id IN (SELECT id FROM pairs WHERE sentence_id=?)',
        [id],
      );
      db.execute('DELETE FROM pairs WHERE sentence_id=?', [id]);
    });
  }
}
