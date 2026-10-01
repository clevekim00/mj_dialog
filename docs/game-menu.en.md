# Games and current navigation

[한국어](game-menu.md) | [English](game-menu.en.md) | [All documents](README.en.md)

<!-- reader-link --> [Read with language tabs](https://clevekim00.github.io/mj_dialog/documents/docs/game-menu.en.html)

Implemented October 1, 2026. This page takes precedence over menu paths in earlier plans.

## Main navigation

**Today → Training → Games → Records → Settings**. Compact windows use bottom navigation; wide windows use left navigation in the same order.

| Menu | Contents |
|---|---|
| Today | Daily practice plan and continuing a session |
| Training | Oral training, consonants, short/long sentences, everyday situations, pacing, comfortable voice and MPT |
| Games | Word speaking game and Gentle voice flight |
| Records | Training, games and MPT, with category filters |
| Settings | Goals, text size, language, recordings and content management |

## Playing

The menu says **“Practise speaking through play.”** It brings together two existing games and does not imply a new therapeutic benefit or score.

- **Games → Word speaking game:** resets previous practice mode before opening words. No time limit is the default. Falling mode remains an option inside the game. Existing recording, waveform, review and pause behavior is preserved.
- **Games → Gentle voice flight:** the bird responds to a comfortable “ah”. There are no collisions or failures, and a round lasts up to 20 seconds. Rest whenever needed. Detected time is not an MPT result.

The previous `Training → Clear speech → Words` and `Training → Comfortable voice practice → Gentle voice flight` entry points have moved to Games. Duplicate game cards have been removed from Training.

## Remaining in Training

- **Training → Oral training:** opens the oral/breathing hub, not a separate top-level destination.
- **Training → Comfortable voice practice → Maximum phonation time (MPT):** observer timing of three confirmed single-breath trials. It is not merged with game scores. Read the [procedure and limitations](mpt-measurement.en.md).
- **Training → Comfortable voice practice → Speak through a sentence:** a visible example sentence with sound-level feedback.
- Word tasks inside daily practice are preserved. Only the separate word game's entry point moves.

## Records and compatibility

The **Games** filter includes both word-game and voice-flight records. Titles and recording content distinguish them. Existing `mode = wordGame` and `feedback.kind = voiceFlight` formats are preserved; old records are not rewritten or deleted. Word-game recording management remains accessible. MPT retains its own **MPT measurement** category.

## Implementation and checks

- `GameMenuScreen`: two choices, duplicate-launch guard and error notice.
- `AdaptiveAppShell`: five destinations and selected-page retention across layout changes.
- `ExerciseMenuScreen`: removes game entry points; retains MPT and oral training.
- `RehabRecordIndex`: includes existing word-game records in the game filter.
- `test/game_menu_test.dart`: mode reset, untimed default, both languages, compact layout, voice-flight entry and preservation of existing records.
- Existing navigation, word-game, MPT and record tests provide regression coverage. These are software checks, not clinical validation.

## Documentation scope

Update Korean and English READMEs, navigation/screen/planning/implementation documents, promotional pages and user guides with current entry points. Every Markdown document links to this current guide. Dated reviews and plans retain their historical facts; the current notice at the top takes precedence for navigation. Archived illustrated guides link to the current guide and carry a change notice. This documentation update does not change the original LICENSE, code identifiers or stored records.
