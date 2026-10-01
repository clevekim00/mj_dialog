# Refocusing on Home Practice for Adults with Acquired Dysarthria

[한국어](README.md) | [English](README.en.md) | [All documents](../README.en.md)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](../game-menu.en.md). Earlier plans and reviews below retain their dated context.

Implemented on 2026-09-26. Basis: section 5 of `blueprint-acquired-dysarthria-daily-rehab.md`.

## Implemented flows

- Keep four destinations at every screen width: Today / Training / Records / Settings. Preserve the selected destination and record filter when the width changes.
- Start a saved everyday-topic plan or resume interrupted practice from one home-screen button. Remove recommendations based on previous recognition scores.
- Organize training into clear speech, sentences, everyday situations, comfortable voicing, and pace/pauses. Place oral/breathing work under optional preparation, preserving existing locks.
- Rename the word game to word practice and disable the time limit on entry from Training. Keep free conversation as an optional everyday-speaking activity.
- New daily practice contains three tasks: word → related sentence → everyday situation. Provide default Korean/English prompts for asking to rest, asking for help at a hospital, and asking someone to repeat something on the phone. Choose 1–3 repetitions per task and check fatigue before starting or re-entering.
- Support recording, playback, saving, and resuming without a recognition server. Label TTS examples as synthetic speech. Do not count unrecorded tasks as spoken/completed.
- On backgrounding, stop and save recording and enter the paused state. On save failure, block advancement and exit and offer to save the same attempt again.
- Update new sessions by ID in a separate repository. Integrate older word/sentence, consonant, oral/breathing, voice, and conversation records through read adapters without moving or overwriting originals.
- Unified records provide date/type filters, playback, same-sentence comparison, repeating that sentence, and sharing individual files. Exclude free responses and voice measurements from same-sentence comparison.
- When deleting a new session, preserve recordings referenced by another new session. Do not delete files if repository persistence fails; report file-deletion errors separately. Retain management screens for older individual practice types.
- Save text size at 100/125/150/200% in Settings. Request microphone permission when recording rather than blocking entry to the whole app. Move recognition results in existing general practice into an expandable section.

## Implemented scope versus follow-up

This version implements the P0 menu/entry changes and the core P1 practice/save/resume flow. It also includes P2 date selection, pause cues, and recording sharing.

- Keep the existing daily time goal and show it on Home. **This plan is repetition-based**; it does not automatically assemble 5/10/15-minute content or estimate active time.
- Unified records offer a date picker and daily lists. Monthly completion heatmaps, user-defined reference recordings, and CSV/PDF reports are not yet provided.
- Everyday situations use fixed offline questions. AI-conversation turn/goal orchestration and reviewed individualized prescriptions are not included.
- Keep earlier analysis/exercise players. The new daily player and all previous players have not been merged into one execution engine.
- Automatic recovery of an unfinished recording immediately before a forced process exit is not guaranteed. Resume from the last step saved after normal pause, screen exit, or backgrounding.
- The new default phrases are product examples. Clinical effectiveness, individual training dosage, actual iOS/Android microphone behavior, and VoiceOver/TalkBack require separate release validation.

## Validation

- `flutter analyze --no-pub`: passed.
- Entire Flutter suite: 126 tests passed. Korean/English menu checks at 360px with 200% text were added afterward; all 10 related tests also passed.
- New regression coverage: concurrent session preservation, duplicate-save prevention, no overwrite of corrupt storage, unchanged legacy records, exclusion of free responses from comparison, save retry, partial completion with no recording, background stop/save, and record-filter preservation across width changes.
- `flutter build macos --debug --no-pub`: succeeded.
- Manually inspected Home, Training, preparation, and unified records in the macOS app. Existing saved records were visible. No actual patient speech was recorded or shared.

## Screens

![Today](today.png)
![Training](training.png)
![Before starting](prepare.png)
![Records](records.png)
