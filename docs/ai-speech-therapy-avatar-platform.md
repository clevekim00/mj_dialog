# AI Speech Therapy Platform: 2D Animation Edition

## Purpose

This project is a professional speech therapy and oral motor rehabilitation platform, not a game. It supports pronunciation training, oral motor exercise, dysarthria support, aphasia rehabilitation support, Korean language learning, and facial muscle exercise.

## Current Implementation Policy

- The app uses 2D tutor animation for exercise screens.
- Three.js, GLB, VRM, and `model_viewer_plus` are not part of the Flutter runtime path.
- The former 3D tongue preview was replaced with a 2D tutor guide.
- macOS audio channel fixes remain in place.
- Future high-quality character assets should be delivered as layered 2D images, Rive, Lottie, or Live2D-compatible assets.

## Production 2D Tutor Target

The production tutor should be an original young adult virtual speech therapist:

- warm, calm, trustworthy, and professional
- medically appropriate, with no fantasy styling or fan-service
- modern Japanese-inspired 2D animation style
- clean line art, painterly soft shading, subtle gradients, and warm lighting
- dark-brown layered hair with subtle secondary motion
- large expressive eyes with eyelids, eyelashes, highlights, blinking, and micro-saccades
- clear mouth, lip, tongue, cheek, eyebrow, and head movement

The character must not copy a specific artist, studio, film, franchise, character, or real person's likeness.

## 2D Layer Contract

Production assets should be split into independently animatable layers:

- back hair
- side hair
- bangs
- face
- neck
- shoulders/body
- eyebrows
- upper eyelids
- lower eyelids
- eyes/iris/highlights
- cheeks/blush
- nose
- upper lip
- lower lip
- mouth cavity
- teeth
- tongue
- foreground hair strands

Flutter currently uses a Canvas-based fallback in:

```text
lib/features/exercise/widgets/animated_exercise_avatar.dart
```

Future production assets can replace this with Rive, Lottie, sprite layers, or Live2D while keeping the same exercise state inputs.

## Korean Mouth Shape Contract

Each pronunciation should map to a 2D mouth drawing or layer state.

Supported vowels:

- `아`, `야`, `어`, `여`, `오`, `요`, `우`, `유`, `으`, `이`

Supported consonants:

- `ㅁ`, `ㅂ`, `ㅍ`, `ㄷ`, `ㅌ`, `ㄴ`, `ㄹ`, `ㄱ`, `ㅋ`, `ㅇ`, `ㅅ`, `ㅈ`, `ㅊ`, `ㅎ`

Recommended 2D mouth states:

- `neutral`
- `openA`
- `wideI`
- `roundU`
- `roundO`
- `closedM`
- `pressedP`
- `tongueTipT`
- `tongueBackK`
- `tongueL`
- `tongueOut`
- `cheekPuff`
- `smile`
- `blink`

Smooth interpolation should happen by crossfading layers, shape keys in Rive/Live2D, or sprite sequence blending.

## Professional Exercise Library

Each exercise module should include:

- title
- description
- difficulty
- duration
- recommended repetitions
- rest interval
- target muscle
- audio cue
- subtitle
- visual cue

The exercise set should cover:

- open mouth
- close mouth
- lip protrusion
- lip spreading
- cheek puff
- tongue out
- tongue left/right/up/down
- tongue circles
- jaw opening
- jaw left-right
- alternating syllables
- breathing exercises
- mirror training

## Screen Layout Direction

The core exercise screen should follow the provided 2D reference direction:

- dark premium medical UI
- large main character area
- current exercise card
- remaining time indicator
- mouth shape guide
- expression preview
- oral exercise preview
- subtitle area
- exercise timeline
- playback controls
- speed and repeat controls
- accessibility/settings entry points

## Audio And Lip Sync

- Never use audio extracted from reference videos.
- Support original recorded audio.
- Use SpeechSynthesis only as a prototype fallback.
- Synchronize audio, subtitle, mouth shape, cheek/tongue movement, and exercise timeline.
- Future alignment sources can include Whisper, OpenAI Realtime API, Azure Speech, Google Speech, or Apple Speech.

## Accessibility And UI Targets

- Korean-first interface
- large playback controls
- captions and pronunciation subtitle
- playback speed control
- mirror mode
- left-handed mode
- high contrast mode
- color-blind safe visual cues
- tablet and hospital kiosk support

## Performance Targets

- 60 FPS target on desktop
- 30-60 FPS target on mobile/tablet
- cache layered raster assets
- prefer Rive/Lottie for complex production animation
- avoid heavy 3D/WebView runtimes for exercise animation
- pause animation when offscreen
