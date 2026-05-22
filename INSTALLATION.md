# PayTrack Installation Guide

## Quick Start (5 minutes)

### Step 1: Install Flutter

Download from [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)

Verify installation:

```bash
flutter doctor
```

Resolve any issues shown (Android SDK, Xcode for iOS, etc.).

### Step 2: Get the project

```bash
cd c:\Users\USER\Downloads\tracker
flutter pub get
```

### Step 3: Connect a device

**Android:** Enable USB debugging, connect phone, run `flutter devices`

**iOS (Mac only):** Open Simulator or connect iPhone

### Step 4: Run the app

```bash
flutter run
```

First launch shows onboarding, then optional PIN setup, then dashboard with sample expenses.

---

## Building APK for Android

### Debug APK (testing)

```bash
flutter build apk --debug
```

File: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (distribution)

```bash
flutter build apk --release
```

File: `build/app/outputs/flutter-apk/app-release.apk`

Install on device:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Split APKs by ABI (smaller size)

```bash
flutter build apk --release --split-per-abi
```

---

## Signing release builds (production)

1. Create keystore:

```bash
keytool -genkey -v -keystore paytrack-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias paytrack
```

2. Create `android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=paytrack
storeFile=../paytrack-release.jks
```

3. Update `android/app/build.gradle.kts` with signing config (see Flutter docs).

4. Build:

```bash
flutter build apk --release
```

---

## iOS Build

Requires macOS with Xcode:

```bash
cd ios
pod install
cd ..
flutter build ios --release
```

Open `ios/Runner.xcworkspace` in Xcode → Product → Archive.

---

## Environment notes

| Requirement | Version |
|-------------|---------|
| Flutter | 3.41+ stable |
| Dart | 3.11+ |
| Android min SDK | 21 (from Flutter default) |
| iOS | 12.0+ |

---

## Troubleshooting

### `flutter pub get` fails

Run `flutter upgrade` then retry.

### Camera not working

Grant camera permission in device Settings → Apps → PayTrack.

### UPI app not listed

Install GPay/PhonePe on device. Android 11+ requires package queries (already in manifest).

### UPI launch fails

Try "Other UPI apps" option to use system chooser.

### Build fails on Windows for iOS

iOS builds require macOS. Use Android APK on Windows.

---

## ZIP distribution

To share the project:

1. Delete `build/`, `.dart_tool/` folders
2. Zip the `tracker` folder
3. Recipient runs `flutter pub get` then `flutter run`
