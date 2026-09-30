# Structured pronunciation practice modes: implementation plan

[한국어](structured-practice-modes-implementation-plan.md) | [English](structured-practice-modes-implementation-plan.en.md) | [All documents](README.en.md)

Created: 2026-06-01

Implementation: MVP and UX improvements completed as of 2026-06-02.

Additional planning: focused consonant rehabilitation and phoneme-level acoustic analysis design finalized on 2026-08-26.

Files changed:

```text
lib/features/practice/model/practice_mode.dart
lib/services/practice_content_service.dart
lib/features/practice/view/practice_mode_selection_screen.dart
lib/features/practice/view/word_game_screen.dart
lib/features/practice/provider/practice_provider.dart
lib/features/practice/view/practice_screen.dart
lib/features/practice/view/practice_history_screen.dart
lib/features/practice/view/dashboard_screen.dart
lib/features/chat/view/history_screen.dart
lib/services/practice_history_service.dart
lib/services/practice_content_service.dart
lib/services/api/ai_service.dart
```

Validation:

```text
dart analyze
→ No issues found

flutter test
→ All tests passed
```

## 1. Purpose

The app currently centers on free conversation and reading aloud. Conversation resembles real speaking situations, but varying utterances make assessment and comparison less stable. Add fixed-difficulty, fixed-length practice modes, similar to a typing tutor: words, short sentences, and long sentences. Repeated evaluation of the same items should make changes and continued practice easier to see.

Free conversation supports real-world speech and natural coaching; word/sentence reading supports repetition and consistent assessment.

## 2. Recommended practice structure

Four speaking modes: Word game, Short-sentence reading, Long-sentence reading, and Free conversation. With tongue exercises, a possible sequence is Tongue warm-up → Word game → Short sentences → Long sentences → Free conversation.

## 3. Roles of each mode

### 3.1 Word game

Purposes: short, low-burden repetition; target phonemes/common words; quick experiences of success.

Example Korean practice targets (retained in the original language):

```text
물
약
병원
화장실
도와주세요
괜찮아요
아파요
천천히
```

Suggested measures: target/recognized-text match, retries, success streak, accumulated difficult words, review of missed words, and failure frequency for sound groups requiring tongue/lip movement.

UI: falling words, large text/Record button, stars/checks/streaks on success, a missed-word review entry, Easy/Normal/Focused difficulty, and movement score/exercise-syllable indicator.

Implemented:

- Separate `WordGameScreen` with a falling-word board.
- A target disappears at 70 or more points; reaching the bottom ends the game and shows successes, failures, and average score.
- Show target word, movement score, and exercise-pattern status.
- Words with a `wordGame` result below 70 become review candidates; remove a word once its latest 2 results are both at least 80.
- Start review from Review missed words; mark current review items with a Review chip.
- Add exercise syllables such as `퍼터커`, `파타카`, `피티키`, `버더거`, `타라카`.
- `movementScore`, `baseWeight`, and `isExercisePattern` control movement characteristics and selection weight.
- Easy favors ordinary words; Focused favors exercise syllables/high-movement words.
- Increase weights for the same target sound groups as missed words.

### 3.2 Short-sentence reading

Purposes: useful everyday expressions, pronunciation/communication assessment, and a default mode closely matching `PracticeSentenceService`.

Korean examples:

```text
물을 마시고 싶어요.
조금 쉬고 싶어요.
화장실에 가고 싶어요.
천천히 다시 말해 주세요.
제가 천천히 말해 볼게요.
```

Suggested measures: overall intelligibility, omitted/changed words, speech rate, and change after rereading. Extend `PracticeScreen`; repeat each sentence 1–3 times and show its previous best result.

### 3.3 Long-sentence reading

Purposes: breathing, rate, phrase boundaries, and rhythm; assessment over a more realistic speaking duration; a later mode after familiarity with words/short sentences.

Korean examples:

```text
오늘은 발음 연습을 천천히 하면서 또렷하게 말해 보겠습니다.
병원에 가기 전에 약 먹는 시간을 가족과 함께 확인하겠습니다.
꾸준한 연습만이 올바른 언어 습관을 만드는 비결입니다.
```

Suggested measures: completion, pauses, rate, phrase boundaries, breath duration, and communication of key words. Break lines by meaning, split very long sentences into 2–3 sections, and offer Whole sentence / By section.

### 3.4 Free conversation

Purposes: natural speech near real situations, participation/confidence rather than exact sentences, and sustained AI coaching/conversation. Prefer feedback over scores: summarize stuck points, clarify intended meaning, and suggest words/sentences to practice next. Keep the existing flow; AI may ask questions based on structured-practice results.

## 4. Information architecture changes

### 4.1 Add practice selection

After onboarding, let users choose directly from Today's practice. Move History to a top Home action.

```text
'/practice_modes': PracticeModeSelectionScreen
```

Suggested cards: Tongue warm-up, Word game, Short-sentence reading, Long-sentence reading, Free speaking. Initially route onboarding to `/practice_modes`; retain `/practice` for short/long sentences.

Implemented: `PracticeModeSelectionScreen` is the post-onboarding Home with History/Dashboard actions; word game opens `/word_game`, short/long sentences reuse `/practice`, and conversation opens `ChatScreen`.

### 4.2 Reuse PracticeScreen

The current screen handles sentence practice and free reading. Add `PracticeMode` and reuse recording/analysis instead of rebuilding the screen.

```dart
enum PracticeMode {
  wordGame,
  shortSentence,
  longSentence,
  freeSpeech,
}
```

Add to `PracticeProgress`:

```dart
final PracticeMode mode;
final int currentItemIndex;
final int retryCount;
final int streakCount;
final String category;
```

## 5. Content data design

Extend the functional, difficult, and everyday sentences in `PracticeSentenceService` into a structured service.

```text
lib/services/practice_content_service.dart
```

Proposed model:

```dart
class PracticeContentItem {
  final String id;
  final PracticeMode mode;
  final String text;
  final String category;
  final int difficulty;
  final List<String> targetSounds;
  final int movementScore;
  final int baseWeight;
  final bool isExercisePattern;
}
```

Categories: Everyday, Hospital, Family, Phone, Feelings, Difficult sounds, Breathing practice. A shared word/sentence model simplifies later recommendations, statistics, and favorites.

Implemented:

- Added `PracticeContentService`; words and short/long sentences use `PracticeContentItem`.
- All items have `id`, `mode`, `text`, `category`, `difficulty`, `targetSounds`, `source`; words also have `movementScore`, `baseWeight`, `isExercisePattern`.
- `PracticeContentService.getFailedWordReviewItems()` calculates missed-word reviews.
- `PracticeContentService.pickWeightedWord()` uses difficulty/history weights.
- `PracticeContentService.getDifficultSoundCounts()` counts difficult sound groups.
- Long-sentence mode loads bundled and personal sentences.
- `CustomPracticeContentService` stores personal long sentences in `SharedPreferences`.

## 6. Assessment direction

Use different criteria: words—match/retry/streak; short sentences—intelligibility/omissions/substitutions/rate; long sentences—completion/breathing/pauses/phrasing; conversation—intent/naturalness/next practice. Separate `AiService` prompts by mode.

```dart
Future<AiResponse> evaluatePracticeByMode({
  required PracticeMode mode,
  required String targetText,
  required String spokenText,
  required int durationSeconds,
});
```

MVP can keep `getReadingFeedback()` and add mode to its prompt. Implemented `AiService.evaluatePracticeByMode()` uses mode-specific prompts/fallbacks, emphasizing breathing/phrasing for long sentences and target clarity for words.

## 7. History extension

Record which mode/content was read in `PracticeSession`.

```dart
final String mode;
final String contentId;
final String category;
final int difficulty;
final int retryCount;
final int streakCount;
final int? previousBestScore;
```

Use nullable fields/defaults for backward compatibility:

```text
mode: shortSentence
contentId: null
category: 일반
difficulty: 1
retryCount: 0
streakCount: 0
```

Here the stored category `일반` means General. Implemented all listed fields plus `contentSource` to distinguish personal sentences; old records load with defaults.

## 8. UI implementation

### 8.1 PracticeModeSelectionScreen

```text
lib/features/practice/view/practice_mode_selection_screen.dart
```

Include today's recommended routine, tongue warm-up, four mode cards, and recent summary. Implemented today's count and four cards. Word/short/long cards call `PracticeNotifier.setMode()` before `/practice`; conversation creates a new session and opens `ChatScreen`. This records the implementation notes at the time of writing.

### 8.5 Register personal long sentences

Implemented Add my long sentence, sentence/category input with automatic difficulty estimation, edit/delete in Manage my long sentences, and personal sentences before defaults for immediate repetition.

### 8.2 Word-game screen

Reuse `PracticeScreen` initially; prefer a separate screen as gameplay grows.

```text
lib/features/practice/view/word_game_screen.dart
```

MVP: large word card, Start recording, Next word, success/retry indication, and streak count.

### 8.3 Short/long reading screen

Extend `PracticeScreen` with current mode, separate content lists, meaning-based line breaks for long sentences, previous-best/recent scores, and a prominent Repeat this sentence button.

### 8.4 Free conversation

Retain `ChatScreen` and free reading in `PracticeScreen`; show conversation as its own selection card.

## 9. Implementation stages

### Stage 1: Structure content

Separate words/short/long sentences and extend or replace `PracticeSentenceService`: add `PracticeMode`, `PracticeContentItem`, and `PracticeContentService`; divide current sentences and add words.

### Stage 2: Practice selection

Make practice types clear: add `PracticeModeSelectionScreen`, register `/practice_modes` in `main.dart`, redirect HistoryScreen's reading button there, and route each card to its mode.

### Stage 3: Make PracticeScreen mode-aware

Keep recording/analysis/history: add `mode`, `currentItemIndex`, `retryCount`, `streakCount` to `PracticeProgress`; add `PracticeNotifier.setMode(PracticeMode mode)`; generalize `nextSentence()` to `nextItem()`; change mode copy and save mode metadata.

### Stage 4: Word-game MVP

Enable game-like repeated reading: large card, post-recording match feedback, retry/streak counts, and next word after success.

### Stage 5: Separate assessment prompts

Add mode-based `AiService` assessment, prompts for all four modes, different score explanations, and stronger long-sentence rate/breathing feedback.

### Stage 6: Dashboard/history

Show practice volume by mode: extend `PracticeSession` with mode/category/difficulty, add mode chips to `PracticeHistoryScreen`, counts to `DashboardScreen`, and separate word/sentence/free-speech activity over 7 days.

## 10. Test plan

### 10.1 Unit tests

Correct content per mode; `setMode()` resets text/index; `nextItem()` cycles within the mode; old records load without new fields.

### 10.2 Widget tests

Four selection modes; word card launches word mode; short/long guidance differs; completed history shows a mode chip.

### 10.3 Manual checks

Long text fits small screens; rapid record/stop does not corrupt state; existing conversation remains intact; old history/dashboard records display normally.

## 11. Priorities

Recommended conceptual sequence: structure short sentences → word MVP → long sentences → selection cleanup → mode prompts → dashboard/history.

For visible user impact, the practical development sequence is selection → content structure → word game → short/long split → history/dashboard → advanced prompts.

## 12. Conclusion

Words and fixed-length reading can evolve the app from conversation assistance into structured pronunciation training. Repeating the same material is intended to stabilize assessment, historical comparison, and identifying individual difficulties.

First implementation goal: users choose a mode and read a word/sentence; the app provides suitable feedback/history while preserving existing free conversation.

## 13. Remaining extensions after implementation

The MVP leaves these follow-ups: separate word-game screen; missed-word review summary; personalized falling speed/spawn interval; favorites; stronger per-sentence previous best; section-based long reading; tongue exercise → practice selection; and mode-specific changes in caregiver reports.

## 14. Focused consonant rehabilitation

### 14.1 Audience and purpose

For **adults with acquired dysarthria** who find specific consonants difficult. A chosen consonant progresses through vowel-combination syllables, real words, and short sentences. Users listen to examples, record, replay themselves, and receive server phoneme analysis.

This supports repetition and observing change, not diagnosis or disability grading, and does not replace an SLP's assessment/plan. Prioritize personal-baseline change and repeated success over automatic scores. Safety follows [ASHA's adult dysarthria guidance](https://www.asha.org/practice-portal/clinical-topics/dysarthria-in-adults/), considering articulation, respiration, phonation, prosody, and functional needs together.

### 14.2 Product decisions

| Item | Decision |
|---|---|
| Analysis | Hybrid on-device signal checks + server phoneme analysis |
| Server | Separate `server/pronunciation_analysis/` in the app repository |
| Scope | Initial and final consonants |
| Evaluation | Target interval, position, GoP, possible substitution/omission/distortion |
| Baseline | Shared phoneme criteria + first 3–5 personal attempts |
| Generation | AI candidates during development; automated checks then therapist approval |
| Core content | Bundled for full core offline practice |
| Updates | Version manifest and incremental CDN download |
| Reference audio | Pre-generated item recordings included in packs |
| Device TTS | Fallback only for missing/damaged reference audio |

## 15. Training flow

Focused consonants → choose difficult consonant → initial/final position → fatigue/difficulty → hear syllable → repeat vowel combinations → real words → short sentences → stop/upload/analyze → own/reference playback → phoneme results and possible substitutes → repeat/next → save session and baseline change.

### 15.1 Stages

1. **Syllables:** initially combine onset with `ㅏ·ㅓ·ㅗ·ㅜ·ㅡ·ㅣ`, then diphthongs when stable. For finals vary preceding vowels, e.g. `악·억·옥·욱·윽·익`.
2. **Words:** real daily words with targets at beginning/middle/end. Nonsense syllables belong only in the syllable stage; word-stage items must be dictionary words.
3. **Sentences:** adult daily sentences of 3–8 Korean spacing units, with at least 2 target consonants spread across the sentence.
4. **Repetition:** prioritize low-scoring, therapist-pinned, or recently below-baseline items.

## 16. Korean consonants and pronunciation representation

### 16.1 Initial consonants

Show all 19 modern Hangul initials:

```text
ㄱ ㄲ ㄴ ㄷ ㄸ ㄹ ㅁ ㅂ ㅃ ㅅ ㅆ ㅇ ㅈ ㅉ ㅊ ㅋ ㅌ ㅍ ㅎ
```

Initial `ㅇ` is a null onset, not a consonant sound. Do not score it as an ordinary consonant; use it as a vowel-onset stability comparison and explain this. Actual initial targets in the first phoneme model number 18.

### 16.2 Final consonants

Seven surface sounds:

```text
/ㄱ/ /ㄴ/ /ㄷ/ /ㄹ/ /ㅁ/ /ㅂ/ /ㅇ/
```

Orthographic finals neutralize into these seven representatives or link to the next syllable. Store orthographic jamo separately from the target surface phone.

```json
{
  "orthographicTarget": "ㅅ",
  "surfacePhone": "ㄷ",
  "position": "coda",
  "rule": "coda_neutralization"
}
```

Reserve double finals, linking, nasalization, and liquid assimilation for difficulty-3 expansion packs. Store Korean G2P outputs for every word/sentence so spelling does not select the wrong phone. Consider [KoG2P](https://github.com/scarletcho/KoG2P) or an equivalent validated module, with license review and a clinical exception lexicon.

## 17. Content packs

### 17.1 Core volume

18 initial + 7 final phonemes = 25 target groups.

| Per target group | Quantity |
|---|---:|
| Basic vowel-combination syllables | At least 6 |
| Real words | 12–20 |
| Short sentences | 20 |
| Reference recording | One per syllable, word, and sentence |

At least 500 short sentences in the core pack; complex finals/phonological changes in expansions.

### 17.2 Sentence generation rules

AI generates at least 30 candidates per group during development; release only 20 passing automatic and therapist review.

- 3–8 Korean spacing units; one meaning unit per sentence.
- Adult hospital, family, meals, outings, calls, feelings, and hobbies.
- At least 2 target surface phones at the specified position.
- Exclude difficult proper nouns, slang, childish wording, fear/discrimination, and medical instructions.
- Limit repeated syntax/vocabulary; reject G2P/position mismatches.
- Difficulty 1: simple surrounding vowels; 2: more consonant clusters; 3: phonological changes.
- Only `approved` items may build or deploy to CDN.

### 17.3 Content model

Korean text/category values remain original example data:

```json
{
  "id": "ko_onset_g_001",
  "schemaVersion": 1,
  "contentVersion": "2026.08.1",
  "language": "ko-KR",
  "targetGrapheme": "ㄱ",
  "targetPhone": "k0",
  "position": "onset",
  "level": "sentence",
  "text": "가게에서 고구마를 골랐어요.",
  "pronunciation": ["k0", "aa", "..."],
  "targetSegments": [0, 4, 8],
  "difficulty": 1,
  "category": "일상",
  "audioAsset": "audio/ko_onset_g_001.m4a",
  "approval": {
    "status": "approved",
    "reviewerRole": "slp",
    "reviewedAt": "2026-08-26T00:00:00Z"
  }
}
```

## 18. Development-time generation and approval pipeline

```text
tools/pronunciation_content/
├── consonant_registry.yaml
├── prompts/
│   ├── syllables.md
│   ├── words.md
│   └── short_sentences.md
├── generate_candidates.py
├── validate_hangul.py
├── validate_g2p.py
├── detect_duplicates.py
├── export_review_sheet.py
├── synthesize_reference_audio.py
├── build_content_pack.py
└── tests/
```

No runtime AI generation. Pipeline: registry → AI candidates → Hangul/length/prohibited-word checks → G2P/position checks → semantic deduplication → review CSV → apply therapist decisions → batch reference-audio synthesis → loudness normalization/playback check → JSON/audio pack → SHA-256/signature → bundle copy/CDN upload.

Keep generated originals, model, prompt version, timestamp, automatic results, and approval history for reproducibility.

## 19. Bundled packs and CDN

### 19.1 Bundled pack

Bundle the entire approved core pack under `assets/pronunciation/content/`. First launch/offline must support syllables, words, sentences, examples, recording, and playback. Never delete the bundle; fall back to it if downloads are damaged.

Generate examples with the same speaker/rate/sample rate and use AAC/M4A or another platform-verified format. Target ≤35 MB including JSON and all core audio.

### 19.2 Manifest

Use provider-independent HTTPS. Firebase Cloud Storage supports Flutter download/progress; S3+CloudFront suits edge caching/versioned paths. [Firebase downloads](https://firebase.google.com/docs/storage/flutter/download-files?hl=en), [CloudFront versioning](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/UpdatingExistingObjects.html).

```json
{
  "schemaVersion": 1,
  "channel": "production",
  "minimumAppVersion": "1.1.0",
  "publishedAt": "2026-08-26T00:00:00Z",
  "packs": [
    {
      "id": "ko-consonant-core",
      "version": "2026.08.1",
      "url": "https://cdn.example.com/packs/ko-consonant-core/2026.08.1.zip",
      "size": 23841024,
      "sha256": "...",
      "signature": "...",
      "required": true
    }
  ]
}
```

### 19.3 Update policy

- Check in the background without blocking Home.
- Download only newer, app-compatible versions.
- Prefer Wi-Fi; request consent for mobile data.
- Resume into temporary files, verify size/SHA-256/signature, then atomically swap active pointers.
- Keep the previous download or bundle on failure.
- Short-cache manifests; long-cache immutable version URLs.
- Retain at least one known-good previous version for rollback.

## 20. Phoneme-analysis server

### 20.1 Structure

```text
server/pronunciation_analysis/
├── README.md
├── pyproject.toml
├── Dockerfile
├── app/
│   ├── main.py
│   ├── api/v1/analysis.py
│   ├── domain/models.py
│   ├── services/audio_preprocessor.py
│   ├── services/korean_g2p.py
│   ├── services/forced_aligner.py
│   ├── services/phoneme_scorer.py
│   ├── services/baseline_calibrator.py
│   └── services/result_explainer.py
├── model_registry/
│   └── manifest.yaml
├── scripts/
│   ├── download_models.py
│   ├── calibrate_thresholds.py
│   └── benchmark.py
└── tests/
    ├── fixtures/
    ├── test_g2p.py
    ├── test_alignment.py
    ├── test_scoring.py
    └── test_api.py
```

Do not commit large models or patient recordings. Registry stores only model name, checksum, license, training-data provenance, metrics, and approval status.

### 20.2 Processing

M4A upload → decode/normalize to 16 kHz mono PCM → silence/duration/clipping/SNR checks → Korean G2P → forced alignment → frame phone posteriors → target GoP/competing phones → uncertainty → common/personal-baseline calibration → consonant results/retry guidance.

Consider [MFA's Korean model](https://huggingface.co/MontrealCorpusTools/korean_mfa) for initial alignment. Do not assume a general-adult model accurately assesses dysarthria. Research on uncertainty-aware GoP for Korean dysarthric intelligibility can inform design, but validate release thresholds separately using adult acquired-dysarthria recordings and SLP labels. [INTERSPEECH 2023](https://www.isca-archive.org/interspeech_2023/yeo23_interspeech.pdf).

## 21. Server API

Use asynchronous jobs even for short words because model waits/network retries may be needed.

### 21.1 Request

```http
POST /v1/analysis/jobs
Content-Type: multipart/form-data

audio=<file>
contentId=ko_onset_g_001
targetText=가게
contentVersion=2026.08.1
anonymousPatientId=<pseudonymous-id>
attemptId=<uuid>
```

Resolve approved targets from `contentId`/`contentVersion`; do not trust client-supplied phoneme sequences.

```json
{
  "jobId": "job-uuid",
  "status": "queued",
  "pollAfterMs": 500
}
```

### 21.2 Status and results

```http
GET /v1/analysis/jobs/{jobId}
DELETE /v1/analysis/jobs/{jobId}
GET /health
GET /ready
```

Historical proposed response (the Korean disclaimer means automated practice feedback, not clinical diagnosis):

```json
{
  "jobId": "job-uuid",
  "status": "completed",
  "modelVersion": "ko-gop-1.0.0",
  "contentVersion": "2026.08.1",
  "signalQuality": {
    "accepted": true,
    "snrDb": 24.1,
    "clippingRatio": 0.0
  },
  "overallPracticeScore": 74,
  "confidence": 0.81,
  "phonemes": [
    {
      "expected": "k0",
      "observedCandidates": [
        {"phone": "k0", "probability": 0.63},
        {"phone": "kh", "probability": 0.22}
      ],
      "position": "onset",
      "startMs": 120,
      "endMs": 238,
      "gop": -0.41,
      "practiceScore": 71,
      "status": "retry",
      "errorType": "possible_substitution"
    }
  ],
  "baselineDelta": 8,
  "disclaimer": "훈련 참고용 자동 분석이며 임상 진단이 아닙니다."
}
```

## 22. Phoneme scores and personal baselines

### 22.1 Scoring

GoP uses posteriors to estimate how closely the target interval matches its phone. Phone distributions differ; do not directly display raw GoP as 0–100.

Raw GoP → phone/position normalization → uncertainty penalty → signal-quality gate → 0–100 practice score.

Provisional whole-sentence weights: target consonant accuracy 60%; word completeness/omissions 20%; rate/excessive pauses 10%; signal/analysis confidence 10%. These are unvalidated temporary values, versioned in server configuration.

### 22.2 Personal baseline

- Provisional baseline after 3 valid attempts per phone/position.
- Stable baseline after 5, using median and variability.
- Exclude poor signal, alignment failures, and low confidence.
- Show change such as +8 from baseline separately from shared scores.
- Allow maintenance goals for progressive conditions instead of demanding improvement.
- Reset only by explicit user/therapist action.

### 22.3 Results

Example: “74 points · Try again. Target ㄱ was 8 points above your baseline. Some intervals were analyzed as closer to ㅋ. Listen to the example and read the same word again.”

Limit statuses to Accurate, Caution, Retry, Unavailable. Show substitutions only as possibilities with sufficient confidence, never certainty. Classic GoP work supports the importance of phone-specific thresholds and human ratings: [Witt & Young, 2000](https://doi.org/10.1016/S0167-6393(99)00044-8).

## 23. UI and state

### 23.1 Menu

Today's practice → Focused consonants → Choose consonant / Initial / Final / Therapist-assigned / Consonant history.

### 23.2 Key screens

1. **Selection:** recent score, baseline change, assigned marker.
2. **Setup:** initial/final, syllable/word/sentence, repeats, slower example.
3. **Training:** large target, highlighted consonant, example playback, Record.
4. **Waiting:** separate upload/analysis progress, allow cancellation.
5. **Result:** A/B own/reference playback, segment score, possible substitutes, Retry.
6. **Summary:** attempts, highest/median score, baseline change, next recommended target.

Complement audio with target highlighting and completion vibration. Use text/icons as well as color.

## 24. Models and code reuse

### 24.1 New models

```dart
class ConsonantTrainingTarget {
  final String grapheme;
  final String phone;
  final PhonemePosition position;
  final List<String> vowelFrames;
}

class PhonemeAnalysisResult {
  final String expectedPhone;
  final List<PhoneCandidate> observedCandidates;
  final int startMs;
  final int endMs;
  final double rawGop;
  final int practiceScore;
  final double confidence;
  final PhonemeFeedbackStatus status;
  final String? errorType;
}

class ConsonantBaseline {
  final String phone;
  final PhonemePosition position;
  final double medianScore;
  final double variability;
  final int validAttemptCount;
  final String modelVersion;
}
```

### 24.2 Reuse

- `AudioRecorderService`: recording/local files; fix sample rate/channels or guarantee server conversion.
- `AudioPlayerService`: A/B playback.
- `PracticeSession.phonemeAccuracy`: replace the plain map with versioned results or add compatible fields.
- `PracticeHistoryService`: mode, job ID, model/content versions, baseline delta.
- `PracticeContentService`: read combined bundle/downloads through `ContentPackRepository`, not runtime generation.
- `VoiceSignalAnalyzer`: pre-upload silence/clipping/level checks, not phoneme judgments.
- `TtsService`: fallback for failed reference audio, not the runtime default.

At this planning point `TtsService` is disabled on iOS; core use must not depend on it. Bundled recordings provide consistent examples while native TTS conflicts are resolved separately.

## 25. Privacy, safety, and operations

- Obtain separate consent before first server upload, explaining purpose.
- Use random patient IDs, not names, phone numbers, or diagnoses.
- Enforce TLS; default to deleting original audio immediately after analysis.
- Research/model-training retention requires separate explicit consent and withdrawal.
- Do not log raw audio, full sentences, or local paths.
- Record model/content/threshold versions for reproducibility.
- Never label automated scores as diagnosis, severity, or treatment success/failure.
- Advise stopping and consulting a professional for swallowing/breathing difficulties, severe fatigue, or pain.

## 26. Failures and fallbacks

| Failure | User handling | System handling |
|---|---|---|
| Offline | Continue bundle practice, recording, playback | User chooses whether to queue encrypted analysis requests |
| Timeout | Analysis is taking longer | Exponential backoff; deduplicate by `attemptId` |
| Poor signal | Retry in a quiet place | No score/baseline contribution |
| Alignment failure | Own playback and retry only | Save `analysis_unavailable`; no invented score |
| Low confidence | Hide substitution candidates | Return Difficult to judge instead of a score |
| CDN failure | Start from bundle immediately | Keep known-good pack; delete partial files |
| Checksum/signature failure | Suppress update announcement | Never activate; log security event |
| Damaged reference | Device TTS or text | Redownload on next update |
| Model change | Explain limits on old-score comparison | Separate version baselines and recalibrate |

## 27. Implementation stages

### Stage 1: Schema and bundle

Define registry; AI generation/check scripts; review CSV/approval gate; 25 groups, 500 sentences and audio; bundled `ContentPackRepository`. Done when offline selection/content/example playback works.

### Stage 2: Training UX

Selection/training/results/history; existing audio services; highlights/repeats/fatigue/playback; `PracticeMode.consonantFocus` or separate module. Done when users finish and compare recordings without a server.

### Stage 3: Analysis-server MVP

FastAPI jobs; preprocessing/quality gate; Korean G2P/alignment/posteriors/GoP; 18-initial/7-final schema; versioned models/thresholds and Docker. Done when approved recordings yield reproducible intervals/raw GoP/confidence.

### Stage 4: Clinical calibration and baseline

Build an SLP-labeled adult acquired-dysarthria evaluation set; calibrate phone/position thresholds and uncertainty; first 3–5-attempt baseline/delta; cross-version comparison policy. Meet predefined human agreement, sensitivity/specificity, and failure-rejection criteria.

### Stage 5: CDN

Manifest/checksum/signature; background/resume/atomic activation; rollback/bundle fallback; staging/production. Never lose a valid pack under corruption, interruption, older versions, or incompatible clients.

### Stage 6: Therapist settings/reports

Assigned consonant/position; maintenance/improvement goals, repetitions and difficulty lock; weekly consonant medians/baseline changes; original audio sharing only with separate consent.

## 28. Validation

### 28.1 Content

Check spelling-position/G2P agreement; 20 approved sentences per each of 25 groups; length/duplicates/prohibited terms/category distribution; reject unapproved builds; verify all reference files, duration, decoding, and levels.

### 28.2 Server

Reject scoring silence/clipping/excessive noise; alignment regressions for initials/finals/linking/neutralization; deterministic same-file/model results; no confident substitution claims at low confidence; duplicate/cancel/timeout/model-not-ready handling. Target p95 ≤5 seconds for utterances ≤10 seconds.

### 28.3 App

Complete fully offline; A/B playback; restore pending jobs after relaunch; app exit/network switch during CDN download; retain pack on checksum error; large text, screen-reader labels, keyboard, and non-color status cues.

### 28.4 Clinical

At least 2 SLPs independently label each consonant correct/incorrect/undeterminable. Report inter-rater and model/human agreement, sensitivity/specificity by phone/position/severity, and disparities by sex, age, cause, and severity. Do not transfer general-adult thresholds directly to patients. Test whether score wording causes frustration or misunderstanding.

## 29. Release criteria

- Bundle 25 core groups and 20 approved sentences per group.
- Offline content/examples/recording/playback work.
- Poor signal/low confidence are never disguised as scores.
- Every result includes model/content version, confidence, and non-diagnostic wording.
- Initial/final clinical validation meets predefined approval criteria.
- Baselines form from 3–5 valid attempts and can be reset.
- Damaged CDN packs still allow bundled practice.
- iOS can play every core example without device TTS.
- Default original-audio retention is Do not store.

## 30. Remaining operational assumptions

- Abstract CDN through standard HTTPS manifests, independent of provider.
- First-release finals cover 7 surface phones; complex finals/rules are expansions.
- AI is a development tool, not an on-demand sentence generator during use.
- Start therapist approval with CSV; later expand to web review as content grows.
- Select the Korean acoustic model in the registry after comparing licensing, reproducibility, and adult dysarthria validation.
