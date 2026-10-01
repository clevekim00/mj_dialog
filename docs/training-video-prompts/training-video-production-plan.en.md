# Oral, alternating-movement, and breathing video production and Higgsfield prompt specification

[한국어](training-video-production-plan.md) | [English](training-video-production-plan.en.md) | [All documents](../README.en.md)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](../game-menu.en.md). Earlier plans and reviews below retain their dated context.

> Updated 2026-09-30: for current implementation, video approval, waveforms, and the distinction between phonation play and MPT, prioritize the [additional design and implementation document](../implementation-2026-09-30/README.en.md). The plan below is preserved as a historical record.

Created: 2026-08-25

## 1. Purpose

Produce short silent demonstration loops for the 46 exercises in `docs/breathing-and-oral-exercises.md`. Videos show movement only; Flutter separately displays instructions, repeat counts, safety copy, and speed.

The English prompts are production drafts: combine the shared prefix with each exercise prompt in Higgsfield. Medical or speech-rehabilitation professionals must approve the demonstrated movements before videos are bundled. Korean syllables remain unchanged because they identify the target sounds.

## 2. Production specification

| Item | Specification |
|---|---|
| Character | Same adult female 2D rehabilitation guide as `assets/images/ai_speech_2d_tutor.png` |
| Aspect ratio | 16:9 |
| Source output | Recommended 1920×1080 |
| App delivery | 1280×720 MP4, H.264 |
| Frame rate | Consistent 24 or 30 fps across all videos |
| Duration | 4–8 seconds |
| Audio | None |
| Camera | Locked; no zoom, pan, or cuts |
| Loop | Natural loop with identical neutral first/last posture |
| Text | No generated letters, numbers, logos, or captions |
| Safe area | Keep key face/mouth/chest motion within central 70% |

## 3. Shared Higgsfield prompts

### 3.1 Frontal face close-up `FACE_PREFIX`

```text
Use the supplied reference image as the exact character reference. Keep the same adult Korean female 2D rehabilitation therapist, the same face, dark ponytail, white clinician uniform, soft clean cel-shaded illustration style, and warm speech-therapy clinic background. Front-facing head-and-shoulders close-up, locked camera, symmetrical framing, head and jaw stable unless the requested exercise requires jaw motion. Show the lips and tongue large and unobstructed. Perform one slow, gentle, anatomically plausible demonstration cycle, then return to the exact neutral starting pose for a seamless loop. Silent video, no speaking audio, no text, no captions, no logo, no UI, no camera movement.
```

### 3.2 Side oral cutaway `CUTAWAY_PREFIX`

```text
Create a clean non-graphic 2D clinical education animation matching the supplied therapist reference style. Show a stable side-profile cutaway of the mouth with lips, upper and lower teeth, tongue, hard palate, soft palate, and cheeks clearly separated by calm educational colors. Locked camera, anatomically plausible proportions, no saliva, no gore, no photorealism. Animate only the requested tongue or mouth movement slowly and clearly, then return to the exact neutral starting pose for a seamless loop. Silent video, no text, no labels, no arrows, no logo, no UI, no camera movement.
```

### 3.3 Upper-body breathing `BODY_PREFIX`

```text
Use the supplied reference image as the exact character reference. Keep the same adult Korean female 2D rehabilitation therapist, same face, dark ponytail, white clinician uniform, and clean warm clinic. Seated upright upper-body view from the front at a slight three-quarter angle, hands resting comfortably where specified, shoulders relaxed, locked camera. Demonstrate one calm and anatomically plausible breathing cycle with subtle chest and abdomen motion, then return to the same neutral pose for a seamless loop. Silent video, no text, no captions, no logo, no UI, no dramatic body motion, no camera movement.
```

### 3.4 Silent syllable demonstration `PHONEME_PREFIX`

```text
Use the supplied reference image as the exact character reference. Keep the same adult Korean female 2D rehabilitation therapist, face, dark ponytail, white clinician uniform, and clean cel-shaded style. Extreme front-facing mouth and lower-face close-up, locked camera, stable head, clear lips, teeth, jaw, and visible tongue tip. Silently articulate the requested Korean syllable sequence with distinct, exaggerated but natural mouth placements and even timing. Finish in the exact neutral starting pose for a seamless loop. No generated audio, no text, no phonetic symbols, no captions, no logo, no UI, no camera movement.
```

### 3.5 Shared negative prompt

```text
photorealistic surgery, gore, saliva strands, deformed mouth, duplicate tongue, forked tongue, extra teeth, missing teeth, warped lips, asymmetrical face unless requested, head turning, camera shake, zoom, scene cut, talking audio, written words, subtitles, numbers, watermark, logo, UI, hands covering the mouth, exaggerated pain, choking, coughing
```

## 4. Fourteen tongue videos

Prepend the indicated shared prefix to each exercise prompt.

| File | Type | Higgsfield exercise prompt | Default app caption (English translation) |
|---|---|---|---|
| `tongue_01_vertical.mp4` | `FACE_PREFIX` | Slowly extend the tongue straight forward, move the tongue tip upward toward the upper lip, then downward toward the lower lip, and return to neutral. Keep the head still and keep the movement centered. | `Extend your tongue and move it up and down.` |
| `tongue_02_touch_lips.mp4` | `FACE_PREFIX` | Open the mouth comfortably. Touch the upper lip with the tongue tip, return to center, touch the lower lip, then return to neutral. Do not move the head. | `Alternate touching your upper and lower lips with your tongue tip.` |
| `tongue_03_lip_corners.mp4` | `FACE_PREFIX` | Extend the tongue slightly and touch the viewer-left lip corner, return to center, then touch the viewer-right lip corner and return. Keep the jaw and head stable. | `Alternate touching both corners of your mouth with your tongue tip.` |
| `tongue_04_lip_circle.mp4` | `FACE_PREFIX` | Extend the tongue and trace one slow complete circle around the outside edge of the lips, pause at center, then trace one circle in the opposite direction and return to neutral. | `Slowly circle your lips in both directions.` |
| `tongue_05_soft_palate_click.mp4` | `CUTAWAY_PREFIX` | Lift the back of the tongue gently toward the soft-palate area, make a controlled contact-and-release motion, then return to the resting tongue position. Show one slow cycle that can be sped up by the app. | `Raise the back of your tongue; slowly touch and release.` |
| `tongue_06_palate_sweep.mp4` | `CUTAWAY_PREFIX` | Place the tongue tip directly behind the upper front teeth, then sweep the tongue backward along the roof of the mouth and lower it gently to the resting position. | `Move your tongue backward along the palate from behind your upper teeth.` |
| `tongue_07_hard_palate_hold.mp4` | `CUTAWAY_PREFIX` | Open the jaw comfortably, not excessively. Press the broad tongue gently against the hard palate, hold visibly for two seconds, release, and return to neutral. | `Rest your tongue against the palate and hold comfortably.` |
| `tongue_08_resistance.mp4` | `CUTAWAY_PREFIX` | Clinical supervision demonstration only. Show a stationary flat tongue depressor outside the lips providing very light resistance while the tongue presses forward, then gently to each side. No force, no deep insertion, no self-use gesture. | `Use light resistance only with professional guidance.` |
| `tongue_09_monkey_lips.mp4` | `FACE_PREFIX` | Keep the lips softly closed. Move the tongue inside the mouth to push the upper lip outward from behind, return, then push the lower lip outward from behind, creating a gentle monkey-face shape, then relax. | `Push inside the upper and lower lips alternately with your tongue.` |
| `tongue_10_molars.mp4` | `CUTAWAY_PREFIX` | Move the tongue tip to touch the left back molar area, return to center, then touch the right back molar area and return. Keep the jaw still. | `Alternate touching both back molars with your tongue tip.` |
| `tongue_11_trace_teeth.mp4` | `CUTAWAY_PREFIX` | Use the tongue tip to trace each upper tooth from one side to the other, then trace the lower teeth back in the opposite direction, like checking the teeth one by one. | `Trace your upper and lower teeth in order with your tongue tip.` |
| `tongue_12_cheek_press.mp4` | `FACE_PREFIX` | Keep the lips closed. Press the tongue into the inside of the viewer-left cheek so a small rounded bulge appears, return to center, then repeat on the viewer-right cheek and relax. | `Push against the inside of each cheek alternately.` |
| `tongue_13_clock_click.mp4` | `CUTAWAY_PREFIX` | Demonstrate a gentle clock-like tongue click: lift the tongue tip to the alveolar ridge behind the upper front teeth, create contact, release cleanly, and return to neutral in an even rhythm. | `Try a tick-tock sound by touching and releasing your tongue tip.` |
| `tongue_14_tongue_click.mp4` | `FACE_PREFIX` | Open the lips slightly and demonstrate a clear gentle tongue-click calling motion, repeating three evenly paced contact-and-release cycles, then return to a relaxed mouth. | `Slowly imitate a tongue click.` |

## 5. Twelve lip videos

| File | Type | Higgsfield exercise prompt | Default app caption (English translation) |
|---|---|---|---|
| `lip_01_tuck_extend.mp4` | `FACE_PREFIX` | Roll both lips gently inward over the teeth, hold briefly, then release and extend both lips straight forward into a soft pucker before returning to neutral. | `Tuck your lips inward, then extend them forward.` |
| `lip_02_u_to_i.mp4` | `FACE_PREFIX` | Alternate clearly between a rounded Korean 우 lip shape and a wide relaxed Korean 이 lip shape, then return to neutral. | `Alternate the lip shapes for /우/ and /이/.` |
| `lip_03_a_to_i.mp4` | `FACE_PREFIX` | Alternate between an open Korean 아 mouth shape and a wide Korean 이 lip shape with a stable head and relaxed jaw. | `Alternate the mouth shapes for /아/ and /이/.` |
| `lip_04_u_to_a.mp4` | `FACE_PREFIX` | Alternate between a rounded Korean 우 lip shape and an open Korean 아 mouth shape, using one smooth controlled cycle. | `Alternate the lip shapes for /우/ and /아/.` |
| `lip_05_kiss.mp4` | `FACE_PREFIX` | Form a gentle kiss pucker, hold briefly, release to neutral, and repeat once with a clear smooth motion suitable for slow or fast app playback. | `Repeat a gentle kissing lip shape.` |
| `lip_06_spread_pucker.mp4` | `FACE_PREFIX` | Spread the lips horizontally into a broad relaxed shape, then bring them forward into a rounded kiss pucker, and return to neutral. | `Spread your lips sideways, then gather them forward.` |
| `lip_07_open_hold.mp4` | `FACE_PREFIX` | Open the mouth to a comfortable wide position, keep the jaw centered, hold for two seconds, then close softly. Do not show strain or pain. | `Open comfortably wide and hold for 2 seconds.` |
| `lip_08_lip_cover.mp4` | `FACE_PREFIX` | Move the lower lip upward to cover the upper lip, release, then move the upper lip downward to cover the lower lip, and return to neutral. | `Alternate covering the upper lip with the lower and the lower with the upper.` |
| `lip_09_one_side_grimace.mp4` | `FACE_PREFIX` | Gently pull only one corner of the mouth sideways so the lips shift to one side, hold briefly, release, then demonstrate the opposite side and return to neutral. | `Move one corner of your mouth at a time.` |
| `lip_10_ppa_release.mp4` | `PHONEME_PREFIX` | Close both lips firmly but without strain, build a small amount of pressure, then release into one clear silent Korean 빠 articulation. Return to neutral and repeat once. | `Close and release your lips to say ‘빠’.` |
| `lip_11_fish_mouth.mp4` | `FACE_PREFIX` | Draw both cheeks slightly inward and form a small rounded fish-mouth shape with the lips, hold briefly, then relax completely. | `Draw your cheeks in slightly to make a fish-mouth shape.` |
| `lip_12_sad_smile.mp4` | `FACE_PREFIX` | Change slowly from a gentle sad mouth expression with lowered corners to a broad relaxed smile, then return to neutral. Keep the emotion calm and non-dramatic. | `Alternate a sad expression and a smile.` |

## 6. Ten alternating-movement videos

Produce silent videos. App captions and optional TTS, rather than generated video, provide the exact syllables.

| File | Type | Higgsfield exercise prompt | Default app caption (English translation) |
|---|---|---|---|
| `alternating_01_uiui.mp4` | `PHONEME_PREFIX` | Silently articulate Korean 우-이-우-이 with four distinct evenly timed rounded-to-wide lip transitions. | `우 · 이 · 우 · 이` |
| `alternating_02_ba_ppa_pa_ma.mp4` | `PHONEME_PREFIX` | Silently articulate Korean 바-빠-파-마 in order. Show four distinct bilabial closures and releases with stronger tension for 빠 and visible breath release for 파. | `바 · 빠 · 파 · 마` |
| `alternating_03_aia.mp4` | `PHONEME_PREFIX` | Silently articulate Korean 아-이-아 with clear open-wide-open mouth transitions and even timing. | `아 · 이 · 아` |
| `alternating_04_da_tta_ta_na.mp4` | `PHONEME_PREFIX` | Silently articulate Korean 다-따-타-나 in order, showing distinct tongue-tip placement behind the upper front teeth and clear jaw stability. | `다 · 따 · 타 · 나` |
| `alternating_05_reoreo.mp4` | `PHONEME_PREFIX` | Silently articulate Korean 러-러-러 three times with repeated controlled tongue-tip motion and an even rhythm. | `러 · 러 · 러` |
| `alternating_06_peo_teo_reo_keo.mp4` | `PHONEME_PREFIX` | Silently articulate Korean 퍼-터-러-커 in order, making each mouth and tongue placement visually distinct and evenly timed. | `퍼 · 터 · 러 · 커` |
| `alternating_07_peo_repeat.mp4` | `PHONEME_PREFIX` | Silently articulate Korean 퍼 three times with clear lip closure, release, and even pacing. | `퍼 · 퍼 · 퍼` |
| `alternating_08_teo_repeat.mp4` | `PHONEME_PREFIX` | Silently articulate Korean 터 three times with visible tongue-tip release and stable jaw position. | `터 · 터 · 터` |
| `alternating_09_keo_repeat.mp4` | `PHONEME_PREFIX` | Silently articulate Korean 커 three times with subtle back-of-tongue movement and even timing. | `커 · 커 · 커` |
| `alternating_10_peo_teo_keo.mp4` | `PHONEME_PREFIX` | Silently articulate Korean 퍼-터-커 in order, clearly separating the lip, tongue-tip, and back-of-tongue placements. | `퍼 · 터 · 커` |

## 7. Ten breathing videos

Exclude breathing 2–7 from general recommendations before clinical review. Generated demonstrations must not show excessive effort, facial flushing, or rapid repetitions.

| File | Type | Higgsfield exercise prompt | Default app caption (English translation) |
|---|---|---|---|
| `breathing_01_posture_inhale.mp4` | `BODY_PREFIX` | Sit upright. Inhale slowly while the upper chest opens gently and the torso lengthens without leaning dangerously backward, pause briefly, then return to relaxed posture. | `Sit upright, open your chest, and inhale slowly.` |
| `breathing_02_pause_inhale.mp4` | `BODY_PREFIX` | Clinical-review demonstration. Take a comfortable breath, pause without visible strain, then make one clear brisk nasal inhale and immediately return to calm normal breathing. | `Pause briefly without strain, then inhale once.` |
| `breathing_03_rapid_deep.mp4` | `BODY_PREFIX` | Clinical-review demonstration only. Show two slightly quicker but still controlled deep breathing cycles, then visibly return to a slow steady resting rhythm. Never show prolonged rapid breathing. | `Practice fast breathing briefly only as professionally directed.` |
| `breathing_04_hiccup_sob.mp4` | `BODY_PREFIX` | Clinical-review demonstration. Show one small hiccup-like inspiratory motion followed by one gentle sob-like broken inhalation, without distress, crying tears, choking, or dramatic emotion, then relax. | `Try short inhalations resembling a hiccup and a sob.` |
| `breathing_05_hold_exhale.mp4` | `BODY_PREFIX` | Inhale comfortably, hold with relaxed shoulders for two seconds, then exhale very slowly through softly parted lips until returning to neutral. Do not show maximum effort. | `Inhale comfortably, hold briefly, then exhale slowly.` |
| `breathing_06_small_inhale_hold.mp4` | `BODY_PREFIX` | Take one small gentle inhale, pause briefly with no strain, then return to calm normal breathing. | `Inhale a little and pause comfortably for a moment.` |
| `breathing_07_small_exhale_hold.mp4` | `BODY_PREFIX` | Release a small amount of air through relaxed lips, pause briefly with no strain, then return to calm normal breathing. | `Exhale a little and pause comfortably for a moment.` |
| `breathing_08_sustain_a.mp4` | `BODY_PREFIX` | Inhale comfortably, then hold a steady open Korean 아 mouth shape during one long controlled exhalation. Keep shoulders and face relaxed, then return to neutral. | `Inhale, then sustain /아/ comfortably.` |
| `breathing_09_sustain_i.mp4` | `BODY_PREFIX` | Inhale comfortably, then hold a steady wide Korean 이 mouth shape during one long controlled exhalation. Keep shoulders and face relaxed, then return to neutral. | `Inhale, then sustain /이/ comfortably.` |
| `breathing_10_sustain_u.mp4` | `BODY_PREFIX` | Inhale comfortably, then hold a steady rounded Korean 우 lip shape during one long controlled exhalation. Keep shoulders and face relaxed, then return to neutral. | `Inhale, then sustain /우/ comfortably.` |

## 8. App caption timing

Store cues in exercise data rather than burning captions into videos.

### 8.1 General movement template

| Phase | Proportion | Example caption |
|---|---:|---|
| Prepare | 0–15% | Get ready comfortably. |
| Move toward target | 15–45% | Exercise-specific default caption |
| Hold | 45–65% | Hold briefly. |
| Return | 65–90% | Return slowly. |
| Rest | 90–100% | Relax. |

### 8.2 Left/right or alternating template

| Phase | Proportion | Example caption |
|---|---:|---|
| Prepare | 0–10% | Look ahead. |
| First direction | 10–40% | Left or first syllable |
| Center | 40–50% | Center |
| Opposite direction | 50–80% | Right or next syllable |
| Return | 80–100% | Return slowly. |

### 8.3 Alternating-syllable display

- Display the current syllable large in the center.
- Preview the next syllable on the right at 60% transparency.
- Use a brief emphasis animation within 150 ms when syllables change.
- Scale cue times proportionally for 0.5×, 0.75×, and 1× playback.
- Generated mouth shapes may be inaccurate; app captions and expert review are the final accuracy criteria.

## 9. Generation and review procedure

1. Lock the reference character image.
2. Combine the appropriate shared and exercise prompts.
3. Add the shared negative prompt.
4. Generate at least 3 candidates per exercise.
5. First review character consistency, oral anatomy, direction, and loop continuity.
6. Have a speech-rehabilitation professional review intent and safety.
7. Compress approved output to silent 720p H.264 MP4.
8. Extract the first frame as a WebP or PNG poster.
9. Automatically check filenames against exercise IDs.
10. Check loop boundaries and decoding on physical iOS/Android devices.

## 10. Video QA checklist

- Consistent character, clothing, hairstyle, and background?
- Stable camera/head except when head motion is required?
- No duplicated tongue or distorted teeth/lips?
- Internal contact points match the instructions?
- Directions match app-caption policy?
- First and last frames join naturally?
- No meaningless text or watermarks?
- No alarming pain, choking, or excessive strain?
- Enough lower-screen safe area for captions?
- Movement remains intact at 0.5× speed?

Regenerate with a corrected prompt after any failure. If internal anatomy remains unstable, use handmade 2D vectors or Rive animation instead of generated video.

## 11. App asset structure

```text
assets/training_videos/
├── tongue/
├── lip/
├── alternating/
└── breathing/

assets/training_posters/
├── tongue/
├── lip/
├── alternating/
└── breathing/
```

Register directories in `pubspec.yaml`. If compressed videos exceed 60 MB, bundle only default-routine videos and defer others to a versioned remote manifest and local cache.

## 12. Source-use principles

- Use the supplied document only as user-provided material for the exercise inventory.
- Do not copy or redistribute footage, audio, or captions from YouTube or other third parties.
- Create every demonstration anew using the reference character.
- Describe generated videos as educational visuals, not guarantees of correct performance or treatment effectiveness.
