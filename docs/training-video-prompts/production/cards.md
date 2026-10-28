# 혀·입술 누락 영상 제작 카드

카탈로그와 로컬 렌더 결과에서 생성한 작업 카드다. 임상 승인 결과가 아니다.
제작 결과: output/training_video/batch_2026-10-27/README.md 및 index.html 참고.

공통 출력: 1280×720, 24fps, H.264, yuv420p, 오디오 트랙 없음.
기준 PNG에는 자막·플레이어 UI가 있다. 기존 MP4를 참고해 얼굴 전체의 연동 자세를 준비한다.
중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
lip_03_a_to_i/v001은 입만 교체해 어색하다는 피드백을 받은 초안으로, 후속 제작 템플릿으로 사용하지 않는다.
기존 6개 혀·입술 MP4는 보존하고, 검토 후보를 앱 assets에 연결하지 않는다.

먼저 파일럿 1–5의 정지 자세·캐릭터 일치·접촉 위치를 확인한 뒤 프레임을 렌더링한다.

## lip_03_a_to_i — 아-이 입 모양

- 제작 순서: 파일럿 1
- 지시문: /아/와 /이/ 입 모양을 번갈아 만드세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Alternate between an open Korean 아 mouth shape and a wide Korean 이 lip shape with a stable head and relaxed jaw.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/lip_03_a_to_i/v002/exports/lip_03_a_to_i_v002_review.mp4

## lip_04_u_to_a — 우-아 입 모양

- 제작 순서: 파일럿 2
- 지시문: /우/와 /아/ 입 모양을 번갈아 만드세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Alternate between a rounded Korean 우 lip shape and an open Korean 아 mouth shape, using one smooth controlled cycle.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/lip_04_u_to_a/v001/exports/lip_04_u_to_a_v001_review.mp4

## lip_05_kiss — 뽀뽀 입술 만들기

- 제작 순서: 파일럿 3
- 지시문: 뽀뽀하는 입술 모양을 느리게 한 뒤 빠르게 반복하세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Form a gentle kiss pucker, hold briefly, release to neutral, and repeat once with a clear smooth motion suitable for slow or fast app playback.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/lip_05_kiss/v001/exports/lip_05_kiss_v001_review.mp4

## lip_06_spread_pucker — 입술 벌렸다 모으기

- 제작 순서: 파일럿 4
- 지시문: 입술을 양옆으로 벌렸다가 앞으로 모으세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Spread the lips horizontally into a broad relaxed shape, then bring them forward into a rounded kiss pucker, and return to neutral.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/lip_06_spread_pucker/v001/exports/lip_06_spread_pucker_v001_review.mp4

## tongue_02_touch_lips — 윗입술·아랫입술 대기

- 제작 순서: 파일럿 5
- 지시문: 혀끝을 윗입술과 아랫입술에 번갈아 붙이세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Open the mouth comfortably. Touch the upper lip with the tongue tip, return to center, touch the lower lip, then return to neutral. Do not move the head.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/tongue_02_touch_lips/v001/exports/tongue_02_touch_lips_v001_review.mp4

## lip_01_tuck_extend — 입술 넣었다 내밀기

- 제작 순서: 파일럿 검토 후
- 지시문: 입술을 입 안으로 넣었다가 앞으로 쭉 내미세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Roll both lips gently inward over the teeth, hold briefly, then release and extend both lips straight forward into a soft pucker before returning to neutral.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/lip_01_tuck_extend/v001/exports/lip_01_tuck_extend_v001_review.mp4

## lip_08_lip_cover — 윗입술·아랫입술 덮기

- 제작 순서: 파일럿 검토 후
- 지시문: 아랫입술로 윗입술을 덮고, 윗입술로 아랫입술을 번갈아 덮으세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Move the lower lip upward to cover the upper lip, release, then move the upper lip downward to cover the lower lip, and return to neutral.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/lip_08_lip_cover/v001/exports/lip_08_lip_cover_v001_review.mp4

## lip_09_one_side_grimace — 입꼬리 한쪽씩 움직이기

- 제작 순서: 파일럿 검토 후
- 지시문: 한쪽 안면만 가볍게 찡그려 입술을 좌우로 움직이세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Gently pull only one corner of the mouth sideways so the lips shift to one side, hold briefly, release, then demonstrate the opposite side and return to neutral.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/lip_09_one_side_grimace/v001/exports/lip_09_one_side_grimace_v001_review.mp4

## lip_10_ppa_release — 빠 소리 내기

- 제작 순서: 파일럿 검토 후
- 지시문: 입술을 막았다 터뜨리는 느낌으로 /빠/를 발음하세요.
- 길이: 5초 / 120프레임
- 시각 모드: phoneme / 안전 등급: general
- 동작 초안: Close both lips firmly but without strain, build a small amount of pressure, then release into one clear silent Korean 빠 articulation. Return to neutral and repeat once.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/lip_10_ppa_release/v001/exports/lip_10_ppa_release_v001_review.mp4

## lip_11_fish_mouth — 붕어입 만들기

- 제작 순서: 파일럿 검토 후
- 지시문: 볼을 살짝 안으로 당기고 입술을 둥글게 모으세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Draw both cheeks slightly inward and form a small rounded fish-mouth shape with the lips, hold briefly, then relax completely.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/lip_11_fish_mouth/v001/exports/lip_11_fish_mouth_v001_review.mp4

## lip_12_sad_smile — 슬픈 표정·웃는 표정

- 제작 순서: 파일럿 검토 후
- 지시문: 슬픈 표정과 웃는 표정을 천천히 번갈아 만드세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Change slowly from a gentle sad mouth expression with lowered corners to a broad relaxed smile, then return to neutral. Keep the emotion calm and non-dramatic.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/lip_12_sad_smile/v001/exports/lip_12_sad_smile_v001_review.mp4

## tongue_05_soft_palate_click — 혀 뒤쪽 붙였다 떼기

- 제작 순서: 파일럿 검토 후
- 지시문: 혀 뒤쪽을 연구개 방향으로 천천히 붙였다가 떼세요.
- 길이: 5초 / 120프레임
- 시각 모드: oralCutaway / 안전 등급: caution
- 동작 초안: Lift the back of the tongue gently toward the soft-palate area, make a controlled contact-and-release motion, then return to the resting tongue position. Show one slow cycle that can be sped up by the app.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/tongue_05_soft_palate_click/v001/exports/tongue_05_soft_palate_click_v001_review.mp4

## tongue_06_palate_sweep — 입천장 뒤로 훑기

- 제작 순서: 파일럿 검토 후
- 지시문: 혀끝을 윗니 뒤에 댄 뒤 입천장을 따라 뒤로 천천히 움직이세요.
- 길이: 5초 / 120프레임
- 시각 모드: oralCutaway / 안전 등급: general
- 동작 초안: Place the tongue tip directly behind the upper front teeth, then sweep the tongue backward along the roof of the mouth and lower it gently to the resting position.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/tongue_06_palate_sweep/v001/exports/tongue_06_palate_sweep_v001_review.mp4

## tongue_07_hard_palate_hold — 입천장에 혀 대고 유지하기

- 제작 순서: 파일럿 검토 후
- 지시문: 입을 편안한 범위에서 벌리고 혀를 경구개에 대어 잠깐 유지하세요.
- 길이: 6초 / 144프레임
- 시각 모드: oralCutaway / 안전 등급: caution
- 동작 초안: Open the jaw comfortably, not excessively. Press the broad tongue gently against the hard palate, hold visibly for two seconds, release, and return to neutral.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/tongue_07_hard_palate_hold/v001/exports/tongue_07_hard_palate_hold_v001_review.mp4

## tongue_08_resistance — 설압자 저항 운동

- 제작 순서: 파일럿 검토 후
- 지시문: 전문가 지도 아래 설압자로 앞·좌·우 방향에 가벼운 저항을 주세요.
- 길이: 6초 / 144프레임
- 시각 모드: oralCutaway / 안전 등급: clinicianOnly
- 동작 초안: Clinical supervision demonstration only. Show a stationary flat tongue depressor outside the lips providing very light resistance while the tongue presses forward, then gently to each side. No force, no deep insertion, no self-use gesture.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/tongue_08_resistance/v001/exports/tongue_08_resistance_v001_review.mp4

## tongue_09_monkey_lips — 원숭이 입 모양 만들기

- 제작 순서: 파일럿 검토 후
- 지시문: 입술 안쪽에서 혀로 윗입술과 아랫입술을 번갈아 밀어주세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Keep the lips softly closed. Move the tongue inside the mouth to push the upper lip outward from behind, return, then push the lower lip outward from behind, creating a gentle monkey-face shape, then relax.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/tongue_09_monkey_lips/v001/exports/tongue_09_monkey_lips_v001_review.mp4

## tongue_10_molars — 양쪽 어금니 대기

- 제작 순서: 파일럿 검토 후
- 지시문: 혀끝을 왼쪽과 오른쪽 어금니에 번갈아 대세요.
- 길이: 5초 / 120프레임
- 시각 모드: oralCutaway / 안전 등급: general
- 동작 초안: Move the tongue tip to touch the left back molar area, return to center, then touch the right back molar area and return. Keep the jaw still.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/tongue_10_molars/v001/exports/tongue_10_molars_v001_review.mp4

## tongue_11_trace_teeth — 치아 차례로 훑기

- 제작 순서: 파일럿 검토 후
- 지시문: 이를 하나씩 확인하듯 혀끝으로 윗니와 아랫니를 차례로 훑으세요.
- 길이: 7초 / 168프레임
- 시각 모드: oralCutaway / 안전 등급: general
- 동작 초안: Use the tongue tip to trace each upper tooth from one side to the other, then trace the lower teeth back in the opposite direction, like checking the teeth one by one.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/tongue_11_trace_teeth/v001/exports/tongue_11_trace_teeth_v001_review.mp4

## tongue_13_clock_click — 똑딱 소리 내기

- 제작 순서: 파일럿 검토 후
- 지시문: 혀끝을 윗니 뒤쪽에 붙였다 떼며 똑딱 소리를 내보세요.
- 길이: 5초 / 120프레임
- 시각 모드: oralCutaway / 안전 등급: general
- 동작 초안: Demonstrate a gentle clock-like tongue click: lift the tongue tip to the alveolar ridge behind the upper front teeth, create contact, release cleanly, and return to neutral in an even rhythm.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/tongue_13_clock_click/v001/exports/tongue_13_clock_click_v001_review.mp4

## tongue_14_tongue_click — 혀 차기 연습

- 제작 순서: 파일럿 검토 후
- 지시문: 강아지를 부르듯 혀 차기 소리를 천천히 반복하세요.
- 길이: 5초 / 120프레임
- 시각 모드: faceCloseUp / 안전 등급: general
- 동작 초안: Open the lips slightly and demonstrate a clear gentle tongue-click calling motion, repeating three evenly paced contact-and-release cycles, then return to a relaxed mouth.
- 얼굴 연동 기준: 중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. 정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. 혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.
- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.
- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기
- 검토용 영상: output/training_video/tongue_14_tongue_click/v001/exports/tongue_14_tongue_click_v001_review.mp4
