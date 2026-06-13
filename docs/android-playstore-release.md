# Android Play Store Release

## Prepared Assets

- Launcher icons are updated under `android/app/src/main/res/mipmap-*`.
- Play Store icon is available at `store_assets/icons/playstore_icon_512.png`.
- Package name: `com.clevekim00.speechrehab`.
- App label in Android manifest: `Speech Rehab`.

## One-Time Signing Setup

This workspace already has local signing files prepared:

- `android/upload-keystore.jks`
- `android/key.properties`
- `android/release-signing-passwords.env`

These files are ignored by git and should not be committed.

To recreate the signing files on another machine, create an upload keystore locally:

```bash
keytool -genkey -v \
  -keystore android/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Then create `android/key.properties` from the example:

```bash
cp android/key.properties.example android/key.properties
```

Fill in:

```properties
storePassword=<your keystore password>
keyPassword=<your key password>
keyAlias=upload
storeFile=../upload-keystore.jks
```

Do not commit `android/key.properties` or `android/upload-keystore.jks`.
They are ignored by `android/.gitignore`.

## Build Play Store Bundle

Android SDK must be installed before building.

Current expected setup:

```bash
flutter doctor -v
```

If Flutter reports `Unable to locate Android SDK`, install Android Studio and Android SDK, or point Flutter to an existing SDK:

```bash
flutter config --android-sdk /path/to/Android/sdk
```

Then build:

```bash
scripts/build_android_release.sh
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

Upload this `.aab` to Play Console.

## Before Submission

- Confirm the Play Console app name, short description, full description, screenshots, privacy policy URL, and data safety form.
- Confirm microphone permission disclosure because the app records pronunciation practice audio.
- Increment `version` in `pubspec.yaml` for every production upload.
- Run `flutter build appbundle --release` through `scripts/build_android_release.sh`, not through a debug-signed fallback.
