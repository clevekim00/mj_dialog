# Integrated changes — October 3, 2026

[한국어](release-notes-2026-10-03.md) | [English](release-notes-2026-10-03.en.md) | [All documents](README.en.md)

## What changes for users

SpeechBridge supports repeated home practice for adults with acquired dysarthria. Navigation is **Today → Training → Games → Records → Settings**. This summary covers earlier implementation and the accumulated uncommitted work. Prefer the current linked feature documents over historical plans.

| Feature | Current behavior | Details |
|---|---|---|
| My sentences | Type or use photo-library/camera/file OCR → verify text → two recordings per dated pair → individual AI feedback and listening/comparison | [Sentence design](sentence-repeat-and-mouth-video-plan.en.md) |
| Long input | Removes the former 30-sentence/500-character limits; next-step controls remain accessible with long OCR lists | [Input and OCR](sentence-repeat-and-mouth-video-plan.en.md) |
| Ease tension | Dedicated training and contextual guidance for rest and short phrases | [Comfort guidance](sentence-repeat-and-mouth-video-plan.en.md) |
| Permissions and layout | Photo/camera/microphone guidance, settings links, macOS speech permissions, accessible controls with expanded waveforms | [Implementation scope](sentence-repeat-and-mouth-video-plan.en.md) |
| Games | Word speaking, Syllable adventure run, Gentle voice flight | [Game guide](game-menu.en.md) |
| Cheese/Mochi runner | Yellow male Cheese or white female Mochi, free jump/duck, three stages of 12/16/20 obstacles, comfort/challenge modes, two retries in challenge mode | [Runner rules](game-menu.en.md) |
| Continuous word listening | Start once → unchanged recognized text for 2.5 seconds → comparison → 1.5-second result → next recording. A 30-second cap/errors pause the session; fixed stop control and visual Cheese encouragement | [Continuous listening](game-menu.en.md) |
| Automatic MPT | Prepare once → 1.5-second noise check → automatic onset/offset → audio review. Excludes trailing confirmation silence; longest of three valid trials | [Timing and limitations](mpt-measurement.en.md) |
| Training availability | Oral/breathing exercises open by default; per-exercise server policy structure | [Management API status](training-availability-and-server.en.md) |

## Records and server

- Sentences preserve revisions and dated recording pairs. AI requests are per recording with upload/retention disclosure. Text differences are not clinical pronunciation scores or diagnoses.
- The sentence-analysis server provides job submission/status/processing/deletion, owner checks, consent, idempotency, file validation and local Whisper integration. Server/model configuration is required. Production identity issuance, management UI and a multi-process queue remain separate work. [Server guide](../server/pronunciation_analysis/README.en.md).
- Word-game recordings use existing history rules. The runner does not persist audio or stage progress. MPT remains separate from daily practice and game results.
- Automatic MPT estimates acoustic boundaries; it does not verify the vowel, breath or cough. Only reviewed valid attempts count. Legacy observer-timed records remain readable.

## User and publishing materials

[Illustrated guide](https://clevekim00.github.io/mj_dialog/user-guide.en.html) · [About the app](https://clevekim00.github.io/mj_dialog/promotion.en.html) · [Tabbed document home](https://clevekim00.github.io/mj_dialog/documents.en.html). Korean is the default; English tabs open corresponding content. GitHub README cannot host arbitrary dynamic tabs, so the document website provides them.

The `eli5` guide uses large illustrations and short steps. Illustrations explain features; they are not screenshots. User materials and technical documents have Korean and English versions.

## Verification and remaining scope

Automated coverage includes continuous listening restart/stop/silence, stale STT results, runner stages/retries, PCM-based MPT boundaries, manual MPT compatibility, OCR input, permissions and save failures. Document builds, bilingual/tab/link checks and static analysis are part of validation. macOS debug build/run is the default; iPad builds/installations happen only on request.

Automatic tests do not establish MPT accuracy for weak/noisy voices, every physical-device permission/audio combination or clinical validity. This does not indicate completed app-store review, signing or production-server deployment. A GitHub main push triggers the existing Pages workflow to publish the document site.

Pre-push verification: **212 Flutter tests passed** and **37 analysis-server tests passed**. The latest macOS debug build/run and automatic MPT screen entry were verified.
