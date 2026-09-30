# Exercises Without Guide Videos

[한국어](training-video-coverage-2026-09-17.md) | [English](training-video-coverage-2026-09-17.en.md) | [All documents](README.en.md)

Checked: 2026-09-17 · Based on source and video assets in the current working directory.

Of **46 exercises, 8 have linked videos and 38 do not**. All 38 have an empty `videoAsset`, and their planned MP4 files are also absent from the project video folder.

Verified that all eight linked files exist and are registered as app assets. No linked path points to a missing file, and no video file exists without an exercise link. Actual playback on each device and content suitability were outside this check.

| Exercise type | Total | Video linked | No video |
|---|---:|---:|---:|
| Tongue exercises | 14 | 4 | 10 |
| Lip exercises | 12 | 2 | 10 |
| Alternating exercises | 10 | 0 | 10 |
| Breathing training | 10 | 2 | 8 |
| **Total** | **46** | **8** | **38** |

Exercises without videos currently show **a tutor background image + a scaling icon + text instructions**, not footage demonstrating the movement.

The 38 include **seven “expert confirmation” exercises** currently locked in the app: tongue-depressor resistance and breathing items 2–7. **31 exercises** available to general users lack videos.

**Alternating exercise 1, “우이우이,”** included in the default recommended routine, also has no video.

## Tongue exercises — 10 without videos

| App order | Exercise name | Planned video file | App safety category |
|---:|---|---|---|
| 2 | Touch upper/lower lips | `tongue_02_touch_lips.mp4` | General |
| 5 | Attach/release the back of the tongue | `tongue_05_soft_palate_click.mp4` | Caution |
| 6 | Sweep backward along the palate | `tongue_06_palate_sweep.mp4` | General |
| 7 | Hold tongue against the palate | `tongue_07_hard_palate_hold.mp4` | Caution |
| 8 | Tongue-depressor resistance | `tongue_08_resistance.mp4` | Expert confirmation |
| 9 | Monkey-mouth shape | `tongue_09_monkey_lips.mp4` | General |
| 10 | Touch both sides of the molars | `tongue_10_molars.mp4` | General |
| 11 | Trace the teeth in order | `tongue_11_trace_teeth.mp4` | General |
| 13 | Tick-tock clicking | `tongue_13_clock_click.mp4` | General |
| 14 | Tongue-click practice | `tongue_14_tongue_click.mp4` | General |

## Lip exercises — 10 without videos

| App order | Exercise name | Planned video file | App safety category |
|---:|---|---|---|
| 1 | Tuck and extend lips | `lip_01_tuck_extend.mp4` | General |
| 3 | A–I mouth shapes | `lip_03_a_to_i.mp4` | General |
| 4 | U–A mouth shapes | `lip_04_u_to_a.mp4` | General |
| 5 | Kissing lips | `lip_05_kiss.mp4` | General |
| 6 | Spread and pucker lips | `lip_06_spread_pucker.mp4` | General |
| 8 | Cover upper/lower lips | `lip_08_lip_cover.mp4` | General |
| 9 | Move one mouth corner at a time | `lip_09_one_side_grimace.mp4` | General |
| 10 | Produce “빠” | `lip_10_ppa_release.mp4` | General |
| 11 | Fish-mouth shape | `lip_11_fish_mouth.mp4` | General |
| 12 | Sad and smiling expressions | `lip_12_sad_smile.mp4` | General |

## Alternating exercises — 10 without videos

| App order | Exercise name | Planned video file | App safety category |
|---:|---|---|---|
| 1 | 우이우이 | `alternating_01_uiui.mp4` | General |
| 2 | 바-빠-파-마 | `alternating_02_ba_ppa_pa_ma.mp4` | General |
| 3 | 아이아 | `alternating_03_aia.mp4` | General |
| 4 | 다-따-타-나 | `alternating_04_da_tta_ta_na.mp4` | General |
| 5 | 러러러 | `alternating_05_reoreo.mp4` | General |
| 6 | 퍼-터-러-커 | `alternating_06_peo_teo_reo_keo.mp4` | General |
| 7 | 퍼퍼퍼 | `alternating_07_peo_repeat.mp4` | General |
| 8 | 터터터 | `alternating_08_teo_repeat.mp4` | General |
| 9 | 커커커 | `alternating_09_keo_repeat.mp4` | General |
| 10 | 퍼터커 | `alternating_10_peo_teo_keo.mp4` | General |

## Breathing training — 8 without videos

| App order | Exercise name | Planned video file | App safety category |
|---:|---|---|---|
| 2 | Pause breathing, then inhale | `breathing_02_pause_inhale.mp4` | Expert confirmation |
| 3 | Rapid deep breathing | `breathing_03_rapid_deep.mp4` | Expert confirmation |
| 4 | Imitate hiccups/sobbing | `breathing_04_hiccup_sob.mp4` | Expert confirmation |
| 5 | Inhale, then exhale slowly | `breathing_05_hold_exhale.mp4` | Expert confirmation |
| 6 | Small inhale and hold | `breathing_06_small_inhale_hold.mp4` | Expert confirmation |
| 7 | Small exhale and hold | `breathing_07_small_exhale_hold.mp4` | Expert confirmation |
| 9 | Sustain the I vowel | `breathing_09_sustain_i.mp4` | Caution |
| 10 | Sustain the U vowel | `breathing_10_sustain_u.mp4` | Caution |

Planned files belong in `assets/videos/training/`. Names come from the production specification and do not mean files have already been made. Safety categories reproduce the current app configuration.

## For comparison: eight exercises with videos

| Exercise type | App order | Exercise name | Linked file |
|---|---:|---|---|
| Tongue exercises | 1 | Extend tongue and move up/down | `tongue_01_vertical.mp4` |
| Tongue exercises | 3 | Touch both mouth corners | `tongue_03_lip_corners.mp4` |
| Tongue exercises | 4 | Circle around the lips | `tongue_04_lip_circle.mp4` |
| Tongue exercises | 12 | Press inside both cheeks | `tongue_12_cheek_press.mp4` |
| Lip exercises | 2 | U–I mouth shapes | `lip_02_u_to_i.mp4` |
| Lip exercises | 7 | Open mouth wide and hold | `lip_07_open_hold.mp4` |
| Breathing training | 1 | Sit upright and inhale | `breathing_01_posture_inhale.mp4` |
| Breathing training | 8 | Sustain the A vowel | `breathing_08_sustain_a.mp4` |

## Verification method and evidence

- Loaded the actual Dart catalog and checked all 46 items, including those generated by helpers.
- Compared every video reference with actual file existence.
- Confirmed all 46 planned filenames match exercise IDs.
- Confirmed `assets/videos/training/` is registered in `pubspec.yaml`.
- Inspected playback fallback to text when a video is missing or initialization fails.

Related files:

- [Exercise catalog](../lib/features/guided_training/data/guided_training_catalog.dart)
- [Exercise models and video-availability checks](../lib/features/guided_training/model/guided_training_models.dart)
- [Guide player and fallback instructions](../lib/features/guided_training/view/guided_training_player_screen.dart)
- [App asset registration](../pubspec.yaml)
- [Video production plan and per-exercise prompts](training-video-prompts/training-video-production-plan.en.md)
