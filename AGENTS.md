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
| Home primary actions | `home_primary_actions.dart` |
| Tab navigation | `paytrack_bottom_nav.dart`, `main_tab_bottom_chrome.dart` |
| Category drill-down | `category_expenses_sheet.dart` |
| Expenses history | `monthly_expenses_screen.dart` (route `/expenses`) |
| Edit expense | `/edit-expense/:id` → `manual_expense_screen.dart` |
| Payment / manual forms | `floating_form_scaffold.dart`, `expense_metadata_screen.dart` |
| Theme | `lib/core/theme/app_theme.dart` |

## UI chrome (dashboard)

```
[ Add Expense | Scan QR ] ← HomePrimaryActions (Home only, below spending card)
[ Home | Monthly | Analytics ] ← NavigationBar
```

Primary actions live **only** on Home. Do **not** use vertical FAB stacks or duplicate action bars on other tabs.

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
flutter test
flutter build apk --release
flutter build appbundle --release
```

Release signing and store deployment: see [RELEASE.md](RELEASE.md).

## Git

Commit `pubspec.lock`. Do not commit `build/`, `.dart_tool/`, `android/local.properties`, secrets.
