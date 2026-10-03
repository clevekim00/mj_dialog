# Maximum phonation time (MPT)

[한국어](mpt-measurement.md) | [English](mpt-measurement.en.md) | [All documents](README.en.md)

<!-- reader-link --> [Read with language tabs](https://clevekim00.github.io/mj_dialog/documents/docs/mpt-measurement.en.html)

## Scope

Open **Training → Comfortable voice practice → Maximum phonation time (MPT)**. Automatic voice timing is the default. Prepare once; no onset/offset button presses are needed during phonation. Disable automatic timing to use the existing observer timer. Timing mode stays fixed within a set. Records remain separate from voice games.

Automatic timing estimates acoustic boundaries. It does not verify the vowel “ah”, a single breath, or coughs. Weak/irregular voices and background noise can affect boundaries. This is not a clinically validated test or diagnostic tool and gives no normal/abnormal grade.

## Instructions

1. Rest in a quiet place and keep the device, microphone distance and environment consistent. Select fatigue and confirm readiness.
2. Select **Prepare recording** once. Stay quiet for about 1.5 seconds while background sound is checked.
3. After **Ready**, take a full breath and sustain a comfortable “ah” on one exhalation. Do not strain.
4. A large fixed timer starts when voice is detected and stops automatically after it ends. Detection confirmation delays are not added to the measured interval.
5. **Listen to recording**. Confirm only a single-breath trial with no interference and correct boundaries. Exclude extra breaths, coughs or incorrect detection. Check any brief-gap warning carefully.
6. Rest, then repeat preparation, phonation and review. The longest of three confirmed valid attempts is the result, not the sum or average.
7. **Records → MPT measurement** shows automatic estimate/observer timing, duration, inclusion/exclusion and audio. Incomplete sets cannot resume; start a new set.

If automatic detection is difficult, disable **Automatic voice timing** for a new set. A helper can press the existing onset and offset buttons. Stop for discomfort, dizziness or breathlessness. Automation removes timing taps during phonation; preparation and recording review still require confirmation.

## Timing and failures

- One PCM input (16 kHz, 16-bit mono) supplies both recording and analysis. Boundaries use actual audio timestamps in roughly 64 ms frames. A 0.1-second display does not imply that accuracy.
- Calibration lasts 1536 ms. The onset threshold is 10 dB above background, clamped to -55 through -20 dBFS. A voiced signal lasting 192 ms confirms onset, backdated to its first frame. These are initial product settings, not clinical standards.
- Offset is confirmed after 640 ms without detected voice. Duration ends at the last voiced frame, excluding trailing silence. Brief gaps may remain inside the interval; detected gaps are stored for review.
- Voice/loud noise during calibration, or no detected onset within 20 seconds after calibration, ends an excluded attempt. Check the environment or use manual timing rather than forcing louder voice.
- Leaving the app, missing input, input errors or the 120-second recording cap excludes the attempt. This cap is a memory limit, not a clinical MPT cutoff.
- Attempts save as unreviewed. They never count toward a final result without review. Save failures block new attempts and retry with the same attempt and original boundaries.

## Storage and validation

`RehabSession.feedback.kind = mpt`. Automatic timing uses `version = mpt-auto-reviewed-3-trials-v1`, `timingMethod = automatic-acoustic` and `detectorVersion = adaptive-voice-v1`, with detector settings. Manual timing retains `mpt-observer-3-trials-v1` / `observer-stopwatch`. Each trial preserves duration, recording offsets, method, gap flag, acceptance and exclusion reason. Legacy records default to observer timing. `maximumMs` stays null until three valid attempts are confirmed. MPT remains separate from ordinary practice resume, pronunciation comparisons and daily practice totals.

Tests cover automatic boundaries, trailing-silence exclusion, short-sound rejection, gaps, silence, noisy calibration, manual timing, save retry and permission errors. Real-device and clinical comparison against expert timing, including weak voices and noisy environments, remains necessary.

## Sources

[ASHA adult dysarthria assessment](https://www.asha.org/practice-portal/clinical-topics/dysarthria-in-adults/) includes sustained vowel prolongation. The [PhenX adult MPT protocol](https://s3.amazonaws.com/phenx-portal/public/phenx-content/consensus/speech_hearing/14_Voice_Impairments_MPT.pdf) informs the single-breath vowel and longest-of-three principles. Automatic thresholds, delays and UI are product decisions; these sources do not validate this detector.
