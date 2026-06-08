enum PracticeMode { wordGame, shortSentence, longSentence, freeSpeech }

extension PracticeModeLabel on PracticeMode {
  String get label {
    return switch (this) {
      PracticeMode.wordGame => '단어 게임',
      PracticeMode.shortSentence => '짧은 문장 읽기',
      PracticeMode.longSentence => '긴 문장 읽기',
      PracticeMode.freeSpeech => '자유 말하기',
    };
  }

  String get storageValue {
    return switch (this) {
      PracticeMode.wordGame => 'wordGame',
      PracticeMode.shortSentence => 'shortSentence',
      PracticeMode.longSentence => 'longSentence',
      PracticeMode.freeSpeech => 'freeSpeech',
    };
  }

  static PracticeMode fromStorageValue(String? value) {
    return switch (value) {
      'wordGame' => PracticeMode.wordGame,
      'longSentence' => PracticeMode.longSentence,
      'freeSpeech' => PracticeMode.freeSpeech,
      _ => PracticeMode.shortSentence,
    };
  }
}
