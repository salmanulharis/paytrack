# PayTrack — UPI Expense Tracker

A production-ready Flutter app that tracks UPI expenses **before payment** — no bank SMS sync or API required. Scan a QR, tag the expense, pay via GPay/PhonePe/Paytm, and confirm when you return.

![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)

## Features

- **UPI-first workflow** — Scan QR → Enter amount & tags → Launch UPI app with prefilled details
- **Smart payment app picker** — Detects installed UPI apps, remembers last used, optional default app
- **Payment status handling** — Pending state + confirmation sheet on app resume
- **Premium fintech UI** — Material 3, glassmorphism, gradients, animations, dark/light themes
- **Analytics** — Charts, category breakdown, spending calendar, budget progress, insights
- **Offline-first** — Hive local database, no network required
- **Security** — PIN lock, biometric unlock, encrypted PIN storage
- **Notifications** — Daily summary, weekly report, pending payment reminders
- **Search & filters** — By date, category, status, amount, payment app
- **Manual expenses** — Add non-UPI expenses with receipt attachment
- **Export** — JSON backup via share sheet

## Architecture

```
lib/
├── main.dart                 # App entry + Hive init
├── app.dart                  # MaterialApp.router
├── core/
│   ├── constants/            # App constants, default tags
│   ├── theme/                # Light/dark themes
│   ├── router/               # GoRouter + app shell
│   ├── providers/            # Riverpod providers
│   ├── services/             # UPI, auth, analytics, notifications
│   ├── utils/                # Formatters, helpers
│   └── widgets/              # Reusable UI components
├── data/
│   ├── datasources/local/    # Hive storage
│   ├── repositories/         # Expense & tag repos
│   └── sample/               # Demo data seeder
├── domain/entities/          # Business models
└── features/
    ├── onboarding/
    ├── auth/
    ├── dashboard/
    ├── scanner/
    ├── payment/
    ├── expenses/
    ├── analytics/
    └── settings/
```

**Stack:** Flutter · Riverpod · GoRouter · Hive · mobile_scanner · fl_chart · local_auth

## Prerequisites

- Flutter SDK **3.41+** (stable channel)
- Android Studio / Xcode for device builds
- Physical Android or iPhone recommended for UPI testing (simulators cannot complete real payments)

## Installation

### 1. Clone and install dependencies

```bash
cd tracker
flutter pub get
```

### 2. Run on device/emulator

```bash
# List devices
flutter devices

# Run debug build
flutter run
```

### 3. Build release APK (Android)

```bash
# Debug APK
flutter build apk --debug

# Release APK (recommended for distribution)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 4. Build App Bundle (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 5. Build iOS

```bash
cd ios && pod install && cd ..
flutter build ios --release
# Open ios/Runner.xcworkspace in Xcode to archive
```

## UPI Payment Flow

1. User scans merchant UPI QR (`upi://pay?pa=...&am=...`)
2. App parses UPI ID, merchant name, optional amount
3. User enters amount (required) and selects ≥1 category tag
4. User picks payment app (or uses default if configured)
5. Android launches app-specific intent; iOS opens wallet deep link (`tez://`, `phonepe://`, etc.) or generic `upi://`
6. On return, confirmation sheet asks: *Was payment successful?*
7. Expense saved with status: success / failed / cancelled

> **Note:** UPI apps do not return payment callbacks to third-party apps. Confirmation is user-assisted by design (industry standard for expense trackers without NPCI verification APIs).

## UPI Integration (Android + iOS)

Both platforms use the same Flutter method channel: `com.upitracker/upi`.

| Method | Android (`MainActivity.kt`) | iOS (`AppDelegate.swift` / `UpiPlugin`) |
|--------|---------------------------|----------------------------------------|
| `getInstalledUpiApps` | Installed wallet package IDs | Probes URL schemes (`tez`, `phonepe`, `paytmmp`, …) |
| `launchUpiIntent` | `Intent` + `setPackage` | Wallet-specific URL, then `upi://pay` fallback |
| `launchUpiChooser` | Filtered wallet chooser | Opens generic `upi://pay` (system picker) |

Dart layer (`UpiPaymentService`):

- Android: `android_intent_plus` → method channel → `url_launcher`
- iOS: method channel → `UpiIosUriBuilder` → `url_launcher`
- Scanned QR payload is merged into payment URI on both platforms

iOS requires `LSApplicationQueriesSchemes` in `Info.plist` (configured).

## Configuration

| Setting | Location |
|---------|----------|
| App name | `android:label`, iOS `CFBundleDisplayName` |
| Default tags | `lib/core/constants/default_tags.dart` |
| Budget goal (demo) | `analytics_screen.dart` (₹50,000) |
| Payment timeout | `app_constants.dart` (120s) |

## Permissions

| Permission | Purpose |
|------------|---------|
| Camera | QR scanning |
| Notifications | Daily/weekly summaries |
| Biometric | App unlock |
| Photos | Receipt attachment |

## Project ZIP

To create a distributable ZIP:

```bash
# From parent directory
Compress-Archive -Path tracker -DestinationPath PayTrack-Flutter.zip
```

Exclude `build/`, `.dart_tool/` for smaller archives.

## Testing Checklist

- [ ] Onboarding → PIN setup → Dashboard
- [ ] Scan UPI QR (use any merchant QR)
- [ ] Complete metadata → Launch GPay/PhonePe
- [ ] Return to app → Confirm payment
- [ ] Manual expense entry
- [ ] Analytics charts render
- [ ] Search & filter
- [ ] Export JSON from Settings
- [ ] Dark mode toggle
- [ ] Biometric lock

## Optional Enhancements

Architecture is sync-ready for future:

- Firebase Auth / Cloud Firestore sync
- OCR receipt scanning (Google ML Kit)
- Voice expense logging
- Home screen widgets
- PDF/Excel export

## License

MIT — Use freely for personal and commercial projects.

## Support

For UPI issues: on Android 11+, ensure `<queries>` in `AndroidManifest.xml` lists wallet packages; on iOS, ensure wallet apps are installed and `LSApplicationQueriesSchemes` in `Info.plist` is present (both configured in this repo).
