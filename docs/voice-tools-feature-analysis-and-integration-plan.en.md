# Voice Tools Feature Analysis and Speech Rehab Integration Plan

[한국어](voice-tools-feature-analysis-and-integration-plan.md) | [English](voice-tools-feature-analysis-and-integration-plan.en.md) | [All documents](README.en.md)

<!-- reader-link --> [Read with language tabs](https://clevekim00.github.io/mj_dialog/documents/docs/voice-tools-feature-analysis-and-integration-plan.en.html)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](game-menu.en.md). Earlier plans and reviews below retain their dated context.

Date: 2026-08-24
App reviewed: [Voice Tools — App Store](https://apps.apple.com/us/app/voice-tools/id1447495900)
Developer: DevExtras Ltd.

## 1. Conclusion

Voice Tools' analysis features fit Speech Rehab's dysarthria self-practice direction. However, the original also targets gender-associated pitch display and transgender voice training. Adapt features to dysarthria goals rather than copying that framing:

- Pitch analysis → Voice height/stability practice.
- Level analysis → Comfortable, steady loudness.
- Reference tones → Match a target tone.
- Spectrogram → Observe waveform/timbre.
- Balanced sentences → Korean phonetically balanced reading.
- Latest ten seconds → Listen and compare immediately.
- Statistics → Voice-analysis results.
- Gender-associated pitch percentages → Omit; use personal reference ranges.

Place the requested pronunciation-wave analysis initially under phonation training. Pitch, level, duration, and spectrum describe voice height, intensity, stability, and quality; they alone cannot determine consonant/vowel accuracy. In pronunciation menus, use them only as supporting measures with target/user alignment, phoneme recognition, formant, or other acoustic comparison.

## 2. Research scope and evidence

### Confirmed in official material

App Store description/version history or the developer's privacy policy confirms:

- Real-time pitch and graphs.
- Pitch-related range bands.
- Reference-tone playback and imitation.
- Real-time level analysis.
- Phonetically balanced reading sentences.
- Latest-ten-second recording/playback.
- Spectrogram.
- Mean/median pitch and level results.
- Sensitivity to environmental noise.
- On-device real-time processing by default.
- Saving to files, voice bank, or history only when chosen.

Official sources:

- [Apple App Store](https://apps.apple.com/us/app/voice-tools/id1447495900)
- [DevExtras Voice Tools](https://devextras.com/voicetools/)
- [DevExtras privacy policy](https://devextras.com/privacy-policy/)
- [Google Play](https://play.google.com/store/apps/details?id=com.DevExtras.VoiceTools)

### Supplemented by screenshots/external descriptions

- Colored pitch-range bands.
- A note grid for choosing reference frequencies.
- Real-time dB graph.
- Mean/median pitch and level statistics.
- Background-noise statistics.

These interpret official descriptions together with store screenshots. Not all internal settings, algorithms, or thresholds are public.

## 3. Feature inventory

| No. | Original feature | Description | Rehabilitation use | Evidence |
|---:|---|---|---|---|
| 1 | Real-time pitch | Estimate F0 from microphone input; show Hz and time graph | Sustained vowels, comfortable pitch, sentence intonation/stability | Official |
| 2 | Range bands | Background bands show pitch regions; original uses gender-associated ranges | Personal baseline/target range and excursions | Official |
| 3 | Reference tones | Play a frequency/note for imitation | Vowels, glides, target imitation | Official |
| 4 | Real-time level | Show microphone strength in dB/relative graph | Quiet voice, fading sentence endings, steady intensity | Official |
| 5 | Spectrogram | Frequency energy over time; harmonics, noise, onset/sustain | Observe phonation/quality; not a stand-alone pronunciation score | Version history |
| 6 | Balanced sentences | Reading prompts with broad sound coverage | Sample Korean consonants/vowels and prosody | Official |
| 7 | Latest-ten-second playback | Brief recent audio and immediate replay | Self-listening, before/after comparison, repetition | Official |
| 8 | Summary statistics | Pitch/level values and distributions, including mean/median/noise | Reference changes for same user/task within/across sessions | Description + screenshots |
| 9 | Noise guidance | Explain noise/microphone effects; recommend quiet/external mic | Reject low-confidence results and guide retry | Official |
| 10 | Session privacy | Default real-time audio processed in local memory, not automatically saved/sent | Local-first sensitive voice processing | Official |
| 11 | Optional file/history/voice bank | Explicit save, add to bank/history, or email | Baselines, comparison, calendar connection | Policy |
| 12 | Ad removal purchase | Ad-supported free app and removal purchase | Not a treatment feature; omit | Official |

## 4. Individual menu proposals

Expose relevant features separately for understandable purposes while sharing one analysis engine.

### 4.1 Real-time pitch

- Route: `/voice_pitch`.
- Show current Hz, personal range, live line, stable-interval ratio.
- Tasks: comfortable `아` for 3/5 seconds, short sentence.
- Save valid-F0 ratio, median/range/variability.
- Never classify male/female voice or normal/abnormal pitch.
- Entry: Phonation training > Voice pitch.

### 4.2 Match a target tone

- Route: `/target_tone`.
- Reference playback, target Hz/note, current pitch, tolerance.
- Listen → comfortable vowel → review.
- Initially generate targets only within a comfortable personal range.
- Entry: Phonation training > Match a target tone.

### 4.3 Voice level

- Route: `/voice_volume`.
- Relative-level graph, current range, sentence-ending change.
- Tasks: sustained vowel, counting, short sentence.
- Save calibrated relative dBFS, median, spread, time in range.
- Do not claim accurate smartphone SPL; label relative level before device calibration.
- Entry: Phonation training > Voice level.

### 4.4 Voice waveform analysis

- Route: `/voice_spectrogram`.
- Waveform, spectrogram, pitch/level tracks, playback position.
- Tasks: sustained `아`, gentle onset, glides, short sentences.
- Beginner: waveform/pitch/level only.
- Advanced: spectrogram, harmonics, unvoiced intervals.
- Entry: Phonation training > Voice waveform analysis.

### 4.5 Korean balanced sentences

- Route: `/balanced_sentences`.
- Sentence, principal sounds, reading recording, STT, immediate replay.
- Clinically review balanced onsets/vowels/codas and articulation places.
- Short → long → functional everyday sentences.
- Reuse `PracticeContentService` and `PracticeScreen`.

### 4.6 Ten-second quick recording

- Route: `/quick_voice_recording`.
- Up to ten-second ring buffer or explicit recording; immediate replay/re-record.
- Do not save by default.
- Optional Save to history / Save as reference / Delete.
- Extend `AudioRecorderService` and `AudioPlayerService`.

### 4.7 Voice-analysis results

- Route: `/voice_analysis_result`.
- Median pitch, comfortable range, relative level, duration, voiced ratio, pitch/level stability, noise quality.
- Compare the previous attempt on the same task.
- Use observational wording (“steadier in this measurement”), not improvement/decline judgments.
- Connect to unified `RehabSession` and calendar details.

### 4.8 My reference voice

- Route: `/voice_bank`.
- Save a chosen recording as reference with title/task/date; alternate playback with the current attempt.
- Local only, no automatic upload; individual/all deletion.
- Extend `RecordingLibraryScreen` into a type-filtered unified library.

### 4.9 Analysis history

- Route: `/voice_analysis_history`.
- Date/task/menu history, trend graphs, calendar links.
- Raw audio optional; summaries may be stored alone.
- Enter through date details in the new unified calendar.

### 4.10 Microphone/noise check

- Route: `/microphone_check`.
- Permission, signal, clipping, noise, sample rate, distance guidance.
- Results: ready / try somewhere quieter / too close to microphone.
- Shared starting step for all real-time analysis menus.

## 5. Placement of pronunciation-wave analysis

### Recommendation

Name it Voice waveform analysis under Phonation training.

Reasons:

1. Waveforms show time/amplitude; spectrograms show time/frequency energy.
2. Pitch/level relate more directly to vocal-fold vibration, breath/voice coordination, and prosody.
3. Consonant/vowel accuracy requires target phoneme, articulation, context, and time alignment.
4. Different spectrogram shapes alone cannot establish errors or treatment effectiveness.

### Phonation measures

- Sustained phonation duration.
- Median F0.
- F0 range/variability.
- Valid voiced-frame ratio.
- Relative-level median/spread.
- Sentence-final level decrease.
- Time to voice onset.
- Noise and confidence.

### Limited reuse in pronunciation practice

- Align target/user waveform playback positions.
- Compare syllable duration and pauses.
- Reference formants in vowel intervals.
- Reference voiced/unvoiced intervals and voice onset.
- Compare intervals when phoneme STT or forced alignment is available.

Present spectrograms as a companion to listening, not a correct-answer graph.

## 6. Gap from current Speech Rehab

| Area | Current state | Needed |
|---|---|---|
| Recording | M4A through `record` and iOS MethodChannel | Live PCM and ten-second buffer |
| Playback | File playback | Ring-buffer replay and A/B reference comparison |
| STT | Sentence recognition/practice | Keep independent from acoustics |
| Pitch | Not implemented | F0 engine and voiced/unvoiced decision |
| Level | Not implemented | RMS, peak, dBFS, clipping, noise floor |
| Spectrogram | Not implemented | Windowing, FFT, magnitude/dB, rendering |
| Target tone | Not implemented | Sine/safe reference generation and playback |
| Results | Text/score-centered `PracticeSession` | `VoiceAnalysisMetrics` and raw-frame summaries |
| Calendar | Separate design stage | Link menus to unified `RehabSession` |
| Breathing/voice | Face/lip/tongue tasks mixed into breathing | Separate breathing from voice analysis |

## 7. Technical design

### 7.1 Shared modules

```text
lib/features/voice_analysis/
  model/
    voice_analysis_frame.dart
    voice_analysis_metrics.dart
    voice_analysis_session.dart
    voice_analysis_task.dart
  provider/
    voice_analysis_provider.dart
  view/
    voice_analysis_menu_screen.dart
    pitch_training_screen.dart
    target_tone_screen.dart
    volume_training_screen.dart
    spectrogram_training_screen.dart
    balanced_sentence_screen.dart
    quick_recording_screen.dart
    voice_analysis_result_screen.dart
    voice_analysis_history_screen.dart
    voice_bank_screen.dart
    microphone_check_screen.dart
  widgets/
    realtime_pitch_chart.dart
    realtime_volume_chart.dart
    spectrogram_painter.dart
    waveform_painter.dart
    analysis_quality_badge.dart
lib/services/audio_analysis/
  audio_input_stream_service.dart
  pitch_detection_service.dart
  volume_analysis_service.dart
  spectrogram_service.dart
  tone_generator_service.dart
  audio_ring_buffer.dart
  microphone_calibration_service.dart
  voice_analysis_repository.dart
```

### 7.2 Data flow

```text
Microphone PCM → DC removal/normalization → 20–40ms frames
→ Noise/clipping checks → Parallel F0+confidence / RMS+peak+dBFS / FFT bins
→ Lower-frequency UI sampling → Ten-second ring buffer
→ End-of-session statistics → Optional local save → RehabSession/calendar
```

### 7.3 Models

```dart
class VoiceAnalysisMetrics {
  final double? medianPitchHz;
  final double? meanPitchHz;
  final double? minPitchHz;
  final double? maxPitchHz;
  final double pitchVariability;
  final double voicedFrameRatio;
  final double medianDbfs;
  final double volumeVariability;
  final double noiseFloorDbfs;
  final double clippingRatio;
  final int phonationDurationMs;
  final double analysisConfidence;
}
```

`VoiceAnalysisSession` stores `taskType`, `promptId`, `startedAt`, `duration`, `metrics`, `audioPath?`, `routineSessionId?`, `analysisVersion`, and `deviceCalibrationId?`.

### 7.4 Principles

- Default to median pitch, less sensitive to outliers.
- Exclude low-confidence/unvoiced frames from F0 statistics.
- Show dBFS/relative level, not dB SPL before calibration.
- Separate rendering and analysis rates to reduce UI load.
- Discard unsaved PCM through the ten-second ring buffer.
- Use consistent sample/frame settings across platforms and test device differences.

## 8. Menu architecture

```text
Today's training
  → 15-minute integrated routine
  → Individual training
      → Lip / Tongue / Breathing / Pronunciation
      → Phonation
          → Live pitch / Match tone / Level / Wave analysis
          → Korean balanced sentences / Ten-second recording / Results
      → Voice tools
          → Reference voice / Analysis history / Microphone-noise check
  → Training calendar
```

Every feature is individually available; integrated routines combine a subset. Save individual runs in `RehabSession`, separately labelled from daily 15-minute completion.

## 9. Integration into a 15-minute routine

Using every tool increases complexity/fatigue. Standard routines use a subset; full features remain in individual menus.

| Segment | Feature | Time |
|---|---|---:|
| Safety/microphone | Microphone/noise check | 30 sec |
| Breathing/phonation | Level graph or sustained vowel | 2 min 30 sec |
| Lips/tongue/speech | Existing movement and syllables | 3 min |
| Pronunciation | Balanced words/sentences, quick recording | 4 min |
| Voice/prosody | One pitch/level measure and functional phrase | 4 min |
| Finish | Immediate replay and short results | 1 min |

Foreground one measure matching the main goal rather than pitch, level, and spectrogram together; excessive visual information can increase cognitive load and interfere with performance.

## 10. Development phases

### Phase 1 — Shared audio foundation

- Live PCM, ten-second ring buffer, RMS/peak/dBFS/clipping, F0/confidence, microphone/noise check, result model.
- Acceptance: ten minutes of unsaved continuous analysis without leaks/dropouts; false speech-pitch detection in silence/noise/music within an acceptable range.

### Phase 2 — Independent-menu MVP

- Live pitch, target tone, level, quick recording, results.
- Acceptance: each opens through its own route; failure shows a reason and retry guidance.

### Phase 3 — Spectrogram and content

- Wave analysis, Korean balanced sentences, waveform/playhead synchronization, beginner/advanced views.
- Acceptance: spectrogram does not resemble diagnosis/correct pronunciation and passes speech-language-pathologist review.

### Phase 4 — History and integrated routine

- Reference voice, analysis history, unified `RehabSession`, calendar, and 15-minute voice stage.
- Acceptance: multiple daily individual/integrated records remain distinguishable; deleting audio preserves statistic/calendar consistency.

## 11. Validation plan

### Signal processing

- Pitch error for synthetic 100/150/200/250Hz signals.
- Diverse adult ranges and rough/breathy voices without gender classification.
- False detection in silence, white noise, TV, and music.
- Low level, clipping, microphone distance.
- iOS/Android sample rates and latency.

### Clinical/usability

- No interpretation of pitch/level as normal/abnormal or treatment success.
- No excessive vocal effort to satisfy the graph.
- One-handed operation with unilateral motor impairment.
- One goal per screen and a large stop control.
- Clear lighter-practice/finish options at fatigue 4–5.

### Privacy

- No saving by default.
- Discard buffer on exit.
- Explicit confirmation before saving voice.
- Delete individual/reference/all recordings.
- Separate consent and transfer indication for any future cloud/AI transmission.

## 12. Product decisions

| Item | Decision |
|---|---|
| Individual menus | Adopt |
| Shared pitch/level/spectrogram engine | Adopt |
| Primary waveform placement | Phonation training > Voice waveform analysis |
| Spectrogram in pronunciation | Limited supporting view only |
| Gender-based pitch judgments | Exclude |
| Personal pitch range | Adopt |
| Actual SPL claims | Exclude before calibration |
| Automatic ten-second saving | Exclude; user-selected saving |
| Ads/ad-removal purchase | Exclude as non-treatment features |
| Diagnosis/recovery judgments | Exclude |

## 13. Risks and responses

| Risk | Response |
|---|---|
| Pitch errors in rough/irregular voices | Confidence/voiced ratio; hide unreliable results |
| Device level differences | Relative level, optional calibration, no SPL claim |
| Strain to hit visual targets | Comfortable-voice guidance; stop for pain/throat tightness; range targets |
| Visualization mistaken for effectiveness | Same-condition reference values, observational copy, no diagnosis |
| Spectrogram mistaken for correct pronunciation | Beginner explanation, phonation placement, separate from scoring |
| Sensitive audio accumulation | Memory-first, optional saving, consider local encryption, deletion |
| STT/live-analysis session conflicts | One audio-session coordinator and explicit state machine |

## 14. Final recommendation

Expose independent features but share one real-time engine. Start with microphone check → pitch → relative level → ten-second replay → results; add spectrograms and Korean balanced sentences next.

Place wave analysis in phonation training. Keep pronunciation centered on STT, targets, and recording comparison; use waves only to locate listening positions or observe vowels, duration, and pauses.
