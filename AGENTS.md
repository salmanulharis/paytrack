# AGENTS.md — PayTrack

UPI expense tracker: tag expenses **before** UPI payment; confirm on app resume.

## Stack

Flutter 3.11+ · Riverpod · GoRouter · Hive · Material 3 · `mobile_scanner` · `fl_chart`

## Entry

`lib/main.dart` → Hive init, sample seed, `ProviderScope` → `lib/app.dart`

## Where to edit

| Task | File(s) |
|------|---------|
| Routes | `lib/core/router/app_router.dart` |
| Providers / settings state | `lib/core/providers/app_providers.dart` |
| User prefs (note, limits) | `UserPreferences`, `userPreferencesProvider`, `settings_screen.dart` |
| Hive DB | `lib/data/datasources/local/hive_storage.dart` |
| UPI parse / pay | `upi_parser_service.dart`, `payment_flow_service.dart`, `MainActivity.kt` |
| Limits | `spending_limit_service.dart`, `limit_progress_card.dart` |
| Backup | `backup_service.dart`, `backup_screen.dart` |
| Dashboard actions | `paytrack_bottom_nav.dart` (`PayTrackBottomChrome`) |
| Payment / manual forms | `floating_form_scaffold.dart`, `expense_metadata_screen.dart` |
| Theme | `lib/core/theme/app_theme.dart` |

## UI chrome (dashboard)

```
[ Add expense | Scan QR ]   ← PayTrackDualActionBar (horizontal, equal width)
[ Home        | Analytics ] ← NavigationBar
```

Do **not** use vertical FAB stacks or center-docked FABs on the dashboard.

## Critical flows

1. **Scan** → `/metadata` → validate amount, tags, note (per `NoteFieldMode`) → UPI app → confirm sheet
2. **Merchant QR amount** — auto-fill; lock if `allowEditMerchantAmount == false`
3. **Limits** — check before pay; show `LimitProgressCard` on home when enabled

UPI apps do not return payment results; status is user-confirmed.

## Full index

See `CODEBASE_INDEX.md`.

## Commands

```bash
flutter pub get
flutter run
flutter analyze
flutter build apk --release
```

## Git

Commit `pubspec.lock`. Do not commit `build/`, `.dart_tool/`, `android/local.properties`, secrets.
