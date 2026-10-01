# Maximum phonation time (MPT)

[한국어](mpt-measurement.md) | [English](mpt-measurement.en.md) | [All documents](README.en.md)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](game-menu.en.md). Earlier plans and reviews below retain their dated context.

## Scope

Open Training → Comfortable voice practice → **Maximum phonation time (MPT)**. This has its own screen and record category, separate from voice play. A helper or examiner presses buttons at actual voice onset and offset: **observer timing**. A person checks the breath and interval instead of relying on automatic detection that may miss weak or irregular voices.

This implements a way to record an MPT procedure, not a clinically validated automated test or diagnostic device. It does not replace professional assessment or provide normal/abnormal grading, recovery scores or sex-specific normal ranges. A professional should interpret clinical results.

## Instructions

1. Sit comfortably in a quiet place. Keep the device, microphone distance and environment consistent. A helper or examiner gives instructions and operates the timer.
2. Choose fatigue, confirm sufficient rest and that a helper is ready. Postpone if tired.
3. Select **Prepare recording**. Preparation time is not itself MPT.
4. Take a full breath and sustain “ah” on one exhalation as long as comfortably possible at your usual pitch and loudness. Do not strain.
5. The helper selects **Voice onset · Start timer** when sound actually begins, then **Voice offset · Stop timer** when it ends. Do not include waiting or inhalation.
6. Review the recording and waveform. Select **Confirm valid trial** only after checking one breath, no cough or interference, and correct start/end timing. Exclude another breath, mistimed buttons or poor recordings.
7. Rest sufficiently, then repeat until 3 valid trials are confirmed. The **longest of the three** is the final MPT, not their sum or average.
8. In Records → **MPT measurement**, review each attempt, inclusion/exclusion, the final result and recordings. Leaving an unreviewed attempt preserves it but does not count it. Incomplete sets cannot be resumed; start a new set if needed.

Stop immediately for pain, dizziness or breathlessness. Do not use this as an endurance competition or daily repetition target. Discuss suitability and frequency with a clinician.

## Timing and failure handling

- A monotonic `Stopwatch` measures between button presses, displayed to 0.1 seconds. Display precision is not accuracy: observer reaction and button timing affect the result.
- Uses the existing single PCM input (16 kHz, 16-bit mono). Full audio including preparation, waveform and recording offsets at button presses are preserved. The waveform shows input level, not pronunciation accuracy.
- Automatic VAD, pitch detection and accumulated game detection time do not calculate MPT. Human confirmation does not automatically verify voice content or breaths.
- Backgrounding the app or losing microphone input excludes that attempt. Zero duration or no recorded interval between onset/offset also prevents confirmation.
- Reaching the existing 120-second recording cap stores an **excluded attempt**, not a 120-second MPT result. This is a memory limit, not a clinical protocol time limit.
- Each attempt is saved unreviewed first, then updated on confirmation. `maximumMs` remains null until 3 valid trials are accepted. Invalid attempts remain in the audit trail and can be retried.
- Audio/record storage failure blocks new attempts and offers retry. The same attempt ID and original stop time are preserved. Retry before closing the app when a save error remains. Recovery of unsaved in-memory data after force quit is not guaranteed.

## Storage and validation

Uses the existing `RehabSession` store with `feedback.kind = mpt`, `version = mpt-observer-3-trials-v1`, and `timingMethod = observer-stopwatch`. Attempts store ID, timer duration, recording onset/end offsets, acceptance and exclusion reason. `maximumMs` is calculated only for exactly 3 confirmed valid attempts. Incomplete sets are `partial`; finished sets are `completed`. These records do not link to ordinary sentence-practice resume/comparison. Existing recording playback, sharing and deletion remain available. MPT attempts are excluded from daily practice totals.

`test/mpt_test.dart` covers three-trial maximum, incomplete sets, interruption, input failure, save retry, denied microphone permission and record separation. These tests are not clinical validation. Before release, verify real-device recording, audio latency, background interruption and error against expert manual timing.

## Source

The [PhenX adult MPT protocol](https://s3.amazonaws.com/phenx-portal/public/phenx-content/consensus/speech_hearing/14_Voice_Impairments_MPT.pdf) describes a sustained /a/ on one breath at comfortable pitch and loudness, taking the longest of three attempts. This implementation follows those administration principles. Recording review, failure handling, the 120-second memory cap and app UI are product decisions. The source's normal ranges are not used for app grading.
