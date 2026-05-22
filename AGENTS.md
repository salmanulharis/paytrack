# AGENTS.md — PayTrack

Flutter UPI expense tracker. Log expenses **before** UPI payment; confirm status on app resume.

## Stack

Flutter 3.41+ · Dart 3.11+ · Riverpod · GoRouter · Hive · Material 3

## Entry & boot

1. `lib/main.dart` — `HiveStorage.init()`, `SampleDataSeeder`, `ProviderScope` + `sharedPreferencesProvider` override
2. `lib/app.dart` — `PayTrackApp` → `routerProvider`, `themeModeProvider`

## Where to edit

| Task | Primary file(s) |
|------|-------------------|
| Routes | `lib/core/router/app_router.dart` |
| DI / global state | `lib/core/providers/app_providers.dart` |
| Local DB | `lib/data/datasources/local/hive_storage.dart` |
| UPI parse / URI build | `lib/core/services/upi_parser_service.dart` |
| UPI launch (Android) | `lib/core/services/upi_payment_service.dart`, `android/.../MainActivity.kt` |
| Payment lifecycle | `lib/core/services/payment_flow_service.dart` |
| Theme | `lib/core/theme/app_theme.dart` |
| Default tags | `lib/core/constants/default_tags.dart` |

## Feature folders

`lib/features/{onboarding,auth,dashboard,scanner,payment,expenses,analytics,settings}/presentation/`

## Critical flow

QR scan → `/metadata` (amount + tags required) → UPI app → resume → `PaymentConfirmationSheet` → `Expense` in Hive.

UPI apps do **not** return payment callbacks; status is user-confirmed.

## Full index

See `CODEBASE_INDEX.md` for routes, providers, models, prefs keys, and native files.

## Commands

```bash
flutter pub get
flutter run
flutter analyze
flutter build apk --release
```

## Do not

- Add freezed/build_runner without updating docs
- Commit `build/`, `.dart_tool/`
- Use `IconButton(selected:)` — not a valid parameter; use visual selection state on container
