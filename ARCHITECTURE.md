# PayTrack Architecture

## Overview

PayTrack follows **feature-first clean architecture** with clear separation between UI, business logic, and data layers.

```
Presentation → Providers (Riverpod) → Repositories → Local Storage (Hive)
                     ↓
                 Services (UPI, Auth, Analytics, Notifications)
```

## Layers

### Domain (`lib/domain/entities/`)

Pure Dart models with no framework dependencies:

- `Expense`, `ExpenseTag`, `UpiPaymentData`, `PendingPayment`, `UpiAppInfo`
- `ExpenseStatus` enum

### Data (`lib/data/`)

- **HiveStorage** — Single source of truth for JSON-serialized entities
- **ExpenseRepository** / **TagRepository** — CRUD + search queries
### Core Services (`lib/core/services/`)

| Service | Responsibility |
|---------|----------------|
| `UpiParserService` | Parse `upi://pay` URIs and QR payloads |
| `UpiPaymentService` | Android intents + iOS URL launcher |
| `PaymentFlowService` | Pending state, app usage tracking, completion |
| `AuthService` | PIN hash, biometrics, onboarding flag |
| `AnalyticsService` | Aggregations, insights, heatmaps |
| `NotificationService` | Scheduled local notifications |

### Presentation (`lib/features/`)

Each feature has a `presentation/` folder with screens. State flows through Riverpod:

- `expensesProvider` — Global expense list
- `tagsProvider` — Category tags
- `themeModeProvider` — Light/dark/system
- `routerProvider` — GoRouter with auth redirects

## Payment State Machine

```
[IDLE] → scan QR → [METADATA_ENTRY] → pick UPI app → [PENDING]
                                                      ↓
                                            launch external app
                                                      ↓
                                            app resumed → [CONFIRMATION]
                                                      ↓
                              success / failed / cancelled → [SAVED]
```

## Security

- PIN stored as SHA-256 hash in `FlutterSecureStorage`
- Biometric via `local_auth`
- App lock on resume when PIN/biometric enabled
- No sensitive data in SharedPreferences

## Offline-First

All reads/writes go to Hive. Architecture supports future sync:

1. Add `ExpenseRepository.sync()` with remote datasource
2. Add conflict resolution layer
3. Queue pending writes in separate Hive box

## Android Native Bridge

`MethodChannel('com.upitracker/upi')` in `MainActivity.kt`:

- Package detection for UPI apps
- Intent-based launch with fallback chooser

## Key Design Decisions

1. **Hive over Isar** — Zero code generation, instant `flutter run`
2. **User-confirmed payment status** — UPI apps don't expose callbacks
3. **Pre-payment tagging** — Core product differentiator
4. **Riverpod over Bloc** — Less boilerplate for this app size
