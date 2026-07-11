# React Mouth Speech Exercise 3D

Original React + TypeScript + React Three Fiber prototype for a premium speech therapy and oral motor exercise guide.

This is a general exercise guide, not medical advice. Consult a speech-language pathologist or doctor if needed.

## Install

```bash
cd react_mouth_exercise
npm install
npm run dev
```

## Build

```bash
npm run build
npm run preview
```

## Folder Structure

```text
src/
  components/
    ProfessionalAvatarStage.tsx
    ProfessionalInstructorAvatar.tsx
    OralAlternatingExercise3D.tsx
    MouthSpeechExercise3D.tsx
    MouthExercise3D.tsx
    ExerciseControls.tsx
  data/
    avatarModel.ts
    facialRig.ts
    koreanVisemes.ts
    oralExerciseLibrary.ts
    oralAlternatingSteps.ts
    speechExerciseSteps.ts
    mouthExerciseSteps.ts
  hooks/
    usePronunciationAudio.ts
    useExercisePlayer.ts
    useExerciseAnimation.ts
  App.tsx
  main.tsx
  styles.css
```

## Speech Exercise Steps

`OralAlternatingExercise3D` adds original continuous and alternating oral movement practice with synced pronunciation audio:

- Neutral face
- 아 sound
- 이 sound
- 우 sound
- 아-이-우 continuous sequence
- 파-타-카 alternating articulation
- 라-라-라 tongue-tip movement
- Jaw left-right movement
- Tongue left-right movement
- Relax

The audio prototype uses `window.speechSynthesis` with `ko-KR` when no `audioSrc` is provided. To use recorded audio, place original files in `public/audio/` and set `audioSrc` in `oralAlternatingSteps.ts`.

## Premium Rehabilitation Avatar Requirement

All exercise viewers use `ProfessionalAvatarStage`, which loads a professionally modeled GLB through `ProfessionalInstructorAvatar` when a model is available.
Until that model is ready, the viewer uses `FallbackInstructorAvatar` so the exercise screens remain usable during development.

Default model path:

```text
public/models/speech_therapy_instructor.glb
```

Alternative model path:

```bash
VITE_INSTRUCTOR_AVATAR_URL=/models/my_professional_avatar.glb npm run dev
```

If the GLB is missing, the viewer renders the lightweight fallback avatar. The fallback is temporary and should be replaced by the production GLB before release.

The production model should be a completely original young-adult virtual speech therapist character with refined proportions, visible neck and shoulders, detailed lips, teeth, tongue, mouth cavity approximation, eyelids, eyelashes, brows, ears, hairline, layered dark-brown hair, PBR skin, natural blush, and speech-therapy appropriate styling. It must not copy any specific artist, studio, film, franchise, or existing character.

## Korean Viseme And Coarticulation Architecture

`src/data/koreanVisemes.ts` defines reusable Korean viseme poses for:

- vowels: `아`, `야`, `어`, `여`, `오`, `요`, `우`, `유`, `으`, `이`
- consonants: `ㅁ`, `ㅂ`, `ㅍ`, `ㄷ`, `ㅌ`, `ㄴ`, `ㄹ`, `ㄱ`, `ㅋ`, `ㅇ`, `ㅅ`, `ㅈ`, `ㅊ`, `ㅎ`

`blendVisemes(from, to, amount)` is the starting point for coarticulation. In the current prototype, `useOralAlternatingPlayer` uses the viseme table for `아`, `이`, `우`, `파-타-카`, and `라-라-라`. A production lip-sync system can replace the current phase timing with phoneme timestamps from recorded audio, SpeechSynthesis marks, Whisper alignment, OpenAI Realtime API events, Azure Speech, Google Speech, or Apple Speech.

## Professional Exercise Library

`src/data/oralExerciseLibrary.ts` adds structured exercise metadata for future menus and cloud exercise packs. Each exercise contains:

- `titleKo`
- `descriptionKo`
- `difficulty`
- `durationSeconds`
- `targetMuscleKo`
- `recommendedRepetitions`
- `restIntervalSeconds`
- `audioCueKo`
- `visualCueKo`

Included modules cover wide mouth opening, lip protrusion, lip spreading, cheek inflation, tongue protrusion, tongue elevation, tongue lateralization, alternating motion, and breathing synchronization.

## Earlier Speech Exercise Steps

- Neutral face
- Deep breath preparation
- Open mouth wide
- Close mouth gently
- Smile wide
- Lip rounding "oo"
- Tongue out and back
- Tongue left and right
- Puff cheeks
- Relax

## Morph Target Preparation

`MouthSpeechExercise3D` accepts props:

```tsx
<MouthSpeechExercise3D
  autoPlay
  loop
  defaultSpeed={1}
  onStepChange={(index, id) => console.log(index, id)}
  onComplete={() => console.log("complete")}
/>
```

The future-ready facial rig is defined in `src/data/facialRig.ts` and includes:

- `mouthOpen`
- `mouthClose`
- `jawOpen`
- `jawForward`
- `jawLeft`
- `jawRight`
- `lipWide`
- `lipRound`
- `lipSmile`
- `lipPress`
- `lipCornerUp`
- `lipCornerDown`
- `lipCornerRaise`
- `lipCornerLower`
- `cheekPuff`
- `cheekRaise`
- `tongueOut`
- `tongueUp`
- `tongueDown`
- `tongueLeft`
- `tongueRight`
- `tongueCurl`
- `tongueTipUp`
- `eyeBlinkLeft`
- `eyeBlinkRight`
- `eyeLookLeft`
- `eyeLookRight`
- `eyeLookUp`
- `eyeLookDown`
- `browRaise`
- `browLower`
- `noseWrinkle`
- `neckRotate`
- `headTilt`

Use `arkitBlendshapeMap` as the adapter starting point for ARKit-compatible GLB/VRM/Ready Player Me/MetaHuman-style rigs.

The GLB should expose these morph target names directly, or ARKit-compatible names that can be mapped through `arkitBlendshapeMap`.

To add or replace the Blender-made GLB instructor:

1. Model and rig the character in Blender, Maya, or equivalent DCC software.
2. Create blendshapes for the rig names above.
3. Export as GLB with PBR materials, compressed textures, and clean hierarchy.
4. Place it at `public/models/speech_therapy_instructor.glb`, or set `VITE_INSTRUCTOR_AVATAR_URL`.
5. Keep `ExerciseControls`, exercise data, audio hooks, and `FacialRigState` unchanged.
6. For VRM, Ready Player Me, Live2D, or MetaHuman-style models, create an adapter that converts `FacialRigState` to the target runtime's parameter names.

## Embedding Notes

- Keep `Canvas` DPR capped, as this component does with `dpr={[1, 2]}`.
- Prefer baked textures and PBR materials for a lightweight premium educational style.
- Use compressed GLB assets with Draco or Meshopt and KTX2 textures when replacing the fallback avatar.
- Pause animation when the component is offscreen in production apps.
- If embedding in Flutter or a native app, host this Vite build as a web view or port the same morph target names into the native 3D renderer.
- Use lazy loading and code splitting for heavy avatar viewers.
- Target 60 FPS desktop and 30-60 FPS tablet/mobile by limiting DPR, shadows, post-processing, and mesh counts.

## Current Limitations

- No production character model is bundled. A professional GLB/VRM avatar must be provided separately before release.
- True anatomical accuracy, muscle simulation, physically simulated hair, HDRI assets, KTX2 textures, and studio voice packs require external 3D/audio asset production.
- The current SpeechSynthesis audio is a prototype fallback. Production pronunciation training should use original recorded Korean audio files with phoneme timing metadata.
