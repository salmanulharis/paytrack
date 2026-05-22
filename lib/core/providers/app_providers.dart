import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local/hive_storage.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../constants/app_constants.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/payment_flow_service.dart';
import '../services/spending_limit_service.dart';
import '../services/upi_parser_service.dart';
import '../services/upi_payment_service.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_tag.dart';
import '../../domain/entities/note_field_mode.dart';
import '../../domain/entities/pending_payment.dart';
import '../../domain/entities/user_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final hiveStorageProvider = Provider<HiveStorage>((ref) {
  return HiveStorage.instance;
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(hiveStorageProvider));
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository(ref.watch(hiveStorageProvider));
});

final upiParserProvider = Provider<UpiParserService>((ref) {
  return UpiParserService();
});

final upiPaymentServiceProvider = Provider<UpiPaymentService>((ref) {
  return UpiPaymentService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(secureStorageProvider),
  );
});

final paymentFlowServiceProvider = Provider<PaymentFlowService>((ref) {
  return PaymentFlowService(
    storage: ref.watch(hiveStorageProvider),
    expenseRepo: ref.watch(expenseRepositoryProvider),
    upiService: ref.watch(upiPaymentServiceProvider),
    parserService: ref.watch(upiParserProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    expenseRepository: ref.watch(expenseRepositoryProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final spendingLimitServiceProvider = Provider<SpendingLimitService>((ref) {
  return SpendingLimitService(ref.watch(sharedPreferencesProvider));
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    storage: ref.watch(hiveStorageProvider),
    expenseRepo: ref.watch(expenseRepositoryProvider),
  );
});

final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  return UserPreferencesNotifier(ref.watch(sharedPreferencesProvider));
});

// State providers
final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  return ExpensesNotifier(ref.watch(expenseRepositoryProvider));
});

final tagsProvider = StateNotifierProvider<TagsNotifier, List<ExpenseTag>>((ref) {
  return TagsNotifier(ref.watch(tagRepositoryProvider));
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});

final pendingPaymentProvider = StateProvider<PendingPayment?>((ref) => null);

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  ExpensesNotifier(this._repo) : super([]) {
    load();
  }

  final ExpenseRepository _repo;

  Future<void> load() async {
    state = await _repo.getAll();
  }

  Future<void> add(Expense expense) async {
    await _repo.save(expense);
    await load();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    await load();
  }

  Future<void> update(Expense expense) async {
    await _repo.save(expense);
    await load();
  }
}

class TagsNotifier extends StateNotifier<List<ExpenseTag>> {
  TagsNotifier(this._repo) : super([]) {
    load();
  }

  final TagRepository _repo;

  Future<void> load() async {
    state = await _repo.getAll();
  }

  Future<ExpenseTag> create({
    required String name,
    required String iconName,
    required int colorValue,
  }) async {
    final tag = await _repo.create(
      name: name,
      iconName: iconName,
      colorValue: colorValue,
    );
    await load();
    return tag;
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    final mode = _prefs.getString('theme_mode') ?? 'system';
    state = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString('theme_mode', value);
  }
}

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier(this._prefs) : super(const UserPreferences()) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    state = UserPreferences(
      noteFieldMode: NoteFieldMode.fromString(
        _prefs.getString(AppConstants.prefNoteFieldMode),
      ),
      allowEditMerchantAmount:
          _prefs.getBool(AppConstants.prefAllowEditMerchantAmount) ?? true,
      dailyLimitEnabled:
          _prefs.getBool(AppConstants.prefDailyLimitEnabled) ?? false,
      dailyLimitAmount:
          _prefs.getDouble(AppConstants.prefDailyLimitAmount) ?? 2000,
      monthlyLimitEnabled:
          _prefs.getBool(AppConstants.prefMonthlyLimitEnabled) ?? false,
      monthlyLimitAmount:
          _prefs.getDouble(AppConstants.prefMonthlyLimitAmount) ?? 50000,
      limitAlertsEnabled:
          _prefs.getBool(AppConstants.prefLimitAlertsEnabled) ?? true,
      compensationEnabled:
          _prefs.getBool(AppConstants.prefCompensationEnabled) ?? false,
      encryptedBackup:
          _prefs.getBool(AppConstants.prefEncryptedBackup) ?? false,
    );
  }

  Future<void> update(UserPreferences prefs) async {
    state = prefs;
    await _prefs.setString(
      AppConstants.prefNoteFieldMode,
      prefs.noteFieldMode.name,
    );
    await _prefs.setBool(
      AppConstants.prefAllowEditMerchantAmount,
      prefs.allowEditMerchantAmount,
    );
    await _prefs.setBool(
      AppConstants.prefDailyLimitEnabled,
      prefs.dailyLimitEnabled,
    );
    await _prefs.setDouble(
      AppConstants.prefDailyLimitAmount,
      prefs.dailyLimitAmount,
    );
    await _prefs.setBool(
      AppConstants.prefMonthlyLimitEnabled,
      prefs.monthlyLimitEnabled,
    );
    await _prefs.setDouble(
      AppConstants.prefMonthlyLimitAmount,
      prefs.monthlyLimitAmount,
    );
    await _prefs.setBool(
      AppConstants.prefLimitAlertsEnabled,
      prefs.limitAlertsEnabled,
    );
    await _prefs.setBool(
      AppConstants.prefCompensationEnabled,
      prefs.compensationEnabled,
    );
    await _prefs.setBool(
      AppConstants.prefEncryptedBackup,
      prefs.encryptedBackup,
    );
  }

  Future<void> setNoteFieldMode(NoteFieldMode mode) async {
    await update(state.copyWith(noteFieldMode: mode));
  }

  Future<void> setDailyLimit(double amount, {required bool enabled}) async {
    await update(state.copyWith(
      dailyLimitEnabled: enabled,
      dailyLimitAmount: amount,
    ));
  }

  Future<void> setMonthlyLimit(double amount, {required bool enabled}) async {
    await update(state.copyWith(
      monthlyLimitEnabled: enabled,
      monthlyLimitAmount: amount,
    ));
  }
}
