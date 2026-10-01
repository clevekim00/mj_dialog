# Integrated oral, alternating-movement, and breathing training implementation plan

[한국어](tongue-exercise-implementation-plan.md) | [English](tongue-exercise-implementation-plan.en.md) | [All documents](README.en.md)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](game-menu.en.md). Earlier plans and reviews below retain their dated context.

Created: 2026-06-01 · Integrated revision: 2026-08-25

## 1. Overview

Replace the existing tongue, facial, alternating-movement, and breathing exercises with the 46 items transcribed in `docs/breathing-and-oral-exercises.md`. Users choose a training type, follow a short demonstration with synchronized captions for a chosen number of repetitions, and save the result.

This plan fixes three product requirements: classification/delivery of all 46 items; one player sharing video, captions, and repetitions; and the migration sequence for existing screens/history. Filenames and Higgsfield prompts follow [video production](training-video-prompts/training-video-production-plan.en.md); menu architecture follows [adaptive menus](adaptive-ui-menu-architecture.en.md).

## 2. Goals and non-goals

### 2.1 Goals

- Make all 14 tongue, 12 lip, 10 alternating-movement, and 10 breathing items from the photographed source browsable.
- Offer the same playback, caption, repeat, speed, pause, and skip controls everywhere.
- Support short category or personal routines instead of requiring all 46 exercises at once.
- Continue with a poster and text when video is missing or fails.
- Gradually migrate to integrated training history while preserving old tongue-exercise records.

### 2.2 Non-goals

- No automatic camera-based judgment of actual performance.
- Video loop counts are not successful user-performance counts.
- No diagnosis or automatic prescription of individual treatment intensity.
- Do not impose the source wording/intensity on every user without clinical review.

## 3. Key decisions

| Item | Decision |
|---|---|
| Source | Transcription in `docs/breathing-and-oral-exercises.md` |
| Structure | Separate the 46-item library from short routines |
| Video | Silent 4–8-second MP4 loops per exercise |
| Captions | App overlays driven by phase/settings; never burned in |
| Repetitions | Automatically count demonstrated loops, without claiming user performance |
| Default routine | 3–5 exercises, approximately 3–7 minutes |
| 20 repetitions | Preserve as source recommendation; users choose 5, 10, 20, or custom |
| Speed | 0.5×, 0.75×, 1× |
| Offline | MVP bundles all 46 optimized videos; target total ≤60 MB |
| Later delivery | If too large, bundle core videos and download category packs |

## 4. Safety and clinical review

Acquired dysarthria treatment should match affected systems such as respiration, phonation, and articulation, and individual condition. Dose depends on energy and severity. Posture, photos, and video can cue articulatory placement. Source: [ASHA Dysarthria in Adults](https://www.asha.org/practice-portal/clinical-topics/dysarthria-in-adults/).

Fast or excessive breathing may cause hyperventilation symptoms such as dizziness. General routines should guide users back to slow, steady breathing. Source: [Cambridge University Hospitals](https://www.cuh.nhs.uk/patient-information/breathing-exercises-in-the-treatment-of-hyperventilation/).

### 4.1 Safety tiers

| Tier | Meaning | Delivery |
|---|---|---|
| `general` | General low-intensity demonstration | Default library and recommended routines |
| `caution` | Caution about fatigue, jaw joint, dizziness, etc. | Confirm warning before starting; keep short in recommended routines |
| `clinicianOnly` | Tools, maximal holds, fast breathing, or other tasks requiring professional review | Exclude from default routines; expose only after clinical approval or in professional mode |

### 4.2 Required review items

- Tongue 7: sustained hold with the mouth wide open.
- Tongue 8: resistance using a tongue depressor.
- Breathing 2: forceful inhalation when holding becomes difficult.
- Breathing 3: rapid deep breathing.
- Breathing 4: imitating hiccups/sobbing.
- Breathing 5–7: maximal holds or pauses after partial breaths.
- Breathing 8–10: maximum sustained vowels.

Tongue-depressor videos must not encourage inserting tools into the mouth alone. Mark professional guidance required and provide a tool-free direction-learning alternative.

### 4.3 Common stop conditions

Guide users to stop immediately and rest for:

- Pain, choking, swallowing difficulty, or breathing discomfort.
- Dizziness, palpitations, or tingling around the mouth/hands/feet.
- Sudden voice change or worsening speech.
- Jaw-joint pain or excessive tongue/lip fatigue.

## 5. Content structure

### 5.1 Categories

| Category | Count | Code | Replaces |
|---|---:|---|---|
| Tongue | 14 | `tongue` | `TongueExerciseScreen` and individual tongue exercises |
| Lip | 12 | `lip` | Mouth/lip items in `FaceExerciseScreen` |
| Alternating movements | 10 | `alternating` | `OralAlternatingExerciseScreen` |
| Breathing | 10 | `breathing` | `BreathingTrainingScreen` |

Remove default-menu facial exercises without direct source counterparts, such as side-to-side jaw movement and cheek inflation. Preserve their titles/IDs in a legacy display mapping for old history.

### 5.2 Shared data model

```dart
enum TrainingCategory { tongue, lip, alternating, breathing }
enum TrainingSafetyTier { general, caution, clinicianOnly }
enum TrainingVisualMode { faceCloseUp, oralCutaway, upperBody, phoneme }

class GuidedTrainingExercise {
  final String id;
  final TrainingCategory category;
  final int sourceOrder;
  final String title;
  final String instruction;
  final String shortCaption;
  final String? secondaryCaption;
  final String videoAsset;
  final String posterAsset;
  final TrainingVisualMode visualMode;
  final int defaultRepeatCount;
  final List<int> repeatOptions;
  final Duration loopDuration;
  final List<double> speedOptions;
  final TrainingSafetyTier safetyTier;
  final String? safetyMessage;
  final List<TrainingCue> cues;
}

class TrainingCue {
  final Duration start;
  final Duration end;
  final String caption;
  final TrainingCuePhase phase;
}
```

Keep exercise data in category-specific Dart files or verifiable JSON, not screen code. Dart constant lists are recommended initially for compile-time validation.

### 5.3 ID convention

```text
tongue_01_vertical
tongue_02_lips
...
lip_01_tuck_extend
...
alternating_01_uiui
...
breathing_01_posture_inhale
```

IDs permanently link video, poster, history, and caption cues. Do not change an ID when its title changes.

## 6. User flows

### 6.1 Starting from the library

```text
Training → Oral & breathing training → Tongue / Lips / Alternating / Breathing
→ Exercise list → Details and safety → Repetitions/speed → Video training
→ Complete or repeat
```

### 6.2 Today's recommended routine

```text
Today → Today's oral & breathing routine → Initial fatigue
→ Play 3–5 exercises in sequence → Rest → Final fatigue → Save history
```

### 6.3 Personal routine

- Select up to 8 exercises from the library.
- Save per-exercise repetitions and speed.
- Begin with one My routine; named multiple routines can follow.
- Reconfirm the warning when adding a `clinicianOnly` item.

## 7. Unified video player

### 7.1 Layout

```text
Tongue · 3/14                         Close
Trace around the lips with the tongue
[Silent demonstration video]
[Current phase caption: 1–2 lines]
Demonstration loops 06 / 20
●●●●●●○○○○○○○○○○○○○○
[0.5×] [0.75×] [1×]
[Previous] [Pause] [Next]
```

### 7.2 Playback rules

- Count one completed video as one demonstration loop.
- Increment on `completed`, not when playback starts.
- After the last loop, stop and show Complete / 5 more / Next exercise.
- Pause automatically on navigation away or backgrounding.
- Recalculate video and caption cues together when speed changes.
- Confirm “Skip this exercise?” once when Next is pressed before completion.
- Never label video loops Successful attempts; they do not verify the user's actions.

### 7.3 Repeat settings

- Quick choices: 5, 10, 20; custom: 1–30.
- Source default: 20.
- At initial fatigue 4–5, suggest half the repetitions and a 30-second rest.
- Suggest splitting routines estimated to exceed 10 minutes.
- For alternating movements, show syllable beats alongside loops without speech-success judgment.

## 8. Captions and spoken guidance

### 8.1 Caption principles

- Do not generate or burn text into videos; overlay Korean captions in the app.
- Aim for at most 2 lines, around 18 characters per line.
- Separate movement, hold, return, and rest into distinct cues.
- Show the current alternating syllable large and the next one faintly ahead.
- Use captions/arrows to clarify whether left/right follows the viewer or performer.

### 8.2 Accessibility settings

- Captions on/off; text 100%, 125%, 150%.
- Translucent black or high-contrast white caption background.
- TTS on/off; vibration at loop completion.
- Captions only / Voice + captions / Demonstration only.

### 8.3 TTS rules

- Read the full instruction once before the first loop.
- Optionally say only Start, Hold, Return, and counts during repeats.
- Separate Listen and Repeat for alternating syllables to avoid overlapping TTS and user speech.
- Continue video/captions when TTS fails.

## 9. Video asset strategy

### 9.1 Visual types

| Type | Use | Description |
|---|---|---|
| Frontal face close-up | Visible tongue/lip movements | Stable head/jaw, enlarged mouth area |
| Side oral cutaway | Internal palate movements | Friendly educational 2D illustration instead of realistic medical footage |
| Frontal upper body | Breathing/posture | Show shoulder, chest, and abdominal movement |
| Syllable cards | Alternating movements | Combine the same tutor's mouth with app syllable captions |

### 9.2 Format

- MP4, H.264 baseline/main compatible profile; 16:9, 1280×720.
- Consistent 24 or 30 fps; 4–8 seconds; no audio.
- Average ≤1.3 MB/video and total ≤60 MB.
- Match neutral posture in the first and last frames for loops.

### 9.3 Failure handling

- Show a poster/progress indicator if loading exceeds 2 seconds.
- On decode failure use poster, arrows, captions, and timer.
- Keep missing-video items visible with Start with text guidance.
- Record video errors separately from exercise completion.

## 10. State and history

```dart
enum GuidedTrainingPhase { ready, playing, paused, rest, complete, error }

class GuidedTrainingProgress {
  final GuidedTrainingPhase phase;
  final List<String> exerciseIds;
  final int exerciseIndex;
  final int completedLoops;
  final int targetLoops;
  final double playbackSpeed;
  final int fatigueBefore;
  final int? fatigueAfter;
  final Set<String> skippedExerciseIds;
  final List<TrainingExerciseResult> results;
}
```

Save session ID/start/end, selected category/routine ID, target and completed loops per exercise, playback speed, skipped exercises/interruption point, before/after fatigue, video failure, content version, and history schema version.

Keep reading existing `TongueExerciseSession`. Label legacy sessions Previous tongue-exercise history and show them in the same dated timeline as new sessions.

## 11. Flutter structure

```text
lib/features/guided_training/
├── model/
│   ├── guided_training_exercise.dart
│   ├── guided_training_routine.dart
│   └── guided_training_session.dart
├── data/
│   ├── tongue_exercises.dart
│   ├── lip_exercises.dart
│   ├── alternating_exercises.dart
│   └── breathing_exercises.dart
├── provider/
│   └── guided_training_controller.dart
├── view/
│   ├── guided_training_hub_screen.dart
│   ├── training_category_screen.dart
│   ├── guided_training_player_screen.dart
│   └── routine_builder_screen.dart
└── widgets/
    ├── training_video_stage.dart
    ├── timed_caption_overlay.dart
    ├── repetition_progress.dart
    └── training_safety_card.dart

lib/services/guided_training/
├── guided_training_history_service.dart
└── training_settings_service.dart
```

Reuse the existing `video_player` dependency. Retain `AnimatedExerciseAvatar` temporarily for missing-video items, but do not expand it as the main renderer for new content.

## 12. Routes and backward compatibility

New routes:

```text
/guided_training
/guided_training/tongue
/guided_training/lip
/guided_training/alternating
/guided_training/breathing
/guided_training/player
/guided_training/routine_builder
```

| Old route | Destination |
|---|---|
| `/tongue_exercise_menu` | `/guided_training/tongue` |
| `/tongue_exercise` | Default tongue routine |
| `/face_exercise` | `/guided_training/lip` |
| `/oral_alternating_exercise` | `/guided_training/alternating` |
| `/breathing_training` | `/guided_training/breathing` |

Retain old routes for one release so bookmarks and existing Home cards keep working.

## 13. Implementation stages

### Stage 1: Content and player foundation

1. Define 46 exercise records and permanent IDs.
2. Add safety tiers and clinical-review status.
3. Build shared player, repeat counter, and caption cues.
4. Validate tongue/lip/alternating/breathing types with 4 sample videos.
5. Add player unit/widget tests.

### Stage 2: Video production and category migration

1. Generate 46 draft videos with Higgsfield.
2. QA character, anatomy, loops, and directions.
3. Compress approved videos and register assets.
4. Build hub and category lists.
5. Migrate the four existing screens to the player.

### Stage 3: History and personal routine

1. Build integrated session storage.
2. Preserve legacy tongue-history reading.
3. Save routine edits/settings.
4. Connect Today and dashboard.

### Stage 4: Stabilization

1. Check video memory on low-end iOS/Android devices.
2. Validate large text and screen readers.
3. Handle backgrounding, calls, and audio conflicts.
4. Obtain SLP review and safety-copy approval.

## 14. Tests and acceptance

### 14.1 Content

- All 46 IDs/titles/order match the transcription.
- Every item has video or poster fallback.
- `clinicianOnly` items never enter default recommendations.
- Video directions match captions.

### 14.2 Player

- Each completion event increments once.
- Captions/completion synchronize at 0.5×, 0.75×, and 1×.
- Pause, background, and restart never double count.
- Autoplay stops after the final loop.
- Text training can complete despite video errors.

### 14.3 Accessibility and safety

- 150% captions do not obscure key controls.
- Screen readers announce title, repeat progress, and button state.
- Text/icons distinguish states without color alone.
- Correct tier warnings and stop guidance appear.

### 14.4 Completion

- All four old entry points reach the new structure.
- Category selection through saving works without interruption.
- Every clinically approved item among the 46 supports video, captions, and repetition.
- Existing tongue history is preserved.
- `flutter analyze` and relevant tests pass.

## 15. Assumptions and remaining decisions

### Confirmed assumptions

- Primary users are adults with acquired dysarthria.
- Core training must work offline.
- The first version prioritizes accurate, consistent demonstrations over performance recognition.
- Use the existing 2D female rehabilitation guide consistently.

### To confirm during clinical review/production

- Final repetitions and holds per item.
- Viewer-versus-tutor direction policy.
- General-user availability of breathing 2–7.
- Tongue-depressor alternative and professional mode.
- Final app size when all videos are bundled.
