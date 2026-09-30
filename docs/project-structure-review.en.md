# Speech Rehab Project Structure Analysis and Improvement Review

[한국어](project-structure-review.md) | [English](project-structure-review.en.md) | [All documents](README.en.md)

Date: 2026-04-29

## 1. Project summary

Speech Rehab is a Flutter AI speech-practice coach. Core features are voice-based AI conversation, reading aloud, pronunciation feedback, and conversation/practice history.

The code has grown beyond a simple chat prototype: `chat` and `practice` are separate features with a shared service layer. Initial entry checks permissions and routes to history or permission guidance.

## 2. Top-level structure

```text
.
├── lib/
│   ├── main.dart
│   ├── features/
│   │   ├── chat/
│   │   │   ├── provider/
│   │   │   └── view/
│   │   └── practice/
│   │       ├── model/
│   │       ├── provider/
│   │       └── view/
│   └── services/
│       ├── api/
│       ├── audio/
│       ├── history_service.dart
│       ├── permission_service.dart
│       ├── practice_content_service.dart
│       ├── practice_history_service.dart
│       └── practice_sentence_service.dart
├── backend/
│   └── src/main/kotlin/
├── docs/
├── test/
├── android/
├── ios/
├── macos/
├── web/
├── linux/
└── windows/
```

## 3. Main modules

### Entry and routing

`lib/main.dart` handles Flutter initialization, mobile Gemma initialization, Riverpod `ProviderScope`, route registration, and `StartupResolver`.

```text
main()
→ Flutter/Gemma initialization
→ MyApp
→ StartupResolver
→ PermissionService.hasAllPermissions()
→ Granted: PracticeModeSelectionScreen
→ Not granted: PermissionScreen
```

Up-front permission guidance makes entry clear. However, `StartupResolver` reads permission state directly through `FutureBuilder`, so rechecking after a change depends on navigation.

### Chat

Main files:

```text
lib/features/chat/provider/chat_provider.dart
lib/features/chat/view/history_screen.dart
lib/features/chat/view/chat_screen.dart
lib/features/chat/view/permission_screen.dart
lib/features/chat/view/widgets/animated_orb.dart
lib/features/chat/view/widgets/feedback_card.dart
```

`ChatController` manages the session list/current session, STT state, AI responses, TTS playback, and history persistence. State is better organized, but session management and voice I/O remain in one controller and will need separation as the feature grows.

```text
Select/create conversation in HistoryScreen
→ ChatScreen
→ Tap microphone
→ SttService.startListening()
→ Final text detected
→ AiService.getResponseAndFeedback()
→ TtsService.speak()
→ Show FeedbackCard
→ HistoryService.saveSessions()
```

### Practice

Main files:

```text
lib/features/practice/provider/practice_provider.dart
lib/features/practice/view/practice_screen.dart
lib/features/practice/view/practice_history_screen.dart
lib/features/practice/view/dashboard_screen.dart
```

`PracticeNotifier` handles word game, missed-word review, short/long reading, free speech, personal long sentences, recording, STT, AI evaluation, playback, sharing, and persistence. The user-facing scope is rich, but one notifier concentrates recording/STT/analysis responsibilities.

```text
StartupResolver
→ PracticeModeSelectionScreen
→ Choose word / short / long / conversation
→ WordGameScreen / PracticeScreen / ChatScreen
→ Start recording
→ Start STT and local recorder
→ Stop recording
→ Stop STT and finalize text
→ AiService.evaluatePracticeByMode()
→ PracticeHistoryService.savePractice()
→ Feedback, playback, sharing
```

`CustomPracticeContentService` stores personal long sentences in `SharedPreferences` and combines them with defaults.

`PracticeContentService.getFailedWordReviewItems()` derives review words from history. Words with a score below 70 become candidates; two most recent scores of at least 80 remove them.

`PracticeContentService.pickWeightedWord()` selects the next word using difficulty, exercise-syllable status, movement score, and failures. `getDifficultSoundCounts()` summarizes target groups from word records below 70 for the dashboard.

The word game uses a dedicated falling-word board in `WordGameScreen`. `PracticeNotifier` manages `FallingWord` and `WordGameStatus`, updating positions with a timer. A score of at least 70 removes a word; reaching the bottom ends the game and shows successes, failures, and average score.

### Services

Services form the boundary between UI and platform features:

```text
lib/services/api/ai_service.dart
lib/services/audio/stt_service.dart
lib/services/audio/tts_service.dart
lib/services/audio/audio_recorder_service.dart
lib/services/audio/audio_player_service.dart
lib/services/history_service.dart
lib/services/practice_history_service.dart
lib/services/permission_service.dart
lib/services/practice_content_service.dart
lib/services/practice_sentence_service.dart
```

Separation by feature is a strength. However, repository models in provider files and services that swallow exceptions into simple fallbacks can complicate tests and diagnosis.

### Backend

The Kotlin module contains a Spring-style Gemma 4 voice-evaluation API stub.

It is not directly connected to structured practice evaluation. Flutter's `AiService.evaluatePracticeByMode()` uses recognized text and mode-specific prompts to produce word/short/long/free-speech feedback.

## 4. Validation results

Initial direct checks:

```text
flutter analyze
→ 15 issues found

flutter test
→ Failed
```

`test/widget_test.dart` still expected “Gemma AI Coach” and “메시지를 입력하세요...” (“Enter a message…”), although the app now uses history-first entry and voice-only UI.

Main analyzer issues:

```text
lib/features/practice/provider/practice_provider.dart
→ Dead code from duplicate null checks
→ Deprecated Share API
lib/services/api/ai_service.dart
→ Unused Gemma 4 helpers
→ Unnecessary dart:ui import
→ Missing braces in if/else
lib/features/practice/view/practice_screen.dart
→ Unused import
lib/services/audio/audio_recorder_service.dart
→ Direct path import without a pubspec dependency
lib/services/practice_history_service.dart
→ Unused uuid import
lib/features/chat/view/history_screen.dart
→ Prefer whereType
```

Final state after fixes on 2026-04-29:

```text
flutter analyze
→ No issues found

flutter test
→ All tests passed
```

Changes:

```text
test/widget_test.dart
→ Test current Startup desktop permission bypass and history
lib/features/practice/provider/practice_provider.dart
→ Remove duplicate audioFile null check
→ Replace deprecated Share API with SharePlus.instance.share()
lib/services/api/ai_service.dart
→ Remove dart:ui and unused Gemma 4 helpers; add if/else braces
lib/features/practice/view/practice_screen.dart
→ Remove unused import
lib/services/practice_history_service.dart
→ Remove unused uuid import
lib/features/chat/view/history_screen.dart
→ Use whereType
pubspec.yaml
→ Declare directly imported path package
```

## 5. Improvement review

### P0. Restore tests

Tests initially failed and now pass after adjustment to `StartupResolver` and history.

```text
test/widget_test.dart
→ Removed obsolete title/text-input expectations
→ Fix platform to macOS to make permission bypass explicit
→ Verify history and automatically created “New conversation”
```

Unit tests are more appropriate than widget tests for `ChatController`, `PracticeNotifier`, and `AiService` parsing.

### P0. Remove static-analysis warnings

All 15 issues are resolved. Most were small cleanup, but some signalled real quality concerns.

```text
practice_provider.dart → Duplicate audioFile null check removed
practice_provider.dart → Share.shareXFiles replaced with SharePlus.instance.share()
audio_recorder_service.dart → path added to pubspec dependencies
ai_service.dart → Unused Gemma 4 prompt/parser removed
```

### P1. Separate models and state responsibilities

`ChatSession`, `ChatMessage`, and `ChatSessionState` currently share `chat_provider.dart`. Separate models, storage, and controller as the feature grows.

```text
lib/features/chat/model/chat_message.dart
lib/features/chat/model/chat_session.dart
lib/features/chat/provider/chat_controller.dart
lib/features/chat/provider/chat_state.dart
```

Likewise, move `PracticeProgress` and `PracticeSession` to model files to reduce potential view/provider/service circular dependencies.

### P1. Improve persistence

Conversation/practice history uses JSON strings in `SharedPreferences`. Adequate for MVP, but volume creates performance/migration burdens.

```text
Short term
→ Add debug logging/recovery instead of silently returning [] on JSON failure
→ Add a storage version field
→ Add old-audio cleanup policy
Medium term
→ Consider Drift, Isar, or SQLite
→ Add a repository for unified ChatSession/PracticeSession search
```

### P1. Stabilize voice capture

Practice starts STT and high-quality recording together. The current 400ms stabilization delay may behave differently by device.

```text
Introduce AudioRecordingController or SpeechCaptureService
→ Centralize STT/recorder start-stop order
→ Distinguish recording, STT, and permission failures
→ Explicitly guarantee whether an audio file was created
```

`AudioRecorderService.isRecording()` currently always returns false; track actual state or remove it.

### P1. Clarify AI evaluation

`AiService.evaluateAudio()` appears to be Gemma 4 analysis but does not currently use the audio file, creating a gap between README/UI expectations and quality.

```text
Local MVP
→ Rename to evaluateReadingFromTranscript and state that it uses STT text
Backend integration
→ Connect /api/ai/evaluate with Flutter Dio
→ Multipart audio upload
→ Map GemmaResponse to AiResponse
```

### P2. Clean backend/build artifacts

Tracked artifacts or unclear files include:

```text
Components.
Settings
backend/.gradle/**
backend/bin/main/**
```

They normally should not be source-controlled. Review removal and `.gitignore` additions:

```text
backend/.gradle/
backend/build/
backend/bin/
Components.
Settings
```

### P2. Update documentation

Clarify:

```text
Current audio AI analysis is largely simulation/fallback
Test status and platform limitations
Backend is an experimental stub
Mobile/desktop permission, STT, and Gemma differences
```

## 6. Recommended execution order

1. Restore tests: complete; current Startup/history tests pass.
2. Fix analysis: complete; dead code, unused imports, deprecated API, and missing dependency resolved.
3. Review tracked `backend/.gradle`, `backend/bin`, `Components.`, and `Settings`; strengthen ignore rules.
4. Decide between real audio-backend evaluation and an explicitly transcript-based MVP.
5. Separate Chat/Practice model, state, and controller files.
6. Add persistence versioning and assess a local database as history grows.

## 7. Suggested small work units

```text
Step 1 → widget_test.dart updated; flutter test verified
Step 2 → 15 analyzer issues resolved; flutter analyze verified
Step 3 → Strengthen .gitignore; decide which tracked artifacts to remove
Step 4 → Clarify AiService.evaluateAudio responsibility; document actual evaluation path
```

## 8. Conclusion

The project is growing quickly with a clear voice-conversation/reading direction. Tests and analysis now pass. Descriptions that overstate actual audio evaluation remain a key follow-up.

Clarify the AI path and storage layer next. Deciding whether `evaluateAudio()` analyzes audio or represents transcript-based assessment will improve both backend integration and documentation reliability.
