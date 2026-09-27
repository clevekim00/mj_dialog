class RehabTask {
  const RehabTask({
    required this.id,
    required this.title,
    required this.text,
    required this.instruction,
    this.prompt,
  });
  final String id, title, text, instruction;
  final String? prompt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'text': text,
    'instruction': instruction,
    'prompt': prompt,
  };
  factory RehabTask.fromJson(Map<String, dynamic> j) => RehabTask(
    id: j['id'] as String,
    title: j['title'] as String,
    text: j['text'] as String,
    instruction: j['instruction'] as String,
    prompt: j['prompt'] as String?,
  );
}

class RehabTake {
  const RehabTake({
    required this.id,
    required this.taskId,
    required this.text,
    required this.path,
    required this.createdAt,
    required this.seconds,
  });
  final String id, taskId, text, path;
  final DateTime createdAt;
  final int seconds;
  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'text': text,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
    'seconds': seconds,
  };
  factory RehabTake.fromJson(Map<String, dynamic> j) => RehabTake(
    id: j['id'] as String,
    taskId: j['taskId'] as String,
    text: j['text'] as String,
    path: j['path'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    seconds: j['seconds'] as int,
  );
}

enum RehabStatus { inProgress, paused, completed, partial, stopped }

class RehabSession {
  const RehabSession({
    required this.id,
    required this.title,
    required this.language,
    required this.startedAt,
    required this.localDate,
    required this.tasks,
    required this.repetitions,
    required this.fatigueBefore,
    this.fatigueAfter,
    this.taskIndex = 0,
    this.takes = const [],
    this.status = RehabStatus.inProgress,
    this.offsetMinutes = 0,
    this.fatigueChecks = const [],
  });
  final String id, title, language, localDate;
  final DateTime startedAt;
  final List<RehabTask> tasks;
  final List<RehabTake> takes;
  final int repetitions, fatigueBefore, taskIndex, offsetMinutes;
  final int? fatigueAfter;
  final RehabStatus status;
  final List<int> fatigueChecks;
  bool get canResume =>
      taskIndex < tasks.length &&
      (status == RehabStatus.inProgress || status == RehabStatus.paused);
  int countFor(String taskId) => takes.where((t) => t.taskId == taskId).length;
  int get completedTasks =>
      tasks.where((t) => countFor(t.id) >= repetitions).length;
  int get recordingSeconds => takes.fold(0, (a, b) => a + b.seconds);
  RehabSession copyWith({
    int? taskIndex,
    List<RehabTake>? takes,
    RehabStatus? status,
    int? fatigueAfter,
    List<int>? fatigueChecks,
  }) => RehabSession(
    id: id,
    title: title,
    language: language,
    startedAt: startedAt,
    localDate: localDate,
    tasks: tasks,
    repetitions: repetitions,
    fatigueBefore: fatigueBefore,
    fatigueAfter: fatigueAfter ?? this.fatigueAfter,
    offsetMinutes: offsetMinutes,
    taskIndex: taskIndex ?? this.taskIndex,
    takes: takes ?? this.takes,
    status: status ?? this.status,
    fatigueChecks: fatigueChecks ?? this.fatigueChecks,
  );
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'title': title,
    'language': language,
    'startedAt': startedAt.toIso8601String(),
    'localDate': localDate,
    'offsetMinutes': offsetMinutes,
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'repetitions': repetitions,
    'fatigueBefore': fatigueBefore,
    'fatigueAfter': fatigueAfter,
    'taskIndex': taskIndex,
    'takes': takes.map((t) => t.toJson()).toList(),
    'status': status.name,
    'fatigueChecks': fatigueChecks,
  };
  factory RehabSession.fromJson(Map<String, dynamic> j) {
    final tasks = (j['tasks'] as List)
        .map((t) => RehabTask.fromJson(Map<String, dynamic>.from(t as Map)))
        .toList();
    final takes = (j['takes'] as List)
        .map((t) => RehabTake.fromJson(Map<String, dynamic>.from(t as Map)))
        .toList();
    if (tasks.isEmpty) throw const FormatException('Empty practice tasks');
    final unique = {for (final take in takes) take.id: take};
    return RehabSession(
      id: j['id'] as String,
      title: j['title'] as String,
      language: j['language'] as String,
      startedAt: DateTime.parse(j['startedAt'] as String),
      localDate: j['localDate'] as String,
      offsetMinutes: j['offsetMinutes'] as int? ?? 0,
      tasks: tasks,
      repetitions: (j['repetitions'] as int).clamp(1, 5),
      fatigueBefore: (j['fatigueBefore'] as int).clamp(1, 5),
      fatigueAfter: j['fatigueAfter'] as int?,
      taskIndex: (j['taskIndex'] as int).clamp(0, tasks.length),
      takes: unique.values.toList(),
      fatigueChecks: (j['fatigueChecks'] as List? ?? []).cast<int>(),
      status: RehabStatus.values.byName(j['status'] as String),
    );
  }
}

String rehabDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Everyday speech prompts, not a prescribed medical exercise program.
class RehabScenario {
  const RehabScenario(
    this.id,
    this.koTitle,
    this.enTitle,
    this.koWord,
    this.enWord,
    this.koSentence,
    this.enSentence,
    this.koPrompt,
    this.enPrompt,
  );
  final String id,
      koTitle,
      enTitle,
      koWord,
      enWord,
      koSentence,
      enSentence,
      koPrompt,
      enPrompt;
  String title(bool en) => en ? enTitle : koTitle;
  List<RehabTask> tasks(bool en, {bool pacing = false}) => [
    RehabTask(
      id: '$id-word',
      title: en ? 'Word' : '단어',
      text: en ? enWord : koWord,
      instruction: en
          ? 'Listen and say the word at a comfortable pace.'
          : '예시를 듣고 편안하게 말해 보세요.',
    ),
    RehabTask(
      id: '$id-sentence',
      title: en ? 'Sentence' : '문장',
      text: pacing
          ? (en
                ? enSentence.replaceFirst(' ', ' / ')
                : koSentence.replaceFirst(' ', ' / '))
          : (en ? enSentence : koSentence),
      instruction: pacing
          ? (en
                ? 'Pause at / if comfortable. Do not hold your breath.'
                : '/에서 편안하게 쉬어 가세요. 숨을 참지 마세요.')
          : (en
                ? 'Say the sentence. You can listen again.'
                : '문장을 말해 보세요. 예시를 다시 들어도 괜찮아요.'),
    ),
    RehabTask(
      id: '$id-situation',
      title: en ? 'Everyday situation' : '생활 상황',
      text: en ? enSentence : koSentence,
      prompt: en ? enPrompt : koPrompt,
      instruction: en
          ? 'Respond in your own words, or use the example.'
          : '내 말로 답해 보세요. 예시 문장을 사용해도 괜찮아요.',
    ),
  ];
}

const rehabScenarios = [
  RehabScenario(
    'rest',
    '쉬고 싶다고 말하기',
    'Ask for a break',
    '잠시',
    'break',
    '잠시 쉬고 싶어요.',
    'I would like a short break.',
    '가족이 “조금 더 이야기할까요?”라고 물어요. 쉬고 싶다고 말해 보세요.',
    'A family member asks, “Shall we keep talking?” Ask for a break.',
  ),
  RehabScenario(
    'hospital',
    '병원에서 부탁하기',
    'Make a request at the clinic',
    '천천히',
    'slowly',
    '천천히 설명해 주세요.',
    'Please explain it slowly.',
    '설명이 너무 빨라요. 어떻게 부탁할까요?',
    'The explanation is too fast. What would you ask?',
  ),
  RehabScenario(
    'phone',
    '전화로 다시 말해 달라고 하기',
    'Ask someone to repeat on the phone',
    '다시',
    'again',
    '다시 한번 말씀해 주세요.',
    'Could you say that again?',
    '전화 소리가 잘 들리지 않았어요. 상대에게 부탁해 보세요.',
    'You did not hear the caller. Ask them to repeat.',
  ),
];
