# Speech-Practice App Planning Review

[한국어](speech-practice-planning-review.md) | [English](speech-practice-planning-review.en.md) | [All documents](README.en.md)

<!-- reader-link --> [Read with language tabs](https://clevekim00.github.io/mj_dialog/documents/docs/speech-practice-planning-review.en.html)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](game-menu.en.md). Earlier plans and reviews below retain their dated context.

Date: 2026-05-08

For English release, OS-language selection, in-app language settings, and multilingual analysis API planning, follow the [English-launch specification](../spec-english-version-launch.en.md).

## 1. Product direction

This tool helps people with speaking difficulties practice briefly and regularly at home. Its focus is safe repetition, personal goals, change records, and progress that caregivers can understand, rather than an AI score alone.

Core flow:

```text
Safe self-practice
→ Personalized repetition
→ Improved speech intelligibility and communication participation
→ Records shareable with caregivers/professionals
→ A practice tool that does not replace professional assessment
```

## 2. Existing foundations

The app already contains the basics needed for speech practice:

```text
Voice conversation
→ ChatScreen, ChatController, SttService, TtsService
Reading aloud
→ PracticeScreen, PracticeNotifier, PracticeSentenceService
Recording/playback
→ AudioRecorderService, AudioPlayerService
Practice records
→ PracticeHistoryService, PracticeHistoryScreen
Progress overview
→ DashboardScreen
Permission guidance
→ PermissionScreen, PermissionService
```

Strengths:

- A voice-centered rather than text-entry-centered UI suits actual speaking practice.
- Sentence reading and free speech support both structured and everyday practice.
- Recording playback makes self-listening training easy to extend.
- Records/dashboard provide a basis for a regular practice habit.

## 3. Changes in this iteration

Implemented as of 2026-05-08:

```text
Practice onboarding
→ First-use safety, practice period, goals, duration, caregiver participation
Session records
→ Save goal, pre-practice fatigue, and recording time in PracticeSession
Functional phrase library
→ Add phrases for hospital, home, and everyday caregiver situations
Dashboard improvements
→ Show active days and average fatigue over the last seven days
Post-permission flow
→ Require safety onboarding after granting mobile permissions
```

Validation:

```text
flutter analyze
→ No issues found

flutter test
→ All tests passed
```

Structured pronunciation modes added as of 2026-06-01:

```text
Practice selector
→ Today's-practice Home after onboarding, with word/short/long/conversation options
Falling-word game
→ Correctly pronounce before a word reaches the bottom; end with success/failure/average statistics
Review missed words
→ Repeat words scoring below 70; remove after the latest two attempts score at least 80
Word-game difficulty
→ Adjust ordinary words versus tongue-movement syllables such as 퍼터커, 파타카, 피티키
Structured content
→ PracticeContentItem manages mode, category, difficulty, targets, and provenance
Personal long sentences
→ Add, edit, and delete user-registered text
Mode-specific evaluation
→ AiService.evaluatePracticeByMode() separates word/short/long/free-speech criteria
Extended records
→ PracticeSession stores mode, contentId, category, difficulty, retryCount, streakCount, previousBestScore
Dashboard/history
→ Per-mode counts and record chips
```

Validation:

```text
dart analyze
→ No issues found

flutter test
→ All tests passed
```

## 4. Additional features needed

### 4.1 Initial setup based on user condition

Onboarding currently includes safety and basic goals. Next, collect more detailed speaking difficulties and everyday goals.

Needed:

- Main difficulty: quiet voice, too-fast/slow speech, unclear pronunciation, short breath, monotonous intonation.
- Caregiver notes.
- Frequently needed personal phrases.
- Today's condition/fatigue.

### 4.2 Structured sessions

The current flow is largely a single record/feedback loop. Short sessions better fit speech practice.

Recommended structure:

```text
Prepare → Check condition/fatigue
Warm up → Brief vowel phonation or an easy sentence
Core practice → 3–5 personal target sentences, three repetitions each
Everyday speaking → One real-life situation phrase
Finish → Today's changes, difficulties, and next task
```

### 4.3 Improve the scoring system

A single score is easy to understand, but users/caregivers need more specific explanations of change.

Suggested indicators:

```text
Intelligibility → Similarity between target and recognized text
Rate → Recording duration and sentence length
Volume stability → Variation in recorded level
Breath support → Interruptions and length spoken in one stretch
Intonation/rhythm → Begin with AI text feedback; consider acoustic features later
```

Cautions:

- Do not present these as professional assessment scores.
- Emphasize within-person change over comparison between users.
- Distinguish microphone problems, silence, and background noise from speaking difficulty.

### 4.4 Functional phrases and quick expressions

Some functional phrases are available. Users should be able to quickly retrieve frequent phrases to practice or communicate.

Additional categories:

- Hospital: “I have pain,” “I want some water,” “I feel dizzy.”
- Home: “Please help,” “I need the bathroom,” “I will speak slowly.”
- Family: “I feel good today,” “I would like a short rest.”
- Phone: “Please say that again,” “I will speak slowly.”
- Feelings: “I feel frustrated,” “Thank you,” “I am okay.”

Additional UI:

- Favorite phrases.
- Large-button phrase board.
- First-letter cues.
- A screen where a caregiver selects a phrase for the user.

### 4.5 Caregiver/professional sharing

Sharing currently centers on audio files. A summary report would be more useful.

Include:

- Practice count over a period.
- Seven-day practice continuity.
- Goal-specific change rather than just average scores.
- Frequently difficult sentences.
- Fatigue changes.
- Recording sample links/files.
- User/caregiver notes.

### 4.6 Accessibility

Users may also have difficulties with hand control, vision, attention, or fatigue.

Needed:

- Large-button mode.
- One-handed operation.
- Larger text.
- Shorter explanations.
- Do not distinguish scores by color alone.
- Spoken guidance.
- Caregiver-friendly controls.

## 5. Recommended development order

1. Simplify onboarding and safety copy.
2. Add five-/ten-minute session templates.
3. Add repetition counts and rest timers.
4. Split scoring into intelligibility, rate, level, and breathing indicators.
5. Generate caregiver-shareable reports.
6. Add phrase boards and favorites.

## 6. Conclusion

Voice input, reading, playback, records, and dashboard form a useful foundation. Focus on daily low-burden practice and shared understanding of change rather than AI pronunciation grading.

```text
Users practice briefly each day.
Caregivers understand changes.
The app remains a safe practice companion.
```
