# Improvements Implemented for the Dysarthria Practice App

[한국어](dysarthria-implementation-2026-09-15.md) | [English](dysarthria-implementation-2026-09-15.en.md) | [All documents](README.en.md)

<!-- reader-link --> [Read with language tabs](https://clevekim00.github.io/mj_dialog/documents/docs/dysarthria-implementation-2026-09-15.en.html)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](game-menu.en.md). Earlier plans and reviews below retain their dated context.

2026-09-15 · Implementation based on the [earlier review](dysarthria-app-review-2026-09-13.en.md).

## User flow

From Home, choose **Consonant practice → Onset or coda → Consonant → Syllable/word/sentence**. Choose a goal of 3, 5, or 10 recordings, listen to examples, or record directly. Save recordings on the device first and replay previous recordings of the same item. Show completion at the target count; allow resuming from Home after leaving partway through.

## Improvements

| Area | Implemented behavior |
|---|---|
| Consonant selection | Separate onset/coda; large buttons; underline target syllables; show current position/level |
| Consonant sessions | Finite recording goals; count only saved recordings; restore last item/progress; compare recordings of identical source text and language |
| Recording controls | Fixed bottom record/stop buttons on consonant/sentence screens; block item changes while starting, recording, or saving; save before exiting general practice |
| Evaluation reliability | Remove invented utterances/high scores on recognition failure; label general-practice values only as text match; no scores for free speech/conversation |
| Legacy records | Mark older raw scores as the previous evaluation method and separate them from new text-match statistics; keep unassessed results null |
| Profile | Read onboarding goals/daily time on Home and connect to practice goals; identify unanswered state; check fatigue again for each new sentence session |
| Fatigue | Record post-session fatigue only when entered; offer shorter practice/rest for high fatigue; do not treat missing answers as no change |
| Oral/breathing | Preserve selected repetitions for every exercise; new default 5; include speed in estimated time; add 5 only on explicit user action |
| Oral progress | Autosave start/repetition/step/pause/completion; update the same session; show partial/paused states; restore repetitions, speed, and cumulative active time |
| Word game | No time limit by default; falling mode opt-in; pause/exit protection and background stop; exclude falling events without speech from history/averages |
| Alternative input/conversation end | Keyboard, prepared phrases, explicit microphone labels; prevent late recognition/AI responses from speaking after conversation ends |
| Entry | Use common app navigation even after onboarding |
| iOS recognition | Remove utterance text from debug logs; wait a bounded time for final result/end event; handle late final utterances and callback re-entry |
| Voice-analysis records | Save WAV persistently; delete files only when shared references are gone; separate recording duration from estimated voiced duration; break pitch lines across missing data |

## Content and server analysis

The bundled Korean pack is `2026.09.2`, with 25 targets and 800 items. Removed the template producing incorrect particle combinations. The 500 sentences derive from 125 everyday originals in four time contexts; they are not labelled expert-reviewed. Also fixed older downloaded packs incorrectly taking precedence over newer bundled content.

Default examples are labelled **TTS synthetic speech**. `referenceAudioAsset` can supply a recorded example, but expert reference audio was not produced in this work.

External analysis is requested separately after recording. Display the destination and transmitted items, and require consent for that recording before upload. Implemented overall/per-request timeout, cancellation, and job deletion. Development server access is loopback-only; production enforces HTTPS, short-lived signed tokens, job ownership, result expiry, and upload size/time/request/concurrency limits.

Stopped unvalidated CTC scoring. MFA provides phoneme alignment, leaving scores empty without a validated scoring method. Consonant results permit score display/baseline comparison only when `scoreValidated == true`.

**Production login and token issuance require separate integration.** The default app does not automatically sign in to an external analysis service. See the [server README](../server/pronunciation_analysis/README.en.md) for configuration/authentication.

## Validation

| Check | Result |
|---|---|
| Entire Flutter suite | 121 passed |
| Flutter static analysis | No errors or warnings |
| Analysis-server Python tests | 24 passed |
| Content generation/validation tests | 2 passed |
| macOS debug build | Succeeded |
| iOS Simulator | Latest Swift compilation and Runner linking passed; packaging unconfirmed because copying model assets exhausted disk space |
| Actual screen recheck | Not performed because the Mac was locked; 320/390px and 200% text widget regression tests passed |

Regression coverage includes recognition failure, scoreless records, separation of legacy scores, no-speech game events, stopping while recording startup is pending, save retry, analysis cancellation/no response, delayed final STT, oral repetition retention/resume/late pause, profile loading, large text, and fixed controls.

## Remaining validation and scope

- iOS simulation ran out of space copying Gemma assets after compilation/linking. `BUILD SUCCEEDED` alone was not treated as successful packaging. Only temporary iOS build files from this work were removed; original models and earlier project builds were retained.
- Review content/intensity with actual users with dysarthria and speech-language pathologists. This implementation does not demonstrate treatment effectiveness or clinical accuracy of automatic assessment.
- Verify microphone, camera, slow speech, long pauses, call interruption, and VoiceOver/TalkBack on real iOS/Android devices. Widget tests do not replace device accessibility testing.
- Target time is guidance for recommended volume. No prescription or forced time limit was added to general sentence practice.
- App-level local encryption, OS backup policy, and global retention/deletion settings remain tied to future product policy.
- No external server deployment, login-system implementation, clinical model training, or expert audio production was performed.
