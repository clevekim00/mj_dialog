# Sentence Repetition, Re-recording, and Mouth-Movement Video Plan

[한국어](sentence-repeat-and-mouth-video-plan.md) | [English](sentence-repeat-and-mouth-video-plan.en.md) | [All documents](README.en.md)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](game-menu.en.md). Earlier plans and reviews below retain their dated context.

> Update, 2026-09-30: For current implementation, video-review requirements, waveform, and the distinction between voice play and MPT, first consult the [additional design and implementation document](implementation-2026-09-30/README.en.md). The earlier plan is preserved below.

Date: 2026-06-19

## 1. Purpose

After practicing one or two sentences, users should immediately hear their recording, read the same sentence repeatedly, and compare changes. A later stage records front-camera mouth video during free conversation/sentence practice so users can review sound and mouth movement together.

The main flow from the photo notes is:

```text
Sentence practice
→ Finish recording
→ Read again at the end
→ Check after re-recording
→ Repeat unclear words/sentences
→ Review mouth video as well
```

## 2. Scope

### 2.1 First implementation: repetition/re-recording

Directly implementable in the current app:

- Provide “Listen to the latest recording” on sentence results.
- Provide “Listen to the previous recording” after recording the same sentence again.
- Re-record without changing the target through “Repeat this sentence.”
- Identify repeat-practice candidates from low scores or retry counts.
- Re-enter the same sentence through the existing “Practice again” action in recordings.

### 2.2 Second implementation: entry to difficult sentence/word review

Use existing `PracticeSession` fields: `score`, `retryCount`, `contentId`, `targetText`, and `audioFilePath`.

- Classify scores below 70 as recommended for practice again.
- Count repetitions by the same `contentId` or `targetText`.
- Show difficult-sentence cards on today's practice home and open repeat practice.
- Compare the previous best score with the current score.
- Link low-scoring words to word-game/review mode.

### 2.3 Third implementation: mouth video recording

This requires separate packages and permissions. Its first scope was implemented as of 2026-06-19.

Required packages:

```yaml
camera: ^0.12.0+1
video_player: ^2.11.1
```

iOS permission:

```xml
<key>NSCameraUsageDescription</key>
<string>Speech Rehab uses the camera to record mouth movement during speech practice.</string>
```

Android permission:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

Recommended flow:

- Add a “Record mouth video” toggle to practice.
- Start silent front-camera recording together with audio recording.
- Offer “Listen to my voice” and “Watch mouth video” afterward.
- Associate audio and video in the same session using `PracticeSession.videoFilePath`.

Current scope:

- Save silent front-camera video.
- Play video in a bottom sheet immediately after practice.
- Show front-camera preview before/during recording.
- Replay past mouth videos in the recording library.
- Provide a mouth-video toggle, front preview, and latest-video playback in free conversation.
- Save `mouthVideoPath` on free-conversation user messages.
- Delete linked video files when deleting a session.

Follow-up:

- Reopen past mouth videos from the free-conversation history list.
- Automatically analyze lips/mouth opening from video.
- Define video storage limits and old-video cleanup policy.

## 3. Data model extension

`PracticeSession` already contains:

```dart
audioFilePath
score
retryCount
streakCount
previousBestScore
contentId
targetText
mode
```

The first implementation locates a previous audio file in history for comparison.

The third-stage video feature added:

```dart
final String? videoFilePath;
```

## 4. Implementation order

1. Allow side-by-side listening to the latest and previous recordings on results.
2. Keep “Repeat this sentence” clear and improve re-recording UX.
3. Retain “Practice again” in recordings as a repeat-practice entry point.
4. Add difficult-sentence/word review cards to today's practice home.
5. Add front-camera permissions/services.
6. Group audio/video storage paths in one session record.
7. Provide audio and mouth-video playback on results.

## 5. Implemented status

As of 2026-06-19:

- Added `PracticeProgress.previousAudioPath`.
- After recording, automatically find the previous recording with the same `contentId` or `targetText`.
- Provide latest/previous recording playback on results.
- Keep the existing “Repeat this sentence” action.
- Keep recording-library “Practice again” based on the existing session.
- Add “Read difficult sentences again” to today's practice home.
- Add lowest-score, highest-score, and newest-first sorting to recordings.
- Add a saved-for-repetition button and filter.
- Store saved-for-repetition session IDs in `SharedPreferences`.
- Add “Delete unplayable recordings.”
- Bulk cleanup applies to sessions whose stored audio path no longer exists.
- Add `camera` and `video_player`.
- Add iOS/Android camera permissions.
- Add `MouthVideoRecorderService`.
- Add `PracticeSession.videoFilePath`.
- Add a mouth-video toggle and result-video playback to practice.
- Add front-camera preview to practice.
- Show/open mouth videos in the recording library.
- Add recording toggle, front preview, and result-video playback to free conversation.
- Add `ChatMessage.mouthVideoPath`.
- Delete linked mouth-video files with sessions.

## 6. Validation plan

- `flutter analyze`
- `flutter test test/practice_history_service_test.dart test/practice_content_service_test.dart`
- Check audible latest-recording playback after recording in an iOS release build.
- Check previous-recording availability after repeating a sentence.
- Check playback and practice-again actions for older recordings.
- Test camera permissions and simultaneous recording on a physical iPad.
