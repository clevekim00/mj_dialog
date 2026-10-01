# In-Task Guidance, Sound Graph, and Easy Voice Game

[한국어](README.md) | [English](README.en.md) | [All documents](../README.en.md)

<!-- reader-link --> [Read with language tabs](https://clevekim00.github.io/mj_dialog/documents/docs/implementation-2026-09-30/README.en.html)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](../game-menu.en.md). Earlier plans and reviews below retain their dated context.

2026-09-30 · Home-practice app for adults with acquired dysarthria.

## 1. Product decisions

Users open guidance when needed, review it at their own pace, and then speak. The waveform supports observation of sound level and pauses; it is not a pronunciation-accuracy or recovery score. The voice game is a motivational prototype. **Do not label its continuous-detection time as clinical MPT.**

## 2. Implemented user flow

### Guidance within a task

`Today → Start practice → Check fatigue → Listen first → Check one part → Speak when ready → Record → Self-check`

- Tie instructions to the actual task text. Examples play only on user action and are labelled TTS.
- Split at `/` if present, otherwise at spaces. Users can hear each part separately. These are not acoustically detected boundaries.
- Show the initial consonant of the first Korean syllable. Do not present silent initial ㅇ before a vowel as a consonant instruction. This does not automatically prescribe coda pronunciation or liaison rules.
- Add asking for water: `물 → 물을 주세요 → 가족에게 부탁하기` (“water → water, please → ask a family member”) in one plan.
- Steps never advance automatically; guidance can be folded/reopened. Persist the option to start future guidance folded.
- Stop TTS, playback, and connected demonstrations before recording. Do not play examples while the user speaks.
- Add “Practice with guide and sound graph” to existing general sentence practice. Pass the same text to the new recording flow without replacing the older analysis engine wholesale.

### Mirror

- Off by default; initialize the camera only when tapped.
- Preview only; this feature makes no video-record/save calls.
- On denied permission or unsupported hardware, explain the issue and allow voice practice to continue.
- Release the camera on backgrounding/screen removal. Do not automatically reopen it on return.
- Keep the older mouth-video recording feature separate.

### Conditions for demonstration video

`ReviewedSpeechMedia` contains the exact prompt, reviewer identifier, content version, and audio-synchronization flag. Only assets meeting text/review requirements enter the demonstration player. No autoplay or infinite looping; text/audio guidance remains available on failure.

**No clinically reviewed videos are currently connected to the new tasks.** The eight existing silent oral/breathing videos remain on their original screens. They were not repurposed as exact mouth demonstrations for phrases such as “물을 주세요.” This implementation does not claim new video generation, anatomical tongue cross-section animation, or completed expert review.

Production order:

1. Obtain one naturally synchronized voice/mouth demonstration set for water/everyday phrases.
2. Have a reviewer check text, lip contact, viewing timing, and audiovisual synchronization.
3. Add only necessary placement illustrations; do not infer hidden tongue movement from external video.
4. Connect approved assets and review metadata through `ReviewedSpeechMedia`.
5. Verify users can understand, start, and stop independently before expanding.

## 3. Waveform implementation

UI names are “Show sound graph” and “Sound over time.” Technically this is a peak envelope over roughly 64ms PCM windows for viewing the entire signal, not syllable correctness, accurate pronunciation, or dB SPL.

- Reuse Voice Tool's `VoiceSignalAnalyzer`; skip spectrum computation in this path to reduce cost.
- `PracticeCapture` uses one 16kHz mono PCM16 input for both recording and graphing. It does not open another microphone alongside recording.
- Optionally show a live graph and show the saved full envelope afterward/in record details.
- Use a fixed full-scale amplitude axis. Do not normalize each recording's maximum to 100%, which would make different levels look equal.
- Retain same-text comparison/playback. Differences in microphone, distance, and background noise limit direct comparisons.
- Save the full WAV in the new path, rather than using Voice Tool's latest-10-second buffer for long recordings. The original tool's storage was not changed.
- Limit each task recording to 120 seconds, about 3.84MB raw PCM, for product memory reasons. At the limit, save received audio and pause. This is neither a recommended practice duration nor an MPT testing limit.
- On input end/error, attempt to finish/save. A watchdog also detects missing input.
- Retain PCM in memory for retry after file-write failure. Retry record persistence with the same ID. Recovery of unsaved memory after forced app/process termination is not guaranteed.
- Save WAVs as `voice_analysis/rehab_*.wav` in the existing app-documents directory. Verify owned names/paths and remaining references before deletion.

## 4. Voice-game prototype

Entry: `Training → Comfortable voice practice → Gentle voice flight`.

| Item | Implementation |
|---|---|
| Start | Manual start after fatigue check; briefly stay quiet to sample surroundings |
| Control | The bird advances slowly when reliable pitch is detected |
| Pitch | Establish a baseline from initial detected sound and reflect relative changes gently |
| Difficulty | Wide passage; no collision, failure, ranking, or intensity escalation |
| Rest | Stop motion when pitch is unreliable; never demand a louder voice |
| Duration | One round up to 20 seconds; stop anytime; no automatic repeat |
| End | Stop/save audio and available results on backgrounding or input end |
| Records | Separate voice-play category, full audio, envelope, and estimated longest continuous detected interval |
| Excluded | MPT, respiratory diagnosis, treatment-effect score, normal/abnormal classification |

Internal algorithm: `flight-feedback-v1`.

- Use median dBFS over roughly the first 0.8 seconds as the surrounding-sound baseline.
- Require existing analyzer pitch confidence ≥0.55, pitch ≥60Hz, and an input-level condition. These are engineering thresholds for the prototype, not clinical criteria.
- Baseline pitch is the median of the first eight detected frames. Map at most ±4 semitones to a narrow area around screen center. Users are not required to achieve that range.
- Break continuous intervals on undetected frames, clipping, or sample-time gaps. Do not combine multiple vocalizations into a single-breath duration.
- Detection does not identify a person, vowel, or breath. External voices/sustained noise can cause false positives; weak/irregular voices can be underestimated. No detection does not mean “zero vocal ability.”

## 5. MPT conclusion and separate design

Voice onset/offset can technically be estimated. But a game involving pitch changes and multiple breaths does not produce MPT under consistent conditions. Phonation style, breathing, pitch, intensity, and protocol affect MPT. Summing voiced frames is also different from maximum sustained phonation on one breath.

Design a separate future measurement mode:

1. A professional confirms suitability and defines vowel, posture, breathing, comfortable pitch/level, trials, and rest. Do not show moving obstacles or pitch targets.
2. Preserve full trial audio and sample-based timestamps. Time since pressing record is not phonation time.
3. Show candidate onset/offset and quality warnings; allow manual correction while listening.
4. Distinguish coughing, intervening inhalation, sustained noise, clipping, and uncertain detection. Do not call audio unvoiced merely because pitch is unavailable.
5. Keep repetitions as separate trials; summarize only reviewed valid trials according to the protocol. If stopped or capped by the app, mark the maximum as unconfirmed.
6. Compare estimates against expert-marked intervals and validate error/failure rates before releasing MPT estimation. Do not invent normal ranges or recovery scores.

**At the initial implementation, an MPT mode was not implemented or validated. See the subsequent observer-timed mode below.** Voice play and basic signal estimation were implemented with separate data/UI to avoid confusion with clinical measurement.

## 6. Code and compatibility

- `lib/features/rehab/guide/`: step guidance, reviewed-video contract, preview-only mirror.
- `lib/features/rehab/audio/`: single PCM capture, full WAV saving, envelope display.
- `lib/features/rehab/game/`: voice-feedback algorithm and easy flying screen.
- `RehabTake`: optional waveform/durationMs; old JSON loads an empty waveform.
- `RehabSession`: optional feedback; game audio references use the new-session repository but appear as a separate unified-record category.
- No ASR-score/difficulty linkage. Keep the four top-level menus.

## 7. Validation and pre-release checks

Automated coverage: full PCM retention beyond 10 seconds (12.8-second example), retry after file failure, denied permission, fragmented PCM assembly, separation of continuous intervals, duplicate-frame exclusion, clipping/no detection, input gaps, baseline/gentle movement, manual guide progression, persisted folding, 200% text, background game stop/save, and legacy-session compatibility.

macOS build/screen results and final test counts are below. Real dysarthric-speech accuracy, simultaneous microphone/camera use on iOS/Android, actual VoiceOver/TalkBack, and clinical video review remain separate checks. UI and synthetic signals were tested without granting new microphone permissions or collecting user speech.

## 8. Evidence versus product decisions

- [ASHA Dysarthria in Adults](https://www.asha.org/Practice-Portal/Clinical-Topics/Dysarthria-in-Adults/): individualized goals, speech-system approaches, and visual cues/feedback informed the design; this does not establish this game's treatment effectiveness.
- [W3C clear step-by-step instructions](https://www.w3.org/WAI/WCAG2/supplemental/patterns/o4p07-step-instructions/): short steps/examples near the activity informed UI design.
- [ASHA instrumental voice-assessment protocol](https://pubs.asha.org/doi/10.1044/2018_AJSLP-17-0009): consistent conditions and habitual pitch/level for sustained vowels informed the design. Do not equate its short acoustic sample with MPT.
- [Maximum Phonation Time in Healthy Older Adults](https://pmc.ncbi.nlm.nih.gov/articles/3128209/): research on MPT trials/repetition/rest. Do not prescribe its healthy-older-adult procedures/results directly to users with dysarthria.

The 0.8-second calibration, 20-second game, 120-second recording limit, and motion range are engineering choices, not clinical dosage recommendations.

## 9. Execution results

- `flutter analyze --no-pub`: no warnings/errors.
- Full regression suite: 140 passed.
- Later, six camera-handoff/game-record-separation tests and eight immediate-guide-stop/save-resume tests passed, including overlapping reruns.
- macOS debug build succeeded. Inspected new Training entry, game preparation layout, fatigue check, and disabled start button in the app.
- No new user microphone/camera permissions were granted and no speech was collected. Audio behavior was checked with synthetic PCM and test inputs.

## 10. Follow-up: consonant/word waveforms

- Add “Show waveform” to consonant, word, and general speaking screens, on by default and hideable. Daily practice's “Show sound graph” also defaults on.
- Increase the common plot from 88 to 352 logical pixels (4×). Smaller screens use existing scrolling. Do not amplify input or change the level scale by 4×.
- Keep existing consonant/word recording formats. Read the same recorder's amplitude meter about every 100ms. iOS enables metering on the existing AVAudioRecorder; other supported platforms use the record plugin's amplitude. No additional recorder or microphone stream is opened.
- This graph shows level trends rather than raw PCM oscillations. It differs from daily practice's PCM peak envelope and is not for direct absolute-value comparison.
- Keep the most recent graph in the current app session after recording and reset on the next start. This change does not persist/restore historical consonant/word waveforms during playback.
- Meter failure does not interrupt recording. Stop polling on recording end/service disposal and ignore late replies.

Validation: all 143 tests passed; two waveform tests passed again after test-dependency cleanup. macOS debug build and iOS Swift syntax check passed. Actual iOS/Android microphone levels and device-specific display still need verification.

## 11. Follow-up: observer-timed MPT

[A separate MPT mode](../mpt-measurement.en.md) now records three confirmed single-breath trials and their maximum, with audio, waveforms and exclusion reasons. It uses human onset/offset timing rather than automatic pitch detection. Game records remain separate. This implements the administration workflow; clinical validation is still pending.
