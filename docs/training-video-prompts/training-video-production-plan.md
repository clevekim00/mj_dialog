# 구강·교호·호흡 훈련 영상 제작 및 Higgsfield 프롬프트 명세

작성일: 2026-08-25

## 1. 목적

`docs/breathing-and-oral-exercises.md`의 46개 훈련을 앱에서 반복 재생할 짧은 무음 영상으로 제작한다. 영상은 동작만 보여주고, 지시문·반복 횟수·안전 문구·속도는 Flutter 앱이 별도로 표시한다.

이 문서의 영문 프롬프트는 공통 프롬프트와 운동별 프롬프트를 합쳐 Higgsfield에 입력하는 제작 초안이다. 생성 결과는 의료 또는 언어재활 전문가의 동작 검수를 통과해야 앱에 포함할 수 있다.

## 2. 제작 규격

| 항목 | 규격 |
|---|---|
| 기준 캐릭터 | `assets/images/ai_speech_2d_tutor.png`의 동일한 성인 여성 2D 재활 안내자 |
| 화면비 | 16:9 |
| 원본 출력 | 1920×1080 권장 |
| 앱 배포본 | 1280×720 MP4, H.264 |
| 프레임률 | 전체 영상에서 24fps 또는 30fps 하나로 통일 |
| 길이 | 4~8초 |
| 오디오 | 없음 |
| 카메라 | 고정, 줌·팬·컷 전환 없음 |
| 반복 | 첫 프레임과 마지막 프레임이 같은 기본 자세인 자연스러운 루프 |
| 텍스트 | 생성 영상 안에는 글자·숫자·로고·자막을 넣지 않음 |
| 안전 영역 | 얼굴·입·가슴 등 핵심 동작을 중앙 70% 안에 배치 |

## 3. Higgsfield 공통 프롬프트

### 3.1 얼굴 정면 클로즈업 `FACE_PREFIX`

```text
Use the supplied reference image as the exact character reference. Keep the same adult Korean female 2D rehabilitation therapist, the same face, dark ponytail, white clinician uniform, soft clean cel-shaded illustration style, and warm speech-therapy clinic background. Front-facing head-and-shoulders close-up, locked camera, symmetrical framing, head and jaw stable unless the requested exercise requires jaw motion. Show the lips and tongue large and unobstructed. Perform one slow, gentle, anatomically plausible demonstration cycle, then return to the exact neutral starting pose for a seamless loop. Silent video, no speaking audio, no text, no captions, no logo, no UI, no camera movement.
```

### 3.2 구강 측면 단면도 `CUTAWAY_PREFIX`

```text
Create a clean non-graphic 2D clinical education animation matching the supplied therapist reference style. Show a stable side-profile cutaway of the mouth with lips, upper and lower teeth, tongue, hard palate, soft palate, and cheeks clearly separated by calm educational colors. Locked camera, anatomically plausible proportions, no saliva, no gore, no photorealism. Animate only the requested tongue or mouth movement slowly and clearly, then return to the exact neutral starting pose for a seamless loop. Silent video, no text, no labels, no arrows, no logo, no UI, no camera movement.
```

### 3.3 상반신 호흡 `BODY_PREFIX`

```text
Use the supplied reference image as the exact character reference. Keep the same adult Korean female 2D rehabilitation therapist, same face, dark ponytail, white clinician uniform, and clean warm clinic. Seated upright upper-body view from the front at a slight three-quarter angle, hands resting comfortably where specified, shoulders relaxed, locked camera. Demonstrate one calm and anatomically plausible breathing cycle with subtle chest and abdomen motion, then return to the same neutral pose for a seamless loop. Silent video, no text, no captions, no logo, no UI, no dramatic body motion, no camera movement.
```

### 3.4 무음 음절 시범 `PHONEME_PREFIX`

```text
Use the supplied reference image as the exact character reference. Keep the same adult Korean female 2D rehabilitation therapist, face, dark ponytail, white clinician uniform, and clean cel-shaded style. Extreme front-facing mouth and lower-face close-up, locked camera, stable head, clear lips, teeth, jaw, and visible tongue tip. Silently articulate the requested Korean syllable sequence with distinct, exaggerated but natural mouth placements and even timing. Finish in the exact neutral starting pose for a seamless loop. No generated audio, no text, no phonetic symbols, no captions, no logo, no UI, no camera movement.
```

### 3.5 공통 네거티브 프롬프트

```text
photorealistic surgery, gore, saliva strands, deformed mouth, duplicate tongue, forked tongue, extra teeth, missing teeth, warped lips, asymmetrical face unless requested, head turning, camera shake, zoom, scene cut, talking audio, written words, subtitles, numbers, watermark, logo, UI, hands covering the mouth, exaggerated pain, choking, coughing
```

## 4. 혀 운동 영상 14개

각 행의 프롬프트 앞에 표시된 공통 프롬프트를 붙인다.

| 파일 | 유형 | Higgsfield 운동별 프롬프트 | 앱 기본 자막 |
|---|---|---|---|
| `tongue_01_vertical.mp4` | `FACE_PREFIX` | Slowly extend the tongue straight forward, move the tongue tip upward toward the upper lip, then downward toward the lower lip, and return to neutral. Keep the head still and keep the movement centered. | `혀를 내밀어 위와 아래로 움직이세요.` |
| `tongue_02_touch_lips.mp4` | `FACE_PREFIX` | Open the mouth comfortably. Touch the upper lip with the tongue tip, return to center, touch the lower lip, then return to neutral. Do not move the head. | `혀끝을 윗입술과 아랫입술에 번갈아 대세요.` |
| `tongue_03_lip_corners.mp4` | `FACE_PREFIX` | Extend the tongue slightly and touch the viewer-left lip corner, return to center, then touch the viewer-right lip corner and return. Keep the jaw and head stable. | `혀끝을 양쪽 입꼬리에 번갈아 대세요.` |
| `tongue_04_lip_circle.mp4` | `FACE_PREFIX` | Extend the tongue and trace one slow complete circle around the outside edge of the lips, pause at center, then trace one circle in the opposite direction and return to neutral. | `입술 둘레를 양방향으로 천천히 돌리세요.` |
| `tongue_05_soft_palate_click.mp4` | `CUTAWAY_PREFIX` | Lift the back of the tongue gently toward the soft-palate area, make a controlled contact-and-release motion, then return to the resting tongue position. Show one slow cycle that can be sped up by the app. | `혀 뒤쪽을 올려 천천히 붙였다 떼세요.` |
| `tongue_06_palate_sweep.mp4` | `CUTAWAY_PREFIX` | Place the tongue tip directly behind the upper front teeth, then sweep the tongue backward along the roof of the mouth and lower it gently to the resting position. | `윗니 뒤에서 입천장을 따라 혀를 뒤로 움직이세요.` |
| `tongue_07_hard_palate_hold.mp4` | `CUTAWAY_PREFIX` | Open the jaw comfortably, not excessively. Press the broad tongue gently against the hard palate, hold visibly for two seconds, release, and return to neutral. | `혀를 입천장에 대고 편안하게 유지하세요.` |
| `tongue_08_resistance.mp4` | `CUTAWAY_PREFIX` | Clinical supervision demonstration only. Show a stationary flat tongue depressor outside the lips providing very light resistance while the tongue presses forward, then gently to each side. No force, no deep insertion, no self-use gesture. | `전문가 지도 아래 가벼운 저항 운동을 하세요.` |
| `tongue_09_monkey_lips.mp4` | `FACE_PREFIX` | Keep the lips softly closed. Move the tongue inside the mouth to push the upper lip outward from behind, return, then push the lower lip outward from behind, creating a gentle monkey-face shape, then relax. | `혀로 윗입술과 아랫입술 안쪽을 번갈아 미세요.` |
| `tongue_10_molars.mp4` | `CUTAWAY_PREFIX` | Move the tongue tip to touch the left back molar area, return to center, then touch the right back molar area and return. Keep the jaw still. | `혀끝을 양쪽 어금니에 번갈아 대세요.` |
| `tongue_11_trace_teeth.mp4` | `CUTAWAY_PREFIX` | Use the tongue tip to trace each upper tooth from one side to the other, then trace the lower teeth back in the opposite direction, like checking the teeth one by one. | `혀끝으로 윗니와 아랫니를 차례로 훑으세요.` |
| `tongue_12_cheek_press.mp4` | `FACE_PREFIX` | Keep the lips closed. Press the tongue into the inside of the viewer-left cheek so a small rounded bulge appears, return to center, then repeat on the viewer-right cheek and relax. | `혀로 양쪽 볼 안쪽을 번갈아 미세요.` |
| `tongue_13_clock_click.mp4` | `CUTAWAY_PREFIX` | Demonstrate a gentle clock-like tongue click: lift the tongue tip to the alveolar ridge behind the upper front teeth, create contact, release cleanly, and return to neutral in an even rhythm. | `혀끝을 붙였다 떼며 똑딱 소리를 내보세요.` |
| `tongue_14_tongue_click.mp4` | `FACE_PREFIX` | Open the lips slightly and demonstrate a clear gentle tongue-click calling motion, repeating three evenly paced contact-and-release cycles, then return to a relaxed mouth. | `혀 차기 소리를 천천히 따라 하세요.` |

## 5. 입술 운동 영상 12개

| 파일 | 유형 | Higgsfield 운동별 프롬프트 | 앱 기본 자막 |
|---|---|---|---|
| `lip_01_tuck_extend.mp4` | `FACE_PREFIX` | Roll both lips gently inward over the teeth, hold briefly, then release and extend both lips straight forward into a soft pucker before returning to neutral. | `입술을 안으로 넣었다가 앞으로 내미세요.` |
| `lip_02_u_to_i.mp4` | `FACE_PREFIX` | Alternate clearly between a rounded Korean 우 lip shape and a wide relaxed Korean 이 lip shape, then return to neutral. | `/우/와 /이/ 입 모양을 번갈아 만드세요.` |
| `lip_03_a_to_i.mp4` | `FACE_PREFIX` | Alternate between an open Korean 아 mouth shape and a wide Korean 이 lip shape with a stable head and relaxed jaw. | `/아/와 /이/ 입 모양을 번갈아 만드세요.` |
| `lip_04_u_to_a.mp4` | `FACE_PREFIX` | Alternate between a rounded Korean 우 lip shape and an open Korean 아 mouth shape, using one smooth controlled cycle. | `/우/와 /아/ 입 모양을 번갈아 만드세요.` |
| `lip_05_kiss.mp4` | `FACE_PREFIX` | Form a gentle kiss pucker, hold briefly, release to neutral, and repeat once with a clear smooth motion suitable for slow or fast app playback. | `뽀뽀하는 입술 모양을 반복하세요.` |
| `lip_06_spread_pucker.mp4` | `FACE_PREFIX` | Spread the lips horizontally into a broad relaxed shape, then bring them forward into a rounded kiss pucker, and return to neutral. | `입술을 양옆으로 벌렸다가 앞으로 모으세요.` |
| `lip_07_open_hold.mp4` | `FACE_PREFIX` | Open the mouth to a comfortable wide position, keep the jaw centered, hold for two seconds, then close softly. Do not show strain or pain. | `입을 편안한 범위에서 크게 벌려 2초 유지하세요.` |
| `lip_08_lip_cover.mp4` | `FACE_PREFIX` | Move the lower lip upward to cover the upper lip, release, then move the upper lip downward to cover the lower lip, and return to neutral. | `아랫입술과 윗입술을 번갈아 덮으세요.` |
| `lip_09_one_side_grimace.mp4` | `FACE_PREFIX` | Gently pull only one corner of the mouth sideways so the lips shift to one side, hold briefly, release, then demonstrate the opposite side and return to neutral. | `입꼬리를 한쪽씩 움직여 보세요.` |
| `lip_10_ppa_release.mp4` | `PHONEME_PREFIX` | Close both lips firmly but without strain, build a small amount of pressure, then release into one clear silent Korean 빠 articulation. Return to neutral and repeat once. | `입술을 막았다 터뜨리며 ‘빠’를 발음하세요.` |
| `lip_11_fish_mouth.mp4` | `FACE_PREFIX` | Draw both cheeks slightly inward and form a small rounded fish-mouth shape with the lips, hold briefly, then relax completely. | `볼을 살짝 당겨 붕어입 모양을 만드세요.` |
| `lip_12_sad_smile.mp4` | `FACE_PREFIX` | Change slowly from a gentle sad mouth expression with lowered corners to a broad relaxed smile, then return to neutral. Keep the emotion calm and non-dramatic. | `슬픈 표정과 웃는 표정을 번갈아 만드세요.` |

## 6. 교호 운동 영상 10개

교호 영상은 무음으로 제작한다. 정확한 음절은 생성 영상이 아니라 앱 자막과 선택적 TTS가 책임진다.

| 파일 | 유형 | Higgsfield 운동별 프롬프트 | 앱 기본 자막 |
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

## 7. 호흡 훈련 영상 10개

호흡 2~7번은 임상 검토 전 일반 추천 루틴에 넣지 않는다. 생성 영상 역시 과도한 노력, 얼굴 붉어짐, 빠른 반복을 묘사하지 않는다.

| 파일 | 유형 | Higgsfield 운동별 프롬프트 | 앱 기본 자막 |
|---|---|---|---|
| `breathing_01_posture_inhale.mp4` | `BODY_PREFIX` | Sit upright. Inhale slowly while the upper chest opens gently and the torso lengthens without leaning dangerously backward, pause briefly, then return to relaxed posture. | `앉은 자세에서 가슴을 펴며 천천히 들이마시세요.` |
| `breathing_02_pause_inhale.mp4` | `BODY_PREFIX` | Clinical-review demonstration. Take a comfortable breath, pause without visible strain, then make one clear brisk nasal inhale and immediately return to calm normal breathing. | `무리하지 말고 잠깐 멈춘 뒤 한 번 들이마시세요.` |
| `breathing_03_rapid_deep.mp4` | `BODY_PREFIX` | Clinical-review demonstration only. Show two slightly quicker but still controlled deep breathing cycles, then visibly return to a slow steady resting rhythm. Never show prolonged rapid breathing. | `빠른 호흡은 전문가 지시에 따라 짧게 실시하세요.` |
| `breathing_04_hiccup_sob.mp4` | `BODY_PREFIX` | Clinical-review demonstration. Show one small hiccup-like inspiratory motion followed by one gentle sob-like broken inhalation, without distress, crying tears, choking, or dramatic emotion, then relax. | `딸꾹질과 흐느낌 같은 짧은 들숨을 따라 해보세요.` |
| `breathing_05_hold_exhale.mp4` | `BODY_PREFIX` | Inhale comfortably, hold with relaxed shoulders for two seconds, then exhale very slowly through softly parted lips until returning to neutral. Do not show maximum effort. | `편안히 들이마셔 잠깐 유지한 뒤 천천히 내쉬세요.` |
| `breathing_06_small_inhale_hold.mp4` | `BODY_PREFIX` | Take one small gentle inhale, pause briefly with no strain, then return to calm normal breathing. | `조금 들이마시고 편안하게 잠깐 멈추세요.` |
| `breathing_07_small_exhale_hold.mp4` | `BODY_PREFIX` | Release a small amount of air through relaxed lips, pause briefly with no strain, then return to calm normal breathing. | `조금 내쉬고 편안하게 잠깐 멈추세요.` |
| `breathing_08_sustain_a.mp4` | `BODY_PREFIX` | Inhale comfortably, then hold a steady open Korean 아 mouth shape during one long controlled exhalation. Keep shoulders and face relaxed, then return to neutral. | `숨을 들이마신 뒤 /아/를 편안하게 길게 발성하세요.` |
| `breathing_09_sustain_i.mp4` | `BODY_PREFIX` | Inhale comfortably, then hold a steady wide Korean 이 mouth shape during one long controlled exhalation. Keep shoulders and face relaxed, then return to neutral. | `숨을 들이마신 뒤 /이/를 편안하게 길게 발성하세요.` |
| `breathing_10_sustain_u.mp4` | `BODY_PREFIX` | Inhale comfortably, then hold a steady rounded Korean 우 lip shape during one long controlled exhalation. Keep shoulders and face relaxed, then return to neutral. | `숨을 들이마신 뒤 /우/를 편안하게 길게 발성하세요.` |

## 8. 앱 자막 타이밍

영상에 자막을 굽지 않고 각 운동 데이터에 큐를 저장한다.

### 8.1 일반 동작 템플릿

| 구간 | 비율 | 자막 예시 |
|---|---:|---|
| 준비 | 0~15% | `편안하게 준비하세요.` |
| 목표 방향 이동 | 15~45% | 운동별 기본 자막 |
| 유지 | 45~65% | `잠깐 유지하세요.` |
| 복귀 | 65~90% | `천천히 돌아오세요.` |
| 휴식 | 90~100% | `힘을 빼세요.` |

### 8.2 좌우·교대 동작 템플릿

| 구간 | 비율 | 자막 예시 |
|---|---:|---|
| 준비 | 0~10% | `정면을 보세요.` |
| 첫 방향 | 10~40% | `왼쪽` 또는 첫 음절 |
| 중앙 | 40~50% | `가운데` |
| 반대 방향 | 50~80% | `오른쪽` 또는 다음 음절 |
| 복귀 | 80~100% | `천천히 돌아오세요.` |

### 8.3 교호 운동 표시

- 현재 음절은 화면 중앙에 크게 표시한다.
- 다음 음절은 오른쪽에 60% 투명도로 미리 표시한다.
- 음절 변경 시 150ms 이내의 짧은 강조 애니메이션을 사용한다.
- 0.5배·0.75배·1배 재생 속도에 맞춰 큐 시간을 같은 비율로 조정한다.
- 영상 생성 입 모양이 부정확할 수 있으므로 최종 정확성 기준은 앱 자막과 전문가 검수다.

## 9. 생성 및 검수 절차

1. 기준 캐릭터 이미지를 reference image로 고정한다.
2. 운동 유형에 맞는 공통 프롬프트와 운동별 프롬프트를 합친다.
3. 공통 네거티브 프롬프트를 추가한다.
4. 운동당 최소 3개 후보를 생성한다.
5. 캐릭터 일치, 입·혀 해부학, 좌우 방향, 루프 연결을 1차 검수한다.
6. 언어재활 전문가가 운동 의도와 안전성을 2차 검수한다.
7. 승인본을 720p H.264 무음 MP4로 압축한다.
8. 첫 프레임을 포스터 WebP 또는 PNG로 추출한다.
9. 파일명과 운동 ID가 일치하는지 자동 검사한다.
10. iOS와 Android 실기기에서 반복 경계와 디코딩 성능을 확인한다.

## 10. 영상 QA 체크리스트

- 동일 캐릭터, 의상, 헤어스타일, 배경이 유지되는가?
- 머리 움직임이 필요한 동작 외에는 카메라와 머리가 고정되어 있는가?
- 혀가 두 개로 보이거나 치아·입술이 변형되지 않았는가?
- 내부 구강 동작의 접촉 위치가 설명과 일치하는가?
- 좌우 방향이 앱 자막 정책과 일치하는가?
- 첫 프레임과 마지막 프레임이 자연스럽게 이어지는가?
- 영상 안에 의미 없는 글자나 워터마크가 없는가?
- 고통, 질식, 과도한 힘주기처럼 불안한 장면이 없는가?
- 자막을 덮을 화면 하단 안전 영역이 확보되어 있는가?
- 반복 속도를 0.5배로 낮춰도 동작이 깨지지 않는가?

하나라도 실패하면 수정 프롬프트로 재생성한다. 입 안 구조가 계속 불안정한 항목은 생성형 영상 대신 수작업 2D 벡터 또는 Rive 애니메이션으로 전환한다.

## 11. 앱 자산 구조

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

`pubspec.yaml`에는 디렉터리 단위로 등록한다. 전체 압축 영상이 60MB를 넘으면 기본 추천 루틴 영상만 앱에 포함하고, 나머지는 버전이 포함된 원격 manifest와 로컬 캐시를 사용하는 후속 단계로 전환한다.

## 12. 출처 활용 원칙

- 첨부 문서는 운동 목록을 구성하는 사용자 제공 자료로만 사용한다.
- 기존 YouTube 또는 제3자 영상의 화면, 음성, 자막을 복제하거나 재배포하지 않는다.
- 모든 시범 영상은 기준 캐릭터를 사용해 새로 제작한다.
- 생성 영상은 교육용 시각 자료이며 정확한 수행 여부나 치료 효과를 보장한다고 표현하지 않는다.
