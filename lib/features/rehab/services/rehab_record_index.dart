import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';
import 'package:speech_rehab/features/guided_training/model/guided_training_models.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';
import 'package:speech_rehab/services/practice_history_service.dart';
import 'package:speech_rehab/services/history_service.dart';
import 'package:speech_rehab/services/guided_training/guided_training_history_service.dart';
import 'package:speech_rehab/services/audio_analysis/voice_analysis_repository.dart';
import 'package:speech_rehab/features/consonant_training/services/consonant_training_history_service.dart';
import 'package:speech_rehab/features/chat/provider/chat_provider.dart';
import '../model/rehab_session.dart';
import 'rehab_session_repository.dart';

class IndexedRecording {
  const IndexedRecording({
    required this.id,
    required this.text,
    required this.path,
    required this.date,
    required this.language,
    this.comparable = true,
  });
  final String id, text, path, language;
  final DateTime date;
  final bool comparable;
}

class RehabRecord {
  const RehabRecord({
    required this.id,
    required this.kind,
    required this.title,
    required this.date,
    required this.dateKey,
    required this.status,
    this.recordings = const [],
    this.details = '',
    this.daily,
    this.fatigueBefore,
    this.fatigueAfter,
  });
  final String id, kind, title, dateKey, status, details;
  final DateTime date;
  final List<IndexedRecording> recordings;
  final RehabSession? daily;
  final int? fatigueBefore, fatigueAfter;
}

class RehabRecordIndex {
  RehabRecordIndex({RehabSessionRepository? daily})
    : daily = daily ?? RehabSessionRepository();
  final RehabSessionRepository daily;
  Future<List<RehabRecord>> load() async {
    final results = await Future.wait<Object>([
      daily.load(),
      PracticeHistoryService().loadPractices(),
      ConsonantTrainingHistoryService().load(),
      GuidedTrainingHistoryService().loadAllSessions(),
      VoiceAnalysisRepository().load(),
      HistoryService().loadSessions(),
    ]);
    // Typed adapters keep existing stores as the source of truth.
    final records = <RehabRecord>[];
    for (final session in results[0] as List<RehabSession>) {
      records.add(
        RehabRecord(
          id: 'daily:${session.id}',
          kind: session.feedback['kind'] == 'voiceFlight' ? 'game' : 'daily',
          title: session.title,
          date: session.startedAt,
          dateKey: session.localDate,
          status: session.feedback['kind'] == 'voiceFlight'
              ? 'voicePlay'
              : session.status.name,
          daily: session,
          fatigueBefore: session.fatigueBefore,
          fatigueAfter: session.fatigueAfter,
          recordings: [
            for (final take in session.takes)
              IndexedRecording(
                id: take.id,
                text: take.text,
                path: take.path,
                date: take.createdAt,
                language: session.language,
                comparable:
                    session.tasks
                        .where((t) => t.id == take.taskId)
                        .firstOrNull
                        ?.prompt ==
                    null,
              ),
          ],
        ),
      );
    }
    // The remaining adapters are isolated below so their original models stay unchanged.
    records.addAll(_practice(results[1]));
    records.addAll(_consonants(results[2]));
    records.addAll(_guided(results[3]));
    records.addAll(_voice(results[4]));
    for (final chat in results[5] as List<ChatSession>) {
      final user = chat.messages.where((m) => m.role == ChatRole.user).toList();
      if (user.isEmpty) continue;
      records.add(
        RehabRecord(
          id: 'chat:${chat.id}',
          kind: 'chat',
          title: chat.title,
          date: chat.createdAt,
          dateKey: rehabDate(chat.createdAt.toLocal()),
          status: 'conversation',
          details: user.map((m) => '[${m.inputMethod}] ${m.text}').join('\n'),
        ),
      );
    }
    return uniqueRecords(records);
  }

  static List<RehabRecord> uniqueRecords(Iterable<RehabRecord> records) =>
      {for (final record in records) record.id: record}.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
}

Iterable<RehabRecord> _practice(Object raw) sync* {
  for (final p in raw as List<PracticeSession>) {
    if (!p.isRecordedAttempt) continue;
    yield RehabRecord(
      id: 'practice:${p.id}',
      kind: 'practice',
      title: p.targetText,
      date: p.timestamp,
      dateKey: rehabDate(p.timestamp.toLocal()),
      status: 'attempt',
      fatigueBefore: p.fatigueBefore,
      fatigueAfter: p.fatigueAfter,
      details: '${p.scoreDisplay} · ${p.evaluationVersion}\n${p.feedback}',
      recordings: [
        if (p.audioFilePath.isNotEmpty)
          IndexedRecording(
            id: p.id,
            text: p.targetText,
            path: p.audioFilePath,
            date: p.timestamp,
            language: 'legacy',
            comparable: p.mode != 'freeSpeech',
          ),
      ],
    );
  }
}

Iterable<RehabRecord> _consonants(Object raw) sync* {
  for (final c in raw as List<ConsonantTrainingAttempt>) {
    yield RehabRecord(
      id: 'consonant:${c.id}',
      kind: 'consonant',
      title: c.text,
      date: c.createdAt,
      dateKey: rehabDate(c.createdAt.toLocal()),
      status: 'attempt',
      fatigueBefore: c.fatigue,
      details: '${c.analysis.status.name} · ${c.analysis.modelVersion}',
      recordings: [
        if (c.audioFilePath.isNotEmpty)
          IndexedRecording(
            id: c.id,
            text: c.text,
            path: c.audioFilePath,
            date: c.createdAt,
            language: c.language,
          ),
      ],
    );
  }
}

Iterable<RehabRecord> _guided(Object raw) sync* {
  for (final g in raw as List<GuidedTrainingSession>) {
    yield RehabRecord(
      id: 'guided:${g.id}',
      kind: 'guided',
      title: g.routineName,
      date: g.startedAt,
      dateKey: rehabDate(g.startedAt.toLocal()),
      status: g.completed
          ? 'completed'
          : g.canResume
          ? 'paused'
          : 'partial',
      fatigueBefore: g.fatigueBefore,
      fatigueAfter: g.fatigueAfter,
      details:
          '${g.completedExerciseCount}/${g.exerciseIds.isEmpty ? g.results.length : g.exerciseIds.length}',
    );
  }
}

Iterable<RehabRecord> _voice(Object raw) sync* {
  for (final v in raw as List<VoiceAnalysisSession>) {
    yield RehabRecord(
      id: 'voice:${v.id}',
      kind: 'voice',
      title: v.taskType.name,
      date: v.startedAt,
      dateKey: rehabDate(v.startedAt.toLocal()),
      status: 'measurement',
      details: v.analysisVersion,
      recordings: [
        if (v.audioPath?.isNotEmpty == true)
          IndexedRecording(
            id: v.id,
            text: v.promptId ?? v.taskType.name,
            path: v.audioPath!,
            date: v.startedAt,
            language: 'unknown',
            comparable: false,
          ),
      ],
    );
  }
}
