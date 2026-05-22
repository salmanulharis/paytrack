# PayTrack Codebase Index

> **App:** PayTrack (`upi_expense_tracker`) — UPI-first expense tracker  
> **Package:** `com.upitracker.upi_expense_tracker`  
> **Entry:** `lib/main.dart` → `lib/app.dart`  
> **Dart files:** 53 under `lib/`

---

## Quick lookup

| I want to… | Go to |
|------------|--------|
| App bootstrap | `lib/main.dart`, `lib/app.dart` |
| Routes | `lib/core/router/app_router.dart` |
| Riverpod DI | `lib/core/providers/app_providers.dart` |
| Theme / colors | `lib/core/theme/app_theme.dart` |
| User settings (note mode, limits) | `userPreferencesProvider`, `settings_screen.dart` |
| UPI QR parse / URI build | `lib/core/services/upi_parser_service.dart` |
| Launch GPay / PhonePe | `upi_payment_service.dart`, `android/.../MainActivity.kt` |
| Payment pending → confirm | `payment_flow_service.dart`, `payment_confirmation_sheet.dart` |
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
Riverpod (core/providers/)
        ↓
Services + Repositories
        ↓
HiveStorage (JSON in Hive boxes) + SharedPreferences + SecureStorage
```

**Pattern:** Feature-first clean architecture, offline-first, no code generation.

---

## Directory map (`lib/`)

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/          app_constants.dart, default_tags.dart
│   ├── theme/              app_theme.dart (AppColors, light/dark)
│   ├── router/             app_router.dart (+ _AppShell lock/resume)
│   ├── providers/          app_providers.dart (all Riverpod)
│   ├── services/
│   │   ├── upi_parser_service.dart
│   │   ├── upi_payment_service.dart      # MethodChannel com.upitracker/upi
│   │   ├── payment_flow_service.dart
│   │   ├── auth_service.dart
│   │   ├── analytics_service.dart
│   │   ├── notification_service.dart
│   │   ├── spending_limit_service.dart
│   │   └── backup_service.dart
│   ├── utils/              currency_formatter, tag_icon_helper
│   └── widgets/
│       ├── paytrack_bottom_nav.dart      # PayTrackBottomChrome, DualActionBar
│       ├── floating_form_scaffold.dart
│       ├── limit_progress_card.dart
│       ├── merchant_amount_banner.dart
│       ├── glass_card, gradient_button, tag_chip, expense_list_tile
│
├── domain/entities/
│   ├── expense.dart, expense_tag.dart, expense_status.dart
│   ├── upi_payment_data.dart, pending_payment.dart, upi_app_info.dart
│   ├── user_preferences.dart, note_field_mode.dart, limit_status.dart
│
├── data/
│   ├── datasources/local/hive_storage.dart
│   ├── repositories/       expense_repository, tag_repository
│   └── sample/sample_data_seeder.dart
│
└── features/
    ├── onboarding/         onboarding_screen.dart
    ├── auth/               pin_setup_screen, lock_screen
    ├── dashboard/          dashboard_screen (+ limit cards, bottom chrome)
    ├── scanner/            scanner_screen (mobile_scanner)
    ├── payment/            metadata, upi_app_picker, confirmation_sheet
    ├── expenses/           manual, search, expense_detail
    ├── analytics/          analytics_screen (charts, calendar)
    └── settings/           settings, manage_tags, backup
```

---

## Routes (`GoRouter`)

| Path | Screen |
|------|--------|
| `/onboarding` | OnboardingScreen |
| `/pin-setup` | PinSetupScreen |
| `/lock` | LockScreen |
| `/` | DashboardScreen |
| `/scanner` | ScannerScreen |
| `/metadata` | ExpenseMetadataScreen — `extra`: upiId, merchantName, amount |
| `/manual-expense` | ManualExpenseScreen |
| `/analytics` | AnalyticsScreen |
| `/search` | SearchScreen |
| `/settings` | SettingsScreen |
| `/manage-tags` | ManageTagsScreen |
| `/backup` | BackupScreen |
| `/expense/:id` | ExpenseDetailScreen |

**Shell:** On resume → `checkPendingOnResume()` → `PaymentConfirmationSheet`.

---

## Riverpod providers

| Provider | Type | Role |
|----------|------|------|
| `sharedPreferencesProvider` | Provider | Overridden in `main()` |
| `hiveStorageProvider` | Provider | Singleton Hive |
| `expenseRepositoryProvider` | Provider | CRUD + search |
| `tagRepositoryProvider` | Provider | Tags CRUD |
| `upiParserProvider` | Provider | QR / URI |
| `upiPaymentServiceProvider` | Provider | Android intents |
| `paymentFlowServiceProvider` | Provider | Pending + launch |
| `authServiceProvider` | Provider | PIN / biometric |
| `analyticsServiceProvider` | Provider | Aggregations |
| `notificationServiceProvider` | Provider | Local notifications |
| `spendingLimitServiceProvider` | Provider | Daily/monthly limits |
| `backupServiceProvider` | Provider | JSON export/import |
| `userPreferencesProvider` | StateNotifier | Live settings |
| `expensesProvider` | StateNotifier | `List<Expense>` |
| `tagsProvider` | StateNotifier | `List<ExpenseTag>` |
| `themeModeProvider` | StateNotifier | ThemeMode |
| `pendingPaymentProvider` | StateProvider | Active pending |
| `routerProvider` | Provider | GoRouter |

---

## Core user flows

### UPI pay flow
```
Scan QR → UpiParserService.parse
       → /metadata (amount*, tags*, note per NoteFieldMode)
       → merchant amount lock? (userPreferences.allowEditMerchantAmount)
       → limit check (spendingLimitService)
       → UpiAppPickerSheet or default app
       → PaymentFlowService.startPaymentFlow → external UPI app
       → resume → PaymentConfirmationSheet → Expense saved
```

### Settings-driven behavior
- **Note field:** `NoteFieldMode` mandatory | optional | disabled
- **Merchant amount:** prefilled from QR `am`; banner + read-only if locked
- **Limits:** daily/monthly with `LimitProgressCard` on dashboard
- **Compensation:** yesterday overspend reduces today's effective daily limit
- **Backup:** v1 JSON, optional AES, merge/replace import via `file_picker`

### Dashboard chrome
`PayTrackBottomChrome` = `PayTrackDualActionBar` (Add expense | Scan QR) + `NavigationBar` (Home | Analytics)

---

## Persistence

| Store | Keys / boxes |
|-------|----------------|
| Hive `expenses` | Expense JSON |
| Hive `tags` | ExpenseTag JSON |
| Hive `pending_payments` | PendingPayment JSON |
| SharedPreferences | onboarding, theme, UPI app prefs, limits, note mode, compensation excess per date |
| Secure storage | PIN hash |

---

## Domain models (summary)

- **Expense** — amount, tagIds[], status, merchant, upiId, paymentApp*, notes, isManual, receiptPath
- **UserPreferences** — noteFieldMode, merchant amount edit, daily/monthly limits, alerts, compensation, encryptedBackup
- **LimitStatus** — spent, effectiveLimit, percentUsed, messages for UI cards
- **NoteFieldMode** — mandatory | optional | disabled

---

## Native / platform

| File | Purpose |
|------|---------|
| `android/.../MainActivity.kt` | `getInstalledUpiApps`, `launchUpiIntent`, `launchUpiChooser` |
| `android/.../AndroidManifest.xml` | Camera, notifications, UPI `<queries>` |
| `android/app/build.gradle.kts` | Core library desugaring |
| `ios/Runner/Info.plist` | Camera, photos, Face ID strings |

---

## Dependencies (high level)

Riverpod · GoRouter · Hive · mobile_scanner · fl_chart · flutter_animate · google_fonts · local_auth · flutter_secure_storage · flutter_local_notifications · encrypt · file_picker · share_plus · image_picker

---

## Docs & config

| File | Purpose |
|------|---------|
| `README.md` | Overview, build commands |
| `INSTALLATION.md` | Setup guide |
| `ARCHITECTURE.md` | Layer design |
| `CODEBASE_INDEX.md` | This file |
| `AGENTS.md` | AI agent quick reference |
| `.cursor/rules/paytrack-codebase.mdc` | Cursor always-on rule |
| `.gitignore` | Flutter/Android/iOS exclusions |

---

## Conventions

1. New screen → `features/<name>/presentation/` + route in `app_router.dart`
2. New pref → `AppConstants` + `UserPreferences` + `UserPreferencesNotifier`
3. New UPI app → `UpiAppInfo.knownApps` + `MainActivity.kt` + manifest queries
4. Payment forms → use `FloatingFormScaffold` for pinned CTA
5. Dashboard actions → extend `PayTrackDualActionBar`, not floating stacks

---

*Last indexed: PayTrack v1.0.0 — 53 Dart files.*
