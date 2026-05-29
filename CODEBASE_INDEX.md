# PayTrack Codebase Index

> **App:** PayTrack (`upi_expense_tracker`) — UPI-first expense tracker  
> **Package:** `com.upitracker.upi_expense_tracker`  
> **Version:** 1.0.0+1 · Flutter SDK ^3.11.1  
> **Entry:** `lib/main.dart` → `lib/app.dart` (`PayTrackApp`)  
> **Dart files:** 57 under `lib/` · 1 test under `test/`

---

## Quick lookup

| I want to… | Go to |
|------------|--------|
| App bootstrap | `lib/main.dart`, `lib/app.dart` |
| Routes + shell (lock, resume) | `lib/core/router/app_router.dart` |
| Riverpod DI | `lib/core/providers/app_providers.dart` |
| Theme / colors | `lib/core/theme/app_theme.dart` |
| User settings (note mode, limits) | `userPreferencesProvider`, `settings_screen.dart` |
| Pref / Hive key names | `lib/core/constants/app_constants.dart` |
| UPI QR parse / URI build | `lib/core/services/upi_parser_service.dart` |
| Launch GPay / PhonePe | `upi_payment_service.dart`, `upi/upi_android_launcher.dart`, `upi/upi_ios_uri_builder.dart`, `android/.../MainActivity.kt` |
| Platform guards (no `dart:io`) | `lib/core/platform/app_platform.dart` |
| Payment pending → confirm | `payment_flow_service.dart`, `payment_confirmation_sheet.dart` |
| Lock grace during UPI / scanner | `auth_session_service.dart`, `_AppShell` in `app_router.dart` |
| Hive persistence | `lib/data/datasources/local/hive_storage.dart` |
| Spending limits + compensation | `lib/core/services/spending_limit_service.dart` |
| Backup import/export | `lib/core/services/backup_service.dart`, `backup_screen.dart` |
| Bottom UI (Add + Scan + nav) | `lib/core/widgets/paytrack_bottom_nav.dart` |
| Floating payment forms | `lib/core/widgets/floating_form_scaffold.dart` |
| Default categories | `lib/core/constants/default_tags.dart` |
| Android UPI intents | `AndroidManifest.xml`, `MainActivity.kt` |

---

## Architecture

```
Presentation (features/*/presentation/)
        ↓ watch/read
Riverpod (core/providers/app_providers.dart)
        ↓
Services + Repositories
        ↓
HiveStorage (JSON in Hive boxes) + SharedPreferences + FlutterSecureStorage
```

**Pattern:** Feature-first clean architecture, offline-first, no code generation (no freezed/json_serializable).

See also: `ARCHITECTURE.md`, `AGENTS.md`, `.cursor/rules/paytrack-codebase.mdc`.

---

## Directory map (`lib/`)

```
lib/
├── main.dart                    # Hive init, sample seed, ProviderScope, notifications init
├── app.dart                     # PayTrackApp — MaterialApp.router
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart   # Hive box names, SharedPreferences keys
│   │   └── default_tags.dart    # Seeded ExpenseTag list
│   ├── platform/
│   │   └── app_platform.dart    # AppPlatformKind, supportsUpiPayments (no dart:io)
│   ├── theme/
│   │   └── app_theme.dart       # AppColors, light/dark ThemeData
│   ├── router/
│   │   └── app_router.dart      # GoRouter, redirect, _AppShell (lock + pending pay)
│   ├── providers/
│   │   └── app_providers.dart   # All Riverpod providers + notifiers
│   ├── services/
│   │   ├── upi_parser_service.dart
│   │   ├── upi_payment_service.dart      # MethodChannel com.upitracker/upi + url_launcher
│   │   ├── upi/
│   │   │   ├── upi_android_launcher.dart
│   │   │   └── upi_ios_uri_builder.dart
│   │   ├── payment_flow_service.dart
│   │   ├── auth_service.dart
│   │   ├── auth_session_service.dart     # Lock grace, suspend during external UPI
│   │   ├── analytics_service.dart
│   │   ├── notification_service.dart
│   │   ├── spending_limit_service.dart
│   │   └── backup_service.dart
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   └── tag_icon_helper.dart
│   └── widgets/
│       ├── paytrack_bottom_nav.dart      # PayTrackBottomChrome, DualActionBar, Nav
│       ├── floating_form_scaffold.dart
│       ├── limit_progress_card.dart
│       ├── merchant_amount_banner.dart
│       ├── glass_card.dart
│       ├── gradient_button.dart
│       ├── tag_chip.dart
│       └── expense_list_tile.dart
│
├── domain/entities/             # Pure Dart + equatable (no Flutter imports)
│
├── data/
│   ├── datasources/local/hive_storage.dart
│   ├── repositories/
│   │   ├── expense_repository.dart
│   │   └── tag_repository.dart
│
└── features/
    ├── onboarding/presentation/onboarding_screen.dart
    ├── auth/presentation/
    │   ├── pin_setup_screen.dart
    │   └── lock_screen.dart
    ├── dashboard/presentation/dashboard_screen.dart
    ├── scanner/presentation/scanner_screen.dart
    ├── payment/presentation/
    │   ├── expense_metadata_screen.dart
    │   ├── upi_app_picker_sheet.dart
    │   └── payment_confirmation_sheet.dart
    ├── expenses/presentation/
    │   ├── manual_expense_screen.dart
    │   ├── search_screen.dart
    │   └── expense_detail_screen.dart
    ├── analytics/presentation/analytics_screen.dart
    └── settings/presentation/
        ├── settings_screen.dart
        ├── manage_tags_screen.dart
        └── backup_screen.dart
```

---

## Complete Dart file inventory

### Entry & app
| File | Role |
|------|------|
| `main.dart` | Portrait lock, SharedPreferences override, Hive init, sample seed, notification init |
| `app.dart` | `PayTrackApp` — theme + `routerProvider` |

### Core — constants, platform, theme, router
| File | Role |
|------|------|
| `constants/app_constants.dart` | App name, Hive boxes, pref keys, backup version, limit threshold |
| `constants/default_tags.dart` | Default `ExpenseTag` definitions |
| `platform/app_platform.dart` | `AppPlatformKind`, `supportsUpiPayments`, `isMobilePlatform` |
| `theme/app_theme.dart` | Material 3 light/dark themes |
| `router/app_router.dart` | Routes, auth redirect, `_AppShell` lifecycle |

### Core — providers
| File | Role |
|------|------|
| `providers/app_providers.dart` | All providers; `ExpensesNotifier`, `TagsNotifier`, `ThemeModeNotifier`, `UserPreferencesNotifier` |

### Core — services
| File | Role |
|------|------|
| `services/upi_parser_service.dart` | Parse `upi://pay?pa=&am=&pn=`; build payment URIs |
| `services/upi_payment_service.dart` | List installed UPI apps; launch (Android channel / iOS URL) |
| `services/upi/upi_android_launcher.dart` | Android-specific launch helpers |
| `services/upi/upi_ios_uri_builder.dart` | iOS scheme-specific URI building |
| `services/payment_flow_service.dart` | Pending payment CRUD, launch, resume check, complete/cancel |
| `services/auth_service.dart` | Onboarding flag, PIN hash, biometrics, `shouldLock()` |
| `services/auth_session_service.dart` | Unlock grace period; suspend lock during UPI/scanner |
| `services/analytics_service.dart` | Totals, trends, tag breakdowns, calendar heatmap data |
| `services/notification_service.dart` | Local notifications (daily summary, weekly, budget) |
| `services/spending_limit_service.dart` | Daily/monthly limits, compensation rollover |
| `services/backup_service.dart` | JSON v1 export/import, optional AES encryption |

### Core — utils & widgets
| File | Role |
|------|------|
| `utils/currency_formatter.dart` | INR formatting |
| `utils/tag_icon_helper.dart` | Icon name → `IconData` |
| `widgets/paytrack_bottom_nav.dart` | `PayTrackBottomChrome`, `PayTrackDualActionBar`, `PayTrackBottomNav` |
| `widgets/floating_form_scaffold.dart` | Scroll body + pinned bottom CTA |
| `widgets/limit_progress_card.dart` | Daily/monthly limit UI on dashboard |
| `widgets/merchant_amount_banner.dart` | QR prefilled amount banner |
| `widgets/glass_card.dart` | Frosted card container |
| `widgets/gradient_button.dart` | Primary gradient CTA |
| `widgets/tag_chip.dart` | Selectable tag chip |
| `widgets/expense_list_tile.dart` | Expense row for lists |

### Domain entities
| File | Role |
|------|------|
| `entities/expense.dart` | Main expense model |
| `entities/expense_tag.dart` | Category tag |
| `entities/expense_status.dart` | `pending` \| `success` \| `failed` \| `cancelled` |
| `entities/upi_payment_data.dart` | Parsed UPI fields from QR/URI |
| `entities/pending_payment.dart` | In-flight payment before confirmation |
| `entities/upi_app_info.dart` | Known UPI apps (package, schemes, display name) |
| `entities/user_preferences.dart` | Note mode, limits, compensation, encrypted backup flag |
| `entities/note_field_mode.dart` | `mandatory` \| `optional` \| `disabled` |
| `entities/limit_status.dart` | Spent/limit/percent for progress cards |

### Data layer
| File | Role |
|------|------|
| `datasources/local/hive_storage.dart` | JSON in Hive boxes; tag usage increment |
| `repositories/expense_repository.dart` | CRUD + multi-filter `search()` |
| `repositories/tag_repository.dart` | Tag CRUD + create |
### Features (presentation)
| File | Role |
|------|------|
| `onboarding/onboarding_screen.dart` | First-run slides |
| `auth/pin_setup_screen.dart` | PIN + optional biometric setup |
| `auth/lock_screen.dart` | PIN/biometric unlock overlay |
| `dashboard/dashboard_screen.dart` | Home, recent expenses, limit cards, bottom chrome |
| `scanner/scanner_screen.dart` | `mobile_scanner` → navigate `/metadata` |
| `payment/expense_metadata_screen.dart` | Amount, tags, note → pay |
| `payment/upi_app_picker_sheet.dart` | Choose UPI app |
| `payment/payment_confirmation_sheet.dart` | Post-UPI success/fail/cancel |
| `expenses/manual_expense_screen.dart` | Manual entry (no UPI) |
| `expenses/search_screen.dart` | Filtered expense search |
| `expenses/expense_detail_screen.dart` | View/edit single expense |
| `analytics/analytics_screen.dart` | Charts (`fl_chart`), calendar (`table_calendar`) |
| `settings/settings_screen.dart` | All prefs UI |
| `settings/manage_tags_screen.dart` | Create/edit/delete tags |
| `settings/backup_screen.dart` | Export/import backup file |

---

## Routes (`GoRouter`)

| Path | Screen | Notes |
|------|--------|-------|
| `/onboarding` | OnboardingScreen | Redirect if not complete |
| `/pin-setup` | PinSetupScreen | Outside shell |
| `/lock` | LockScreen | Standalone route (shell uses inline lock) |
| `/` | DashboardScreen | Inside `ShellRoute` |
| `/scanner` | ScannerScreen | |
| `/metadata` | ExpenseMetadataScreen | `extra`: `upiId`, `merchantName`, `amount`, `rawUpiUri` |
| `/manual-expense` | ManualExpenseScreen | |
| `/expenses` | MonthlyExpensesScreen | Expenses tab — month-grouped history |
| `/edit-expense/:id` | ManualExpenseScreen | Edit existing expense |
| `/analytics` | AnalyticsScreen | |
| `/search` | SearchScreen | |
| `/settings` | SettingsScreen | |
| `/manage-tags` | ManageTagsScreen | |
| `/backup` | BackupScreen | |
| `/expense/:id` | ExpenseDetailScreen | `pathParameters['id']` |

**Redirect:** Incomplete onboarding → `/onboarding`; completed onboarding on `/onboarding` → `/`.

**Shell (`_AppShell`):**
- Cold start / resume → `AuthSessionService.shouldRequireLock()` → `LockScreen` overlay
- On pause/inactive during pending payment → `suspendLockForExternalFlow()`
- On resume → `PaymentFlowService.checkPendingOnResume()` → `PaymentConfirmationSheet`

---

## Riverpod providers

| Provider | Type | Role |
|----------|------|------|
| `sharedPreferencesProvider` | Provider | Overridden in `main()` |
| `secureStorageProvider` | Provider | `FlutterSecureStorage` |
| `hiveStorageProvider` | Provider | `HiveStorage.instance` |
| `expenseRepositoryProvider` | Provider | Expense CRUD + search |
| `tagRepositoryProvider` | Provider | Tag CRUD |
| `upiParserProvider` | Provider | QR / URI parse & build |
| `upiPaymentServiceProvider` | Provider | UPI app list + launch |
| `paymentFlowServiceProvider` | Provider | Pending lifecycle (uses `authSession`) |
| `authServiceProvider` | Provider | PIN, biometric, onboarding |
| `authSessionServiceProvider` | Provider | Lock grace + external-flow suspend |
| `analyticsServiceProvider` | Provider | Aggregations |
| `notificationServiceProvider` | Provider | Local notifications |
| `spendingLimitServiceProvider` | Provider | Daily/monthly limits |
| `backupServiceProvider` | Provider | JSON backup |
| `userPreferencesProvider` | StateNotifier | Live `UserPreferences` |
| `expensesProvider` | StateNotifier | `List<Expense>` |
| `tagsProvider` | StateNotifier | `List<ExpenseTag>` |
| `themeModeProvider` | StateNotifier | `ThemeMode` |
| `pendingPaymentProvider` | StateProvider | Active pending (UI) |
| `routerProvider` | Provider | `GoRouter` instance |

---

## Core user flows

### UPI pay flow
```
Scan QR → UpiParserService.parse
       → /metadata (amount*, tags*, note per NoteFieldMode)
       → merchant amount lock? (userPreferences.allowEditMerchantAmount)
       → limit check (SpendingLimitService)
       → UpiAppPickerSheet or default app
       → PaymentFlowService.startPaymentFlow → external UPI app
       → resume → PaymentConfirmationSheet → Expense saved (ExpensesNotifier)
```

UPI apps do **not** return payment results; status is user-confirmed on resume.

### Manual expense
```
Dashboard → Add expense → /manual-expense → FloatingFormScaffold → save (no UPI)
```

### Settings-driven behavior
- **Note field:** `NoteFieldMode` mandatory \| optional \| disabled
- **Merchant amount:** prefilled from QR `am`; `MerchantAmountBanner` + read-only if locked
- **Limits:** daily/monthly with `LimitProgressCard` on dashboard when enabled
- **Compensation:** yesterday overspend reduces today's effective daily limit (`compensation_excess_<date>` keys)
- **Backup:** format v1 JSON, optional AES, merge/replace import via `file_picker`
- **Lock grace:** `prefLockGraceMinutes` (default 3); suspended while UPI app open

### Dashboard chrome
`PayTrackBottomChrome` = `PayTrackDualActionBar` (Add expense \| Scan QR) + `NavigationBar` (Home \| Analytics)

Do **not** use vertical FAB stacks or center-docked FABs on the dashboard.

---

## Persistence

| Store | Keys / boxes |
|-------|----------------|
| Hive `expenses` | Expense JSON (`AppConstants.hiveBoxExpenses`) |
| Hive `tags` | ExpenseTag JSON; seeded from `DefaultTags` if empty |
| Hive `pending_payments` | PendingPayment JSON |
| SharedPreferences | Onboarding, theme, UPI app prefs, notifications, limits, note mode, compensation excess per date, encrypted backup flag, lock grace |
| Secure storage | PIN hash (`prefPinHash`) |

`hiveBoxSettings` is defined in `AppConstants` but not opened in `HiveStorage` (reserved).

---

## Domain models (fields)

### Expense
`id`, `amount`, `tagIds[]`, `createdAt`, `notes?`, `merchantName?`, `upiId?`, `paymentAppId?`, `paymentAppName?`, `status`, `receiptPath?`, `paymentSource?`, `isManual`, `currency`

### UserPreferences
`noteFieldMode`, `allowEditMerchantAmount`, `dailyLimitEnabled/Amount`, `monthlyLimitEnabled/Amount`, `limitAlertsEnabled`, `compensationEnabled`, `encryptedBackup`

### LimitStatus
`spent`, `effectiveLimit`, `percentUsed`, warning/exceeded flags, user-facing messages

### PendingPayment
Links metadata entered pre-launch to confirmation sheet (`payment_flow_service`)

---

## Native / platform

| File | Purpose |
|------|---------|
| `android/.../MainActivity.kt` | `MethodChannel('com.upitracker/upi')`: `getInstalledUpiApps`, `launchUpiIntent`, `launchUpiChooser` |
| `android/.../AndroidManifest.xml` | Camera, notifications, UPI `<queries>` for package visibility |
| `android/app/build.gradle.kts` | Core library desugaring |
| `ios/Runner/Info.plist` | Camera, photos, Face ID usage strings |
| `ios/Runner/AppDelegate.swift` | Standard Flutter host |

**Cross-platform UPI:** Android uses native intents; iOS probes `canLaunchUrl` on known schemes and builds URIs via `upi_ios_uri_builder.dart`. `app_platform.dart` gates features without `dart:io`.

---

## Dependencies (grouped)

| Area | Packages |
|------|----------|
| State / nav | `flutter_riverpod`, `go_router` |
| Storage | `hive`, `hive_flutter`, `shared_preferences`, `flutter_secure_storage`, `path_provider` |
| UPI / device | `mobile_scanner`, `url_launcher`, `android_intent_plus`, `permission_handler` |
| Security | `local_auth`, `crypto`, `encrypt` |
| UI | `google_fonts`, `flutter_animate`, `fl_chart`, `percent_indicator`, `smooth_page_indicator`, `table_calendar` |
| Media / files | `image_picker`, `file_picker`, `share_plus` |
| Other | `intl`, `uuid`, `equatable`, `collection`, `csv`, `package_info_plus`, `flutter_local_notifications`, `timezone` |

---

## Project layout (repo root)

| Path | Purpose |
|------|---------|
| `lib/` | Application source (57 Dart files) |
| `test/widget_test.dart` | Default Flutter widget smoke test |
| `android/`, `ios/` | Platform projects |
| `assets/images/`, `assets/lottie/` | Declared in `pubspec.yaml` (may be empty locally) |
| `.github/workflows/ios.yml` | iOS CI workflow |
| `README.md` | Overview, build commands |
| `INSTALLATION.md` | Setup guide |
| `ARCHITECTURE.md` | Layer design, payment state machine |
| `CODEBASE_INDEX.md` | This file |
| `AGENTS.md` | AI agent quick reference |
| `.cursor/rules/paytrack-codebase.mdc` | Cursor always-on rule |

---

## Commands

```bash
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --release
```

---

## Conventions

1. New screen → `features/<name>/presentation/<name>_screen.dart` + route in `app_router.dart`
2. New pref → `AppConstants` key + `UserPreferences` field + `UserPreferencesNotifier.update`
3. New UPI app → `UpiAppInfo.knownApps` + `MainActivity.kt` queries + `AndroidManifest.xml` `<queries>`
4. Payment / manual forms → `FloatingFormScaffold` for pinned bottom CTA
5. Dashboard actions → extend `PayTrackDualActionBar`, not floating FAB stacks
6. Platform checks → `app_platform.dart` (`supportsUpiPayments`), not raw `Platform.isAndroid`

---

*Last indexed: 2026-05-29 — PayTrack v1.0.0+1, 57 Dart files under `lib/`.*
