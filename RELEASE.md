# PayTrack — Release Build Guide

## Prerequisites

```bash
flutter pub get
flutter analyze
flutter test
```

## Android release signing

1. Create a keystore (once):

   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy `android/key.properties.example` → `android/key.properties` and set paths/passwords.

3. Keep `upload-keystore.jks` and `key.properties` out of git.

If `key.properties` is missing, release builds use the debug keystore (local testing only).

## Build commands

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Play Store bundle
flutter build appbundle --release
```

Output:

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## iOS (macOS required)

```bash
flutter build ios --release
```

Configure signing in Xcode (`ios/Runner.xcworkspace`).

## Versioning

Update `version:` in `pubspec.yaml` (`major.minor.patch+buildNumber`).

## Pre-publish checklist

- [ ] `flutter analyze` — no errors
- [ ] `flutter test` — all pass
- [ ] Release build succeeds
- [ ] Onboarding → PIN → Home flow works
- [ ] QR scan + manual expense + backup export/import tested on device
- [ ] Light and dark themes reviewed
- [ ] Camera and notification permissions behave correctly on Android 13+
