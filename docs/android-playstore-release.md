# Android Play Store 출시

[한국어](android-playstore-release.md) | [English](android-playstore-release.en.md) | [전체 문서](README.md)

## 준비된 자료

- 런처 아이콘은 `android/app/src/main/res/mipmap-*`에 반영되어 있습니다.
- Play Store 아이콘은 `store_assets/icons/playstore_icon_512.png`에 있습니다.
- 패키지명: `com.clevekim00.speechrehab`.
- Android 매니페스트의 앱 표시명: `Speech Rehab`.

## 최초 서명 설정

이 작업공간에는 로컬 서명 파일이 준비되어 있습니다.

- `android/upload-keystore.jks`
- `android/key.properties`
- `android/release-signing-passwords.env`

이 파일은 Git에서 제외되며 커밋하면 안 됩니다.

다른 컴퓨터에서 다시 준비하려면 로컬에서 업로드 키 저장소를 만듭니다.

```bash
keytool -genkey -v \
  -keystore android/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

예제 파일로 `android/key.properties`를 만듭니다.

```bash
cp android/key.properties.example android/key.properties
```

다음을 입력합니다.

```properties
storePassword=<your keystore password>
keyPassword=<your key password>
keyAlias=upload
storeFile=../upload-keystore.jks
```

`android/key.properties`와 `android/upload-keystore.jks`를 커밋하지 마세요.
`android/.gitignore`에 제외 규칙이 있습니다.

## Play Store 번들 빌드

빌드 전에 Android SDK를 설치해야 합니다.

환경 확인:

```bash
flutter doctor -v
```

`Unable to locate Android SDK`가 나오면 Android Studio와 Android SDK를 설치하거나 기존 SDK 경로를 지정합니다.

```bash
flutter config --android-sdk /path/to/Android/sdk
```

빌드:

```bash
scripts/build_android_release.sh
```

출력:

```text
build/app/outputs/bundle/release/app-release.aab
```

이 `.aab` 파일을 Play Console에 업로드합니다.

## 제출 전 확인

- Play Console의 앱 이름, 간단한 설명, 자세한 설명, 스크린샷, 개인정보처리방침 URL과 데이터 보안 양식을 확인합니다.
- 발음 연습 음성을 녹음하므로 마이크 권한 설명을 확인합니다.
- 프로덕션 업로드마다 `pubspec.yaml`의 `version`을 올립니다.
- 디버그 서명을 대신 사용하지 말고 `scripts/build_android_release.sh`를 통해 `flutter build appbundle --release`를 실행합니다.
