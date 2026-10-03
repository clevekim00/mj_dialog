# Sentence Repetition, Re-recording, and Mouth-Movement Video Plan

[한국어](sentence-repeat-and-mouth-video-plan.md) | [English](sentence-repeat-and-mouth-video-plan.en.md) | [All documents](README.en.md)

<!-- reader-link --> [Read with language tabs](https://clevekim00.github.io/mj_dialog/documents/docs/sentence-repeat-and-mouth-video-plan.en.html)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](game-menu.en.md). Earlier plans and reviews below retain their dated context.

> Update, 2026-09-30: For current implementation, video-review requirements, waveform, and the distinction between voice play and MPT, first consult the [additional design and implementation document](implementation-2026-09-30/README.en.md). The earlier plan is preserved below.

Date: 2026-06-19

> 2026-10-02: Sections 7–9 define the proposed typed/OCR sentence, two-recording comparison, per-recording AI feedback and comfortable-practice feature. Not implemented yet.

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

## 7. Read My Sentence Twice — product specification (2026-10-02)

**Status: see section 10 for the implemented scope as of 2026-10-02.** This and the following sections supersede conflicting historical plans above. Do not apply the old below-70 recommendation or best-score competition to this feature. The audience is adults with acquired dysarthria practicing at home.

### 7.1 Goals and defaults

Import a useful everyday sentence by typing or OCR, record two readings, and retain each recording with its own AI feedback. Success means participation, listening back, and reflecting on comfort rather than earning a high score.

- Navigation: `Training → Sentence practice → Read my sentence twice`; add a `My sentences` history filter without adding a top-level tab.
- Proposed retention: one sentence has multiple dated practice pairs, each with at most two recordings and one assessment state/result per recording. Await user confirmation of cumulative versus latest-only retention.
- Saving only A is valid. B is optional; an incomplete pair is not a failure.
- Practicing again after both recordings are saved creates a new pair, without overwriting older audio.
- Assessments are independent asynchronous jobs. Playback, B recording, and leaving the screen do not wait for AI.
- Proposed default: recording/playback work offline; server AI requires explicit transmission consent. This specification is not consent to upload.
- Korean and English are supported; sentence language is independent of interface language.

### 7.2 Flow and screens

```text
My sentences → Type / Import photo → Review and edit text
→ Split/select sentences → Save → Optional comfortable preparation
→ Record A → Listen / Open AI feedback → Optional single practice goal
→ Record B → A/B listening → Sentence history → Dated pairs and assessments
```

| Screen | Behavior |
|---|---|
| Sentence library | Title, preview, last practice date, pair count, search and add |
| Input/OCR review | Type/paste, select image or supported camera, crop/rotate, compare source and OCR, edit/split/merge |
| Reading | Large text, user-selected pause marks, optional example audio, A/B state, waveform, fixed record/stop controls |
| Compare | Play A, play B, play in sequence; separate duration/waveform/assessment state; reflection; finish |
| Sentence history | Newest pairs first, A-only labels, pending/completed/unavailable AI, comparison with earlier pairs |

Preserve waveform-on by default with a hide option. Wave height does not indicate speech quality. Feedback cards start collapsed and never pop up automatically. Disable text changes and playback while recording; keep record/stop visible. The existing 120-second capture limit is a technical ceiling, not an endurance goal.

Only one audio file plays at a time. Sequence means A → short gap → B, with looping off. Use original audio at the same playback rate, without automatic loudness normalization. Show matching time/amplitude scales. Microphone, gain, or processing differences invalidate loudness-improvement interpretations. Across text revisions, allow listening but hide numeric change conclusions.

### 7.3 Input and OCR

Images remain limited to 10 MB/20 megapixels. Product limits on sentence count, characters per sentence and total input characters have been removed. Sentence splitting is a suggestion; users correct line-break, abbreviation, number, and quotation errors before confirmation. Suggest meaningful shorter chunks for long text.

OCR must be reviewed before recording. Support reading-order correction, Korean spacing, blurry print and handwriting errors, and manual language selection/splitting for mixed text. Users can crop or remove names and medical details. Do not retain source images by default; delete app-owned temporary copies after confirmation/cancellation, never the user's photo-library original.

Define `TextExtractionService` with capability/language discovery, recognition, cancellation, and temporary-file cleanup. Keep text entry available on every platform. macOS/iOS: evaluate Apple Vision and query OS-supported languages, then verify Korean/English on real devices. Android: evaluate ML Kit Korean/Latin models and expose model installation status. Windows/Linux: independently validate a local OCR adapter, packaging and licensing. Unsupported platforms fall back to typing, never silently to cloud OCR. A mobile Flutter wrapper does not establish desktop/web support; select providers through a PoC. Sources: [Apple Vision](https://developer.apple.com/documentation/vision/recognizing-text-in-images), [ML Kit](https://developers.google.com/ml-kit/vision/text-recognition/v2).

## 8. AI, history and server design

### 8.1 Assessment semantics and contract

Label the result `AI practice feedback`. Do not provide diagnosis, severity, emotional/tension inference, or unvalidated pronunciation-accuracy totals. ASR difficulty is not proof that the user failed to pronounce a word; dysarthric ASR performance varies. [Primary research](https://pmc.ncbi.nlm.nih.gov/articles/PMC6909999/)

Pipeline:

1. Verify actual audio, decoding, duration, silence, clipping and noise suitability.
2. Transcribe without forcing the target sentence as the answer. Keep target alignment separate from independent ASR.
3. Display transcript differences as recognition differences, not pronunciation errors. Version language-specific normalization, e.g. Korean character and English word comparison. Recognition errors may explain substitutions, omissions or insertions.
4. Provide measured duration, pauses and optional alignment. Slower, shorter or louder is not universally better.
5. Generate concise explanations and one next-practice suggestion from bounded structured observations. Treat imported text as data, never executable instructions. Validate output schema/evidence references; fall back to fixed guidance if invalid.

`Assessment`: `id, recordingId, audioSha256, sentenceRevisionId, status, language, analysisVersion, modelVersion, promptVersion, createdAt, transcript?, qualityFlags[], observations[{kind,value,unit,evidenceStartMs?,evidenceEndMs?}], nextPracticeTip?, unavailableReason?, score:null`.

States: `notRequested → queued → running → completed | unavailable | failed | cancelled | expired`. Missing analysis is not zero. Do not invent uncalibrated confidence percentages. User transcript corrections are annotations, not edits to original AI results.

Maintain one assessment row per recording. Failed retries retain its assessment ID. Completed results remain immutable and versioned; do not silently reassess. Request the same pipeline version for a pair and suppress change conclusions if versions differ. Derive comparison observations only when both results are available; no third AI assessment is needed.

### 8.2 Models and persistence

| Entity | Fields and constraints |
|---|---|
| Sentence | UUID, title, language, source(text/ocr), createdAt, currentRevisionId |
| SentenceRevision | UUID, sentenceId, confirmedText, speechLanguage, textHash, createdAt; immutable after recording |
| PracticePair | UUID, sentenceRevisionId, startedAt, localDate, timezoneOffset, status(draft/oneTake/twoTakes), optional tensionBefore/After, fatigue, chosenGoal |
| Recording | UUID, pairId, slot(A/B), relativeAudioPath, audioSha256, durationMs, format, sampleRate, device/processingMetadata, interrupted; UNIQUE(pairId,slot) |
| Assessment | UUID, recordingId UNIQUE, assessment contract above, remoteJobId? |

Relations: Sentence 1:N Revision 1:N PracticePair 1:at-most-2 Recording 1:1 Assessment, including a not-requested assessment row. Renaming a title preserves the revision; changing content/language creates a new revision. Suggest matching existing sentences without merging automatically.

Use transactional local SQLite, selecting a Dart driver after platform tests. Store UUID audio files in the app directory. Journal temporary capture → complete file move → database reference, recovering interrupted saves on startup. Never claim success when storage fails; retain captured temporary audio for retry where available. Full pairs lead to new pairs.

Sentence deletion previews all dependent revisions, pairs, audio, assessments and remote jobs. Maintain retryable pending deletion until files/database/remote work are cleared. Tombstones prevent late responses from resurrecting deleted history. Never delete original user photos. Sharing is explicit.

Preserve existing stores through adapters; do not infer A/B pairing from equal text. Add a `sentencePair` kind to `RehabRecordIndex`. Count actual recorded attempts, not assessment jobs.

### 8.3 API design — see section 10 for implementation

Existing `/v1/analysis/jobs` requires a target phone and position; do not misuse it for arbitrary sentence feedback. Reuse authentication, upload limits and job patterns through a separate contract.

| Method/path | Contract |
|---|---|
| GET `/v1/sentence-analysis/capabilities` | Languages, analysis version, 120-second/file limits, metrics, retention policy/version, readiness |
| POST `/v1/sentence-analysis/jobs` | Multipart audio plus recordingId, assessmentId, sentenceRevisionId, confirmedText, language, audioSha256, analysisVersion, consentPolicyVersion; Idempotency-Key; 202 jobId/status/expiresAt |
| GET `/v1/sentence-analysis/jobs/{jobId}` | Owner-only state and Assessment result |
| DELETE `/v1/sentence-analysis/jobs/{jobId}` | Idempotent cancellation and temporary audio/result removal; report cancelling until active-job deletion is confirmed |

Example metadata: `recordingId=rA, assessmentId=eA, sentenceRevisionId=s1v1, language=en-US, confirmedText=Please give me a glass of water., analysisVersion=sentence-v1`. Link a result only when identifiers, audio hash and sentence revision match. The server recalculates the uploaded file hash.

Errors: 401/403 authentication/ownership; 409 mismatched idempotency payload/version; 413 size; 422 unsupported language or invalid text/audio; 429 limits; 503 not ready. Retry transient network/429/503 failures with backoff; authentication needs separate action. On restart, query known job IDs; expired jobs offer user-triggered reanalysis.

Local history is authoritative. Sentence CRUD and cross-device sync are outside MVP. Production needs durable queues, ownership, idempotency and confirmed deletion. Authentication issuance and sentence ASR/observation/feedback pipelines require implementation. Existing in-memory jobs with short TTL are not durable history.

Before upload, identify the text/audio sent, receiving server/AI provider, purpose and retention. Do not upload OCR images. Proposed targets: remove temporary audio after completion/cancellation, sweep failures within 24 hours, remove results after receipt acknowledgement or within 24 hours. These are design targets, not existing guarantees. Do not log raw text/audio or use it for model training. Verify external provider retention/training terms before release.

### 8.4 Existing foundation and delivery phases

Source inspection on 2026-10-02: `PracticeCapture` uses one PCM stream for waveform and WAV, 16 kHz and a 120-second cap. `PracticeSession` stores target text, audio, feedback and evaluation method/version. `RehabRecordIndex` merges multiple stores. The pronunciation server provides MFA alignment while practiceScore/gop remain null pending validation. OCR dependencies and this sentence/pair model are absent. The available graphify graph covered scripts and did not locate these relationships; current source was inspected directly.

1. Local core: typed text, revisions, two slots, A/B playback, sentence history, deletion/recovery and history adapter.
2. OCR: macOS/iOS and Android PoCs, review UI, model/permission/fallback handling; separate Windows/Linux acceptance.
3. AI: consent, authentication/durable jobs, quality checks, transcript/observations, grounded feedback, idempotent retry/deletion, validation per language.
4. Comfortable practice: optional preparation/reflection, hidden feedback, user and speech-language pathologist usability review.

Acceptance: no A/B swaps; files/text/results remain linked after restart; A-only completion; OCR confirmation required; no fabricated scores on silence/noise; cancellation/offline/deletion/late-response handling; fixed controls accessible with large text; equivalent Korean/English behavior. Validate analysis against expert assessment across languages, dysarthria types/severity and devices. Do not release pronunciation-accuracy numbers before validation.

## 9. Reducing speaking tension — evidence and product application

Research date: 2026-10-02. Psychological anxiety, excessive laryngeal/jaw effort and neurological muscle tone are different. The app must not diagnose their cause or infer tension scores from voice.

| Approach | Evidence and scope | Proposed application |
|---|---|---|
| Comfortable breathing | NHS recommends gentle, unforced breathing for general stress; this is not direct proof of dysarthria treatment efficacy. | Optional comfortable breaths; no breath holding, maximal inhalation or endurance competition. |
| Releasing unnecessary effort | ASHA voice-disorder guidance discusses relaxation for vocal hyperfunction, not a universal prescription for all dysarthrias. | Let shoulders/hands relax; exclude neck pressure, self-laryngeal massage and forceful contraction routines. |
| Gradually broadening speaking situations | NICE social-anxiety guidance supports individual CBT and graduated exposure; app efficacy in dysarthria is a separate question. | Short speech alone → sentence alone → trusted listener → chosen real situation, with user-controlled progression and stopping. |
| Adjusting speech demands | ASHA dysarthria guidance supports individualized communication and respiratory/phonatory strategies. | Meaningful short chunks, chosen pause locations and breaks; no universal speed/loudness target. |
| Lowering feedback pressure | A product hypothesis informed by anxiety guidance, not a validated effect of this app. | No live scores/rankings, optional feedback opening, one next goal, skip/one-recording completion. |

Optional `Get comfortable` preparation, approximately 1–2 minutes: settle into a comfortable position and release unnecessary effort, take a few natural breaths, try a short phrase, then record when ready. This timing is a UI proposal, not a validated therapeutic dose. Preparation never gates recording.

Optional self-reported tension before/after a pair: 0–10 (none to very high) plus skip. This is neither a physiological measurement nor a diagnostic scale. A pre/post change does not establish a treatment effect. Users may select the recording that felt more comfortable regardless of AI observations.

Stop and rest if dizziness, pain or breathlessness occurs. Persistent effortful phonation warrants adjustment with an SLP/clinician. Anxiety or speaking avoidance that substantially limits daily life warrants mental-health assessment/CBT discussion. Do not attribute neurological speech impairment to anxiety.

### Sources

- [NHS: Breathing exercises for stress](https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/breathing-exercises-for-stress/)
- [NICE CG159: Recommendations](https://www.nice.org.uk/guidance/cg159/chapter/recommendations)
- [ASHA: Dysarthria in Adults](https://www.asha.org/practice-portal/clinical-topics/dysarthria-in-adults/)
- [ASHA: Voice Disorders — Relaxation](https://www.asha.org/practice-portal/clinical-topics/voice-disorders/)
- [ASR performance and dysarthric speech: primary research](https://pmc.ncbi.nlm.nih.gov/articles/PMC6909999/)

### Decisions still open

Cumulative versus latest-two retention and server versus local AI remain assumptions pending user answers. Finalize OCR engines, AI provider/cost/retention and language-specific quality thresholds after PoCs. Writing this specification does not upload speech or deploy services.

## 10. Implementation status — 2026-10-02

This section describes the current implementation where it differs from the earlier proposal.

### App flow

1. **Training → Ease speaking tension** offers guidance for preparation, sounds/words, sentences, conversation, voice, oral/breathing exercises, MPT and games. Context buttons open the relevant situation first and are disabled during active recording/measurement.
2. **Training → Sentence practice → Read my sentence twice** accepts typed text or an image. Crop and rotate the image, run on-device OCR, then confirm the Korean/English language and corrected text. Each line is one sentence. There are no product limits on sentence count, characters per sentence or total input characters. Empty input cannot be saved.
3. Start a new pair, record A, listen, and optionally record B. Play each separately or sequentially, with optional waveforms enabled by default. Recordings are limited to 120 seconds; the recording controls stay at the bottom.
4. Select **Request AI analysis with consent** separately for each recording. Review the server, transmitted data and retention before sending the sentence and that audio file. Images are never uploaded. One assessment identity belongs to each recording, including retries.
5. Reopen dated pairs and feedback by sentence or through Records. A second take is optional. New pairs never overwrite old recordings. Optional before/after tension ratings (0–10) are self-reported, not inferred by AI.

### Storage and failures

- The application-support `sentence_practice/history.sqlite` and UUID WAV files store local history. A save journal, temporary-file rename, SHA-256 and SQLite transactions support recovery; a failed audio recovery does not block unrelated history.
- Sentence text is immutable once saved. Add corrected text as a **new sentence**. Grouped revision editing, favorites and cross-device synchronization are not implemented.
- Input, recording, playback and history work without the server. Failed/cancelled/expired analysis does not delete audio. Persisted job IDs allow polling to resume. Retries are user-triggered rather than unlimited automatic retries.
- Clear remaining remote jobs using each take’s cleanup button before deleting a sentence. Local tombstones prevent late results from restoring deleted history. Physical erasure from OS backups/storage is not guaranteed.

### Actual AI and server scope

Implemented `/v1/sentence-analysis/capabilities`, `POST /jobs`, `GET /jobs/{jobId}` and `DELETE /jobs/{jobId}`, separately from the existing phoneme MFA API. A locally installed **faster-whisper** model transcribes without a target-text prompt. Results contain recording duration, low-energy gap count and differences between the target and recognized text. Guidance uses fixed text, not free-form LLM evaluation. Gap count is not a respiratory or intelligibility measure. `score` is always `null`. Silence, very quiet audio and heavy clipping return unavailable feedback.

A durable SQLite queue, restart recovery, owner authentication, idempotency, audio hash/PCM validation, bounded queues and prevention of post-cancellation result restoration are implemented. Run **one server process**. Audio is removed after processing/deletion; jobs/results expire **15 minutes** after creation. Cleanup resumes after restart if the server is stopped. In-flight inference may retain audio in memory until computation finishes: DELETE 204 means stored audio/results are removed and results cannot be reattached, not immediate process-level inference termination.

The app stores feedback locally then attempts remote deletion, retaining a cleanup button on failure. Production login/token issuance, an administration UI, multi-process queues and clinical/language-specific validation remain release work. Missing models/server readiness are shown explicitly. [Setup, API and operational conditions](../server/pronunciation_analysis/README.en.md).

### Platform and validation scope

- macOS/iOS use Apple Vision; Android integrates Korean/English ML Kit OCR. Windows/Linux offer typed input. PNG/JPG input is capped at 10 MB and 20 megapixels. iOS/iPadOS and Android offer photo-library and camera buttons. Both lead to image review, crop/rotation and OCR. Cancellation preserves typed text; imported cache copies are deleted after reading, without changing library originals.
- Validation covers macOS builds, Flutter unit/widget tests, server API tests and actual Korean/English synthetic-speech recognition. iOS/Android device OCR/permission checks and Windows/Linux builds still require separate validation.
- Functional success with a tiny model is not clinical validation on dysarthric speech. Forced alignment and transcript differences are not presented as pronunciation scores.

### Applying tension guidance

The default is comfortable posture, natural breathing, short phrases and optional listening. Contexts suggest choosing pause points, speaking progressively with trusted people, and reducing score/time pressure. No forced deep breaths, breath-holding, neck massage or maximal phonation is added as relaxation training. Stop and rest with pain, dizziness or breathlessness; persistent speaking anxiety warrants individualized speech-language and mental-health support. The ASHA/NHS/NICE references in section 9 support adjunct guidance, not claims of a validated individualized treatment.

Validation record (2026-10-02): 179 full-suite Flutter regression tests passed, followed by 4 sentence-screen tests including image-import cancellation; `flutter analyze` reported no issues. All 36 Python server tests and the macOS debug build passed. A real local HTTP server completed synthetic Korean/English audio upload, recognition, recording-bound results and deletion. Apple Vision extracted both languages from a test image. Documentation checks covered 34 Markdown pairs, 5 HTML pairs and 76 language-tab reader pages.

The macOS picker now returns image data directly through the native channel to address stalled sheet selection. Seven additional OCR/sentence-screen tests passed, covering picker cancellation, size limits and preview data delivery.

**Remaining manual verification:** macOS UI automation stopped reflecting even ordinary menu clicks, so the latest build’s complete real-picker → image review → recognized-text input flow has not been finally verified. Successful real Vision recognition and automated data-delivery/cancellation tests do not replace this end-to-end UI check. Verify with direct interaction and fix any reproducible application issue.

### iPad photo permission fix

The iOS manual plugin registration path now registers `FLTImagePickerPlugin`. Previously the plugin was included in the build but never registered at runtime, so library/camera calls failed to connect. image_picker checks camera authorization with AVFoundation, requests when undetermined, and returns denied/restricted states. Denial shows an app-settings button; restrictions explain Screen Time/device management. PHPicker with `requestFullMetadata: false` imports selected photos without requiring full-library authorization. Connection failures are distinct from permission failures. After returning from Settings, another tap rechecks OS authorization and preserves entered text.

Long OCR results use actions outside the scrolling content. Image review keeps its extract button in a footer, and sentence input keeps confirmation and save in a footer within the available keyboard-adjusted viewport. Sentence content scrolls separately.

Shared recording services request OS microphone authorization at use time. Denial opens a dialog over the current screen with an Open settings action. After allowing access and returning, tapping Record checks permission again; returning alone does not start recording. The iOS manual registration path also registers `RecordIosPlugin` for PCM capture.
