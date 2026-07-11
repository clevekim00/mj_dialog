# Tongue Exercise Animation for Blender 4.x

이 폴더는 발음/재활용 혀 운동을 설명하기 위한 교육용 3D 애니메이션 예제 생성 스크립트를 포함합니다.

의학적으로 정확한 해부학 모델이 아니라, 실제 혀 3D 모델이나 더 정교한 구강 구조로 교체하기 쉬운 절차적 시각화 예제입니다.

## 생성되는 파일

스크립트를 실행하면 같은 폴더에 다음 파일이 생성됩니다.

- `tongue_exercise_animation.blend`
- `tongue_exercise_animation.glb`

## Flutter 앱 연동

Flutter 앱은 `model_viewer_plus`로 아래 asset을 표시합니다.

```text
/Users/youngwhankim/Project/mj_dialog/assets/models/tongue_exercise_preview.glb
```

Blender에서 생성한 `tongue_exercise_animation.glb`를 앱에 반영하려면 생성된 GLB를 위 경로의 파일로 교체합니다.

```bash
cp /Users/youngwhankim/Project/mj_dialog/blender_tongue_exercise/tongue_exercise_animation.glb \
  /Users/youngwhankim/Project/mj_dialog/assets/models/tongue_exercise_preview.glb
```

앱 표시 위치:

- 혀운동 준비 화면의 `3D 혀 운동 미리보기`
- 혀운동 진행 화면의 현재 운동 카드 상단

## 실행 명령어

Blender 4.x가 설치되어 있고 `blender` 명령어가 PATH에 잡혀 있다면 아래처럼 실행합니다.

```bash
cd /Users/youngwhankim/Project/mj_dialog/blender_tongue_exercise
blender --background --python create_tongue_exercise_animation.py
```

Blender 앱 경로를 직접 지정해야 하는 macOS 환경에서는 예를 들어 아래처럼 실행할 수 있습니다.

```bash
/Applications/Blender.app/Contents/MacOS/Blender --background --python create_tongue_exercise_animation.py
```

## 포함된 구성

- 반투명 얼굴/입 단면
- 윗니와 아랫니
- 입천장
- 여러 control point 단면으로 만든 부드러운 혀 메시
- Shape Key 기반 혀 운동 애니메이션
- 운동별 방향 화살표
- 운동별 Scene Marker
- 카메라 앞 현재 운동명 3D 텍스트
- 24fps 타임라인
- 각 운동 3초, 운동 사이 1초 중립 복귀
- `.blend` 저장 및 `.glb` export

## 포함된 혀 운동

- 중립 자세
- 혀 앞으로 내밀기
- 혀 안으로 넣기
- 혀 위로 올리기
- 혀 아래로 내리기
- 혀 왼쪽 이동
- 혀 오른쪽 이동
- 혀 원형 돌리기

## 나중에 실제 모델로 교체하는 위치

혀 생성 로직은 `create_tongue()` 함수에 분리되어 있습니다. 실제 혀 모델을 쓰려면 이 함수에서 외부 메시를 불러오고, 기존 Shape Key 이름만 유지하거나 운동별 Shape Key를 새 모델에 다시 연결하면 됩니다.

운동 목록과 타이밍은 `exercise_segments()`와 `animate_timeline()`에서 조정할 수 있습니다.
