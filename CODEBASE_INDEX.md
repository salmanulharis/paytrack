# PayTrack Codebase Index

> **App:** PayTrack (`upi_expense_tracker`) — Flutter UPI expense tracker  
> **Package:** `com.upitracker.upi_expense_tracker`  
> **Entry:** `lib/main.dart` → `lib/app.dart` (`PayTrackApp`)

---

## Quick navigation

| I want to… | Go to |
|------------|--------|
| Change startup / init | `lib/main.dart` |
| Add a route | `lib/core/router/app_router.dart` |
| Add Riverpod provider | `lib/core/providers/app_providers.dart` |
| Change theme / colors | `lib/core/theme/app_theme.dart` |
| UPI QR parsing | `lib/core/services/upi_parser_service.dart` |
| Launch GPay / PhonePe | `lib/core/services/upi_payment_service.dart` + `android/.../MainActivity.kt` |
| Payment pending → confirm flow | `lib/core/services/payment_flow_service.dart`, `payment_confirmation_sheet.dart` |
| Persist expenses | `lib/data/datasources/local/hive_storage.dart` |
| Default categories | `lib/core/constants/default_tags.dart` |
| Android permissions / UPI queries | `android/app/src/main/AndroidManifest.xml` |

---

## Directory map (`lib/`)

```
lib/
├── main.dart                          # Hive init, SharedPreferences, sample seed, runApp
├── app.dart                           # MaterialApp.router, themeMode, GoRouter
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # Hive box names, pref keys, timeouts
│   │   └── default_tags.dart          # 15 seeded ExpenseTag definitions
│   ├── theme/
│   │   └── app_theme.dart             # AppColors, light()/dark(), Plus Jakarta Sans
│   ├── router/
│   │   └── app_router.dart            # GoRouter routes, _AppShell (lock + pending payment)
│   ├── providers/
│   │   └── app_providers.dart         # All Riverpod providers + ExpensesNotifier, TagsNotifier
│   ├── services/
│   │   ├── upi_parser_service.dart    # parse(), buildUpiUri() — upi://pay?pa=&am=&pn=
│   │   ├── upi_payment_service.dart     # MethodChannel com.upitracker/upi
│   │   ├── payment_flow_service.dart  # startPaymentFlow, completePayment, pending on resume
│   │   ├── auth_service.dart          # PIN hash, biometric, onboarding flag
│   │   ├── analytics_service.dart     # totals, charts, insights, heatmap
│   │   └── notification_service.dart # flutter_local_notifications schedules
│   ├── utils/
│   │   ├── currency_formatter.dart    # ₹ formatting (INR)
│   │   └── tag_icon_helper.dart       # iconName → IconData, color palette
│   └── widgets/
│       ├── glass_card.dart
│       ├── gradient_button.dart
│       ├── expense_list_tile.dart
│       └── tag_chip.dart
│
├── domain/entities/                   # Pure models (Equatable, toJson/fromJson)
│   ├── expense.dart
│   ├── expense_tag.dart
│   ├── expense_status.dart            # pending | success | failed | cancelled
│   ├── upi_payment_data.dart
│   ├── pending_payment.dart
│   └── upi_app_info.dart              # knownApps: gpay, phonepe, paytm, cred, jupiter, bhim…
│
├── data/
│   ├── datasources/local/
│   │   └── hive_storage.dart          # Singleton; JSON in Hive boxes
│   ├── repositories/
│   │   ├── expense_repository.dart    # CRUD + search(filters)
│   │   └── tag_repository.dart
│   └── sample/
│       └── sample_data_seeder.dart    # First-launch demo expenses
│
└── features/                          # UI only (presentation/)
    ├── onboarding/presentation/onboarding_screen.dart
    ├── auth/presentation/
    │   ├── pin_setup_screen.dart
    │   └── lock_screen.dart
    ├── dashboard/presentation/dashboard_screen.dart
    ├── scanner/presentation/scanner_screen.dart      # mobile_scanner
    ├── payment/presentation/
    │   ├── expense_metadata_screen.dart              # amount + tags before pay
    │   ├── upi_app_picker_sheet.dart
    │   └── payment_confirmation_sheet.dart
    ├── expenses/presentation/
    │   ├── manual_expense_screen.dart
    │   ├── search_screen.dart
    │   └── expense_detail_screen.dart
    ├── analytics/presentation/analytics_screen.dart  # fl_chart, table_calendar
    └── settings/presentation/
        ├── settings_screen.dart
        └── manage_tags_screen.dart
```

---

## Routes (`GoRouter`)

| Path | Screen | Notes |
|------|--------|-------|
| `/onboarding` | OnboardingScreen | Redirect if not complete |
| `/pin-setup` | PinSetupScreen | Optional 4-digit PIN |
| `/lock` | LockScreen | Standalone route (shell uses overlay) |
| `/` | DashboardScreen | Home, FAB scan + manual |
| `/scanner` | ScannerScreen | QR → `/metadata` with `extra` |
| `/metadata` | ExpenseMetadataScreen | `extra`: upiId, merchantName, amount |
| `/manual-expense` | ManualExpenseScreen | |
| `/analytics` | AnalyticsScreen | |
| `/search` | SearchScreen | |
| `/settings` | SettingsScreen | |
| `/manage-tags` | ManageTagsScreen | |
| `/expense/:id` | ExpenseDetailScreen | |

**Shell (`_AppShell`):** App resume → `PaymentFlowService.checkPendingOnResume()` → `PaymentConfirmationSheet.show()`.

---

## Riverpod providers

| Provider | Type | Purpose |
|----------|------|---------|
| `sharedPreferencesProvider` | Provider | Overridden in `main.dart` |
| `hiveStorageProvider` | Provider | `HiveStorage.instance` |
| `expenseRepositoryProvider` | Provider | |
| `tagRepositoryProvider` | Provider | |
| `upiParserProvider` | Provider | |
| `upiPaymentServiceProvider` | Provider | |
| `paymentFlowServiceProvider` | Provider | |
| `authServiceProvider` | Provider | |
| `analyticsServiceProvider` | Provider | |
| `notificationServiceProvider` | Provider | |
| `expensesProvider` | StateNotifierProvider | `List<Expense>` |
| `tagsProvider` | StateNotifierProvider | `List<ExpenseTag>` |
| `themeModeProvider` | StateNotifierProvider | `ThemeMode` |
| `pendingPaymentProvider` | StateProvider | `PendingPayment?` |
| `routerProvider` | Provider | `GoRouter` |

---

## Hive storage

| Box constant | Content |
|--------------|---------|
| `expenses` | `Expense` JSON by id |
| `tags` | `ExpenseTag` JSON by id |
| `pending_payments` | `PendingPayment` JSON by id |

**API highlights:** `getAllExpenses`, `saveExpense`, `getLatestPending`, `exportJson`, `importJson`, `clearAllData`.

---

## UPI payment flow (end-to-end)

```
ScannerScreen.onDetect
  → UpiParserService.parse(raw)
  → context.push('/metadata', extra: { upiId, merchantName, amount })

ExpenseMetadataScreen._pay
  → UpiAppPickerSheet.show (or default app from prefs)
  → PaymentFlowService.startPaymentFlow
       → builds upi:// URI
       → saves PendingPayment
       → UpiPaymentService.launchPayment (Android intent / url_launcher)

User returns to app
  → _AppShell.didChangeAppLifecycleState(resumed)
  → checkPendingOnResume
  → PaymentConfirmationSheet → completePayment(status)
  → Expense saved via ExpenseRepository
```

**Android channel:** `com.upitracker/upi`  
Methods: `getInstalledUpiApps`, `launchUpiIntent`, `launchUpiChooser`

---

## Domain models (fields)

### `Expense`
`id`, `amount`, `tagIds[]`, `createdAt`, `notes?`, `merchantName?`, `upiId?`, `paymentAppId?`, `paymentAppName?`, `status`, `receiptPath?`, `paymentSource?`, `isManual`, `currency`

### `ExpenseTag`
`id`, `name`, `iconName`, `colorValue` (ARGB int), `usageCount`

### `PendingPayment`
`id`, `amount`, `tagIds[]`, `upiId`, `startedAt`, `merchantName?`, `notes?`, `paymentAppId?`, `paymentAppName?`, `transactionNote?`

---

## SharedPreferences keys (`AppConstants`)

| Key | Usage |
|-----|--------|
| `onboarding_done` | Skip onboarding |
| `pin_hash` | In secure storage, not prefs |
| `biometric_enabled` | |
| `theme_mode` | light / dark / system |
| `default_upi_app` | App id string |
| `always_use_default_app` | Skip picker |
| `last_upi_app` | Recommended badge |
| `upi_app_usage_<id>` | Usage counts |
| `notifications_enabled`, `daily_summary_notif`, `weekly_report_notif`, `budget_alerts` | |

---

## Native / platform

| File | Role |
|------|------|
| `android/app/src/main/kotlin/.../MainActivity.kt` | UPI MethodChannel |
| `android/app/src/main/AndroidManifest.xml` | Camera, notifications, `<queries>` for UPI packages |
| `android/app/build.gradle.kts` | Core library desugaring (notifications) |
| `ios/Runner/Info.plist` | Camera, photos, Face ID strings |

---

## Dependencies (`pubspec.yaml`)

| Package | Use |
|---------|-----|
| flutter_riverpod | State |
| go_router | Navigation |
| hive / hive_flutter | Local DB |
| mobile_scanner | QR |
| url_launcher | iOS UPI |
| local_auth, flutter_secure_storage | Security |
| fl_chart, table_calendar, percent_indicator | Analytics UI |
| flutter_animate, google_fonts | UI |
| flutter_local_notifications, timezone | Notifications |
| permission_handler, image_picker, share_plus | Permissions, receipts, export |

---

## Tests & docs

| File | Purpose |
|------|---------|
| `test/widget_test.dart` | Smoke test PayTrackApp |
| `README.md` | User docs, build APK |
| `INSTALLATION.md` | Setup guide |
| `ARCHITECTURE.md` | Layer design |
| `CODEBASE_INDEX.md` | This file |
| `AGENTS.md` | AI agent quick reference |

---

## Conventions for contributors

- **New feature screen:** `lib/features/<name>/presentation/<name>_screen.dart` + route in `app_router.dart`
- **New persisted field:** Update entity `toJson`/`fromJson`, `HiveStorage`, repository if needed
- **New UPI app:** Add to `UpiAppInfo.knownApps` + `MainActivity.kt` `upiPackages` + manifest `<queries>`
- **State:** Prefer existing providers; extend `app_providers.dart`
- **No code generation:** Models are hand-written (no freezed/build_runner)

---

*Generated for PayTrack v1.0.0 — 43 Dart files under `lib/`.*
