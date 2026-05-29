class AppConstants {
  AppConstants._();

  static const String appName = 'PayTrack';
  static const String hiveBoxExpenses = 'expenses';
  static const String hiveBoxTags = 'tags';
  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxPending = 'pending_payments';
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefPinHash = 'pin_hash';
  static const String prefBiometricEnabled = 'biometric_enabled';
  static const String prefThemeMode = 'theme_mode';
  static const String prefDefaultUpiApp = 'default_upi_app';
  static const String prefAlwaysUseDefaultApp = 'always_use_default_app';
  static const String prefLastUpiApp = 'last_upi_app';
  static const String prefUpiAppUsage = 'upi_app_usage';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefDailySummary = 'daily_summary_notif';
  static const String prefWeeklyReport = 'weekly_report_notif';
  static const String prefBudgetAlerts = 'budget_alerts';
  static const int paymentConfirmationTimeoutSec = 120;

  // Payment form
  static const String prefNoteFieldMode = 'note_field_mode';
  static const String prefAllowEditMerchantAmount = 'allow_edit_merchant_amount';

  // Spending limits
  static const String prefDailyLimitEnabled = 'daily_limit_enabled';
  static const String prefDailyLimitAmount = 'daily_limit_amount';
  static const String prefMonthlyLimitEnabled = 'monthly_limit_enabled';
  static const String prefMonthlyLimitAmount = 'monthly_limit_amount';
  static const String prefLimitAlertsEnabled = 'limit_alerts_enabled';
  static const String prefCompensationEnabled = 'compensation_enabled';
  static const String prefCompensationPrefix = 'compensation_excess_';
  static const String prefEncryptedBackup = 'encrypted_backup';
  static const String prefLockGraceMinutes = 'lock_grace_minutes';
  static const String prefShowFloatingQuickActions = 'show_floating_quick_actions';
  static const String prefFloatingActionPosition = 'floating_action_position';

  static const int backupFormatVersion = 1;
  static const double limitWarningThreshold = 0.85;
}
