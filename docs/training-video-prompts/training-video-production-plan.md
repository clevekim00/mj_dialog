# 재활 훈련 영상 제작 프롬프트·자막 명세

## 제작 기준

- 참조 재생목록: https://youtube.com/playlist?list=PLFMpyPN1dRzY
- 참조 캐릭터: `assets/images/ai_speech_2d_tutor.png`
- 영상 생성: Higgsfield Seedance 계열, 16:9, 720p, 5~6초, 무음 루프
- 캐릭터는 동일한 성인 여성 2D 재활 안내자, 흰색 임상복, 짙은 포니테일을 유지한다.
- 정면 상반신 또는 얼굴 클로즈업, 고정 카메라, 입·혀·볼 움직임을 가리지 않는다.
- 생성 영상에는 글자를 넣지 않는다. 앱이 설정값을 반영한 자막을 오버레이한다.
- 모든 동작은 통증이 없는 범위에서 천천히 수행하는 일반 안내이며 의료진 지시를 우선한다.

## 공통 프롬프트 접두어

> Use the exact same adult female 2D anime rehabilitation therapist from the reference image, same face, dark ponytail and white clinician uniform. Clean warm speech therapy clinic, front-facing close-up, locked camera, no UI, no text. Slow, gentle, anatomically plausible clinical demonstration. Keep the head still and make the target oral movement clearly visible.

## 영상별 프롬프트와 자막

| 파일 | 훈련 | 동작 프롬프트 핵심 | 앱 자막 템플릿 |
|---|---|---|---|
| `01_tongue_out.mp4` | 혀 내밀기 | Extend tongue straight forward, hold, return; jaw still; seamless loop. | `혀를 앞으로 내밀었다 돌아오세요. {repeatCount}회 반복하세요.` |
| `02_tongue_side.mp4` | 혀 좌우 | Move tongue tip left corner, right corner, center; head still. | `고개는 고정하고 혀만 좌우로 움직이세요. {repeatCount}회 반복하세요.` |
| `03_tongue_up_down.mp4` | 혀 위아래 | Move tongue tip to upper lip, center, lower lip, center. | `혀끝을 위와 아래로 천천히 움직이세요. {repeatCount}회 반복하세요.` |
| `04_tongue_circle.mp4` | 혀 원 그리기 | Trace a slow circle around the lip edge and return. | `혀끝으로 입술 둘레를 천천히 돌리세요. 방향별 {repeatCount}회 반복하세요.` |
| `05_cheek_press.mp4` | 볼 안쪽 밀기 | Closed lips, press left cheek then right with tongue. | `혀로 양쪽 볼 안쪽을 번갈아 미세요. 각 {repeatCount}회 반복하세요.` |
| `06_mouth_open_close.mp4` | 입 벌리고 다물기 | Open comfortably, hold, close softly. | `입을 편안하게 벌렸다 부드럽게 다무세요. {repeatCount}회 반복하세요.` |
| `07_lip_round_smile.mp4` | 오·이 입술 | Alternate rounded puckered lips and broad relaxed smile. | `입술을 오 모양으로 모았다 이 모양으로 웃으세요. {repeatCount}회 반복하세요.` |
| `08_cheek_puff.mp4` | 볼 부풀리기 | Close lips and inflate both cheeks evenly, then relax. | `입술을 다물고 양쪽 볼을 천천히 부풀리세요. {repeatCount}회 반복하세요.` |
| `09_diaphragmatic_breath.mp4` | 호흡 | Hand on abdomen; inhale through nose, abdomen rises; slow pursed-lip exhale. | `코로 들이마시고 입으로 천천히 내쉬세요. {repeatCount}회 반복하세요.` |
| `10_sustained_voice.mp4` | 지속 발성 | Upright posture; relaxed inhale; sustain Korean vowel 아 with steady open mouth. | `편안한 높이로 아 소리를 길게 내세요. {repeatCount}회 반복하세요.` |

## 자막 처리

`{repeatCount}`는 영상 파일에 굽지 않는다. `TrainingSettingsService`가 앱 설정에서 기본값 또는 훈련별 값을 읽고 재생 시점에 치환한다. 향후 배포용 고정 영상에 자막을 굽는 경우에도 먼저 최종 음성을 Whisper로 타이밍한 뒤 `clean` 스타일을 사용한다.

## 출처 활용 원칙

재생목록 영상은 운동 종류와 임상 설명을 조사하기 위한 참고 자료로만 사용한다. 원본 영상, 프레임, 음성, 자막을 복제하거나 앱에 재배포하지 않고, 앱 캐릭터로 새로운 짧은 시범 영상을 제작한다.
