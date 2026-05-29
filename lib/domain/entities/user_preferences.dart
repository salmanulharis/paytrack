import 'floating_action_position.dart';
import 'note_field_mode.dart';

class UserPreferences {
  const UserPreferences({
    this.noteFieldMode = NoteFieldMode.optional,
    this.allowEditMerchantAmount = true,
    this.dailyLimitEnabled = false,
    this.dailyLimitAmount = 2000,
    this.monthlyLimitEnabled = false,
    this.monthlyLimitAmount = 50000,
    this.limitAlertsEnabled = true,
    this.compensationEnabled = false,
    this.encryptedBackup = false,
    this.showFloatingQuickActions = true,
    this.floatingActionPosition = FloatingActionPosition.bottomRight,
  });

  final NoteFieldMode noteFieldMode;
  final bool allowEditMerchantAmount;
  final bool dailyLimitEnabled;
  final double dailyLimitAmount;
  final bool monthlyLimitEnabled;
  final double monthlyLimitAmount;
  final bool limitAlertsEnabled;
  final bool compensationEnabled;
  final bool encryptedBackup;
  final bool showFloatingQuickActions;
  final FloatingActionPosition floatingActionPosition;

  UserPreferences copyWith({
    NoteFieldMode? noteFieldMode,
    bool? allowEditMerchantAmount,
    bool? dailyLimitEnabled,
    double? dailyLimitAmount,
    bool? monthlyLimitEnabled,
    double? monthlyLimitAmount,
    bool? limitAlertsEnabled,
    bool? compensationEnabled,
    bool? encryptedBackup,
    bool? showFloatingQuickActions,
    FloatingActionPosition? floatingActionPosition,
  }) {
    return UserPreferences(
      noteFieldMode: noteFieldMode ?? this.noteFieldMode,
      allowEditMerchantAmount:
          allowEditMerchantAmount ?? this.allowEditMerchantAmount,
      dailyLimitEnabled: dailyLimitEnabled ?? this.dailyLimitEnabled,
      dailyLimitAmount: dailyLimitAmount ?? this.dailyLimitAmount,
      monthlyLimitEnabled: monthlyLimitEnabled ?? this.monthlyLimitEnabled,
      monthlyLimitAmount: monthlyLimitAmount ?? this.monthlyLimitAmount,
      limitAlertsEnabled: limitAlertsEnabled ?? this.limitAlertsEnabled,
      compensationEnabled: compensationEnabled ?? this.compensationEnabled,
      encryptedBackup: encryptedBackup ?? this.encryptedBackup,
      showFloatingQuickActions:
          showFloatingQuickActions ?? this.showFloatingQuickActions,
      floatingActionPosition:
          floatingActionPosition ?? this.floatingActionPosition,
    );
  }
}
