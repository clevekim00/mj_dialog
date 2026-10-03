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

The menu says **“Practise speaking through play.”** It offers three speaking games and does not imply a new therapeutic benefit or score.

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

- `GameMenuScreen`: three choices, duplicate-launch guard and error notice.
- `AdaptiveAppShell`: five destinations and selected-page retention across layout changes.
- `ExerciseMenuScreen`: removes game entry points; retains MPT and oral training.
- `RehabRecordIndex`: includes existing word-game records in the game filter.
- `test/game_menu_test.dart`: mode reset, untimed default, both languages, compact layout, voice-flight entry and preservation of existing records.
- Existing navigation, word-game, MPT and record tests provide regression coverage. These are software checks, not clinical validation.

## Documentation scope

Update Korean and English READMEs, navigation/screen/planning/implementation documents, promotional pages and user guides with current entry points. Every Markdown document links to this current guide. Dated reviews and plans retain their historical facts; the current notice at the top takes precedence for navigation. Archived illustrated guides link to the current guide and carry a change notice. This documentation update does not change the original LICENSE, code identifiers or stored records.

## Syllable adventure run (implemented October 3, 2026)

**Games → Syllable adventure run** is the third game. Choose one of 19 Korean consonants. Add **ㅏ to jump** or **ㅓ to duck**: ㄱ gives 가/거, ㅁ gives 마/머, and ㅇ gives 아/어. Voice controls remain Korean even with the English interface.

Choose Cheese (yellow male domestic shorthair) or Mochi (white female domestic shorthair). Jump and duck even when obstacles are distant. Actions last 1.5 seconds; repeated inputs during an action are ignored. A matching action clears an obstacle after it reaches 75% of its approach.

Three stages contain 12, 16 and 20 obstacles: Sunny meadow, Cloud hills and Starlight trail. Approach times are 6, 5.5 and 5 seconds. A stage takes roughly 1–3 minutes; comfort mode allows more time. Start the next stage explicitly after completion.

Default **Comfort mode** waits indefinitely and permits skipping. In **Challenge mode**, failing to dodge within 3 seconds of arrival causes a collision and stops the run. Each stage provides one initial attempt and two retries. Retrying restarts that stage and resets action counts. After exhausting retries, start a new game or switch to comfort mode. Recognition latency can affect challenge results; buttons remain available.

Use fixed buttons, Up/Space or Down. Pausing or leaving the app stops progress. Changing cats preserves progress; changing consonants or mode starts a new game. Selection controls hide during play and return when paused. Progress and selections are not saved across app launches.

OS Korean speech recognition uses partial results. Only the complete selected syllable triggers an action once per recognition window; substrings inside longer words do not. iOS receives both syllables as contextual hints. Recognition windows restart after free actions too; comfort mode waits through latency. Recognition may require a network and OS permission. Use buttons when recognition is difficult.

Voice actions, button actions and skips are separate. This version shows a round summary only, without entries in Records or saved audio. Recognition is not pronunciation scoring or clinical assessment; the game does not measure MPT.

## Proposed improvements to the existing flight game (not yet implemented)

Its pitch-controlled height and time display provide little goal, choice or reward. Add short star-collection stages, destinations and changing scenery, rest sections between phonations, and wide passages calibrated to comfortable phonation. Do not reward shouting or breath holding. Keep game phonation time separate from formal three-trial MPT measurement.

Use **Choose consonant** to open 19 large selection buttons. Opening the picker pauses play; choosing a different consonant starts a fresh course. The selected pixel cat animates running, jumping and ducking.

### Shared pixel graphics and local execution

All three games share pixel palettes, stepped clouds and tiled ground. The runner displays the selected Cheese or Mochi cat. Voice flight uses a pixel bird and rectangular decorative gates; the word game uses Cheese and pixel scenery. Instructions and practice words retain readable normal fonts.

Per user preference, default local validation is **build and run on macOS**. Build/install on iPad only when the user explicitly requests it.

Keyboard controls: Up/Space jumps; Down ducks. Starting focuses the game, and held keys do not repeat actions. macOS voice startup requests microphone and speech permissions through the supported speech plugin. Startup errors appear beside the fixed controls.

## Continuous word listening and Cheese encouragement

**Keep listening and judge automatically** is on by default. Start/resume once to begin recording and Korean speech recognition. When recognized text remains unchanged for 2.5 seconds, the existing text comparison judges the attempt. The result stays visible for 1.5 seconds before the next recording starts. Exact word matches clear the target. Cheese, the yellow male shorthair, cheers with a small hop and text; no encouragement audio is played. Other recognized words receive a gentle retry message. This is not a clinical pronunciation assessment.

The fixed **Stop listening · Pause** control finishes the current recording and cancels automatic restart. Leaving the app or playing a recording also stops continuous listening. A recording reaching 30 seconds, or a recognition/comparison problem, pauses the session rather than saving endless silent attempts. Recognition and judging have short listening gaps; speak when the listening indicator appears.

Switch continuous listening off while resting to use manual start/judge buttons. Recordings and results follow the existing history policy. Falling words pause during recording and judging.
