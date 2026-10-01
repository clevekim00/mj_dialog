# MJ Dialog Improvement Plan

[한국어](improvement-plan.md) | [English](improvement-plan.en.md) | [All documents](README.en.md)

<!-- reader-link --> [Read with language tabs](https://clevekim00.github.io/mj_dialog/documents/docs/improvement-plan.en.html)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](game-menu.en.md). Earlier plans and reviews below retain their dated context.

## Goal

Before expanding the prototype, establish testability, consistent state, and reliable services.

## Recommended order

1. Restore tests
Remove the default counter test that no longer matches the app. Add a rendering smoke test and tests for core services.

2. Unify the state model
Replace screen-level coordination across multiple Riverpod providers with a single session state centered on `ChatController`.

3. Stabilize services
Clearly separate initialization timing, completion events, exception handling, and fallback paths for STT, TTS, and AI responses.

4. Improve parsing and UX
Parse AI responses as JSON instead of using regular expressions. Make user-facing errors easier to understand for each feature.

5. Synchronize documentation and configuration
Align the README, root app configuration, design, and platform descriptions with the code, and reduce analyzer warnings.

## Changes in this iteration

- Unify state and logic in `ChatSessionState` and `ChatController`.
- Change state when TTS completes.
- Clarify STT start/stop flow.
- Strengthen JSON parsing of Gemma responses.
- Embed `ProviderScope` in the app root.
- Replace widget tests to match the current structure.
- Resolve static-analysis warnings.

## Additional changes on 2026-06-01

- Add a practice-selection screen.
- Open today's practice after onboarding instead of history.
- Separate word game, short-sentence reading, long-sentence reading, and free conversation.
- Change the word game to a falling-word UI where speaking removes words.
- Add a dedicated word-game screen.
- Add review of unsuccessful words scoring below 70.
- Add syllables involving more tongue movement and difficulty-weighted selection.
- Summarize difficult sound groups on the dashboard using unsuccessful word-game records.
- Add `PracticeContentService` and `PracticeContentItem`.
- Record mode, content, difficulty, retries, and consecutive successes in `PracticeSession`.
- Support adding, editing, and deleting user sentences in long-sentence mode.
- Separate evaluation prompts by mode with `AiService.evaluatePracticeByMode()`.
- Show mode-specific information in history and the dashboard.
- Add tests for content services, history compatibility, and practice selection.

Validation:

```text
dart analyze
→ No issues found

flutter test
→ All tests passed
```
