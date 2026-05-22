import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/note_field_mode.dart';
import '../../../domain/entities/upi_app_info.dart';
import '../../payment/presentation/upi_app_picker_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final userPrefs = ref.watch(userPreferencesProvider);
    final notifier = ref.read(userPreferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(themeMode.name),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: ThemeMode.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (m) {
                if (m != null) ref.read(themeModeProvider.notifier).setTheme(m);
              },
            ),
          ),
          const _SectionHeader('Payment form'),
          ListTile(
            title: const Text('Reason / note field'),
            subtitle: Text(userPrefs.noteFieldMode.label),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<NoteFieldMode>(
              segments: NoteFieldMode.values
                  .map((m) => ButtonSegment(value: m, label: Text(m.label)))
                  .toList(),
              selected: {userPrefs.noteFieldMode},
              onSelectionChanged: (s) {
                HapticFeedback.selectionClick();
                notifier.setNoteFieldMode(s.first);
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Allow editing merchant amount'),
            subtitle: const Text(
              'When QR includes amount, let user change it. Turn off to lock the field.',
            ),
            value: userPrefs.allowEditMerchantAmount,
            onChanged: (v) => notifier.update(
              userPrefs.copyWith(allowEditMerchantAmount: v),
            ),
          ),
          const _SectionHeader('Payments'),
          SwitchListTile(
            title: const Text('Always use default UPI app'),
            value: prefs.getBool(AppConstants.prefAlwaysUseDefaultApp) ?? false,
            onChanged: (v) async {
              await prefs.setBool(AppConstants.prefAlwaysUseDefaultApp, v);
              setState(() {});
            },
          ),
          ListTile(
            title: const Text('Default UPI app'),
            subtitle: Text(_appName(prefs.getString(AppConstants.prefDefaultUpiApp))),
            onTap: () async {
              final app = await UpiAppPickerSheet.show(context);
              if (app != null) {
                await prefs.setString(AppConstants.prefDefaultUpiApp, app.id);
                setState(() {});
              }
            },
          ),
          const _SectionHeader('Spending limits'),
          SwitchListTile(
            title: const Text('Daily spending limit'),
            value: userPrefs.dailyLimitEnabled,
            onChanged: (v) => notifier.setDailyLimit(
              userPrefs.dailyLimitAmount,
              enabled: v,
            ),
          ),
          if (userPrefs.dailyLimitEnabled)
            ListTile(
              title: Text('Daily limit: ${CurrencyFormatter.format(userPrefs.dailyLimitAmount)}'),
              trailing: const Icon(Icons.edit_rounded),
              onTap: () => _editLimit(
                context,
                title: 'Daily limit',
                current: userPrefs.dailyLimitAmount,
                onSave: (v) => notifier.setDailyLimit(v, enabled: true),
              ),
            ),
          SwitchListTile(
            title: const Text('Monthly spending limit'),
            value: userPrefs.monthlyLimitEnabled,
            onChanged: (v) => notifier.setMonthlyLimit(
              userPrefs.monthlyLimitAmount,
              enabled: v,
            ),
          ),
          if (userPrefs.monthlyLimitEnabled)
            ListTile(
              title: Text(
                'Monthly limit: ${CurrencyFormatter.format(userPrefs.monthlyLimitAmount)}',
              ),
              trailing: const Icon(Icons.edit_rounded),
              onTap: () => _editLimit(
                context,
                title: 'Monthly limit',
                current: userPrefs.monthlyLimitAmount,
                onSave: (v) => notifier.setMonthlyLimit(v, enabled: true),
              ),
            ),
          SwitchListTile(
            title: const Text('Limit alerts'),
            subtitle: const Text('Warn when approaching or exceeding limits'),
            value: userPrefs.limitAlertsEnabled,
            onChanged: (v) =>
                notifier.update(userPrefs.copyWith(limitAlertsEnabled: v)),
          ),
          SwitchListTile(
            title: const Text('Compensating limit'),
            subtitle: const Text(
              'If you overspend today, tomorrow\'s limit is reduced by the excess amount',
            ),
            value: userPrefs.compensationEnabled,
            onChanged: (v) =>
                notifier.update(userPrefs.copyWith(compensationEnabled: v)),
          ),
          if (userPrefs.compensationEnabled)
            ListTile(
              title: const Text('Reset compensated limits'),
              subtitle: const Text('Clear all rollover adjustments'),
              leading: const Icon(Icons.refresh_rounded),
              onTap: () async {
                await ref.read(spendingLimitServiceProvider).resetCompensation();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compensation data reset')),
                  );
                }
              },
            ),
          const _SectionHeader('Security'),
          SwitchListTile(
            title: const Text('Biometric unlock'),
            value: ref.watch(authServiceProvider).isBiometricEnabled,
            onChanged: (v) async {
              await ref.read(authServiceProvider).setBiometricEnabled(v);
            },
          ),
          ListTile(
            title: const Text('Change PIN'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/pin-setup'),
          ),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Enable notifications'),
            value: prefs.getBool(AppConstants.prefNotificationsEnabled) ?? true,
            onChanged: (v) async {
              await prefs.setBool(AppConstants.prefNotificationsEnabled, v);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Daily summary'),
            value: prefs.getBool(AppConstants.prefDailySummary) ?? true,
            onChanged: (v) async {
              await prefs.setBool(AppConstants.prefDailySummary, v);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Weekly report'),
            value: prefs.getBool(AppConstants.prefWeeklyReport) ?? true,
            onChanged: (v) async {
              await prefs.setBool(AppConstants.prefWeeklyReport, v);
              setState(() {});
            },
          ),
          const _SectionHeader('Categories'),
          ListTile(
            title: const Text('Manage categories'),
            leading: const Icon(Icons.label_rounded),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/manage-tags'),
          ),
          const _SectionHeader('Data'),
          SwitchListTile(
            title: const Text('Encrypted backup'),
            subtitle: const Text('AES encrypt JSON exports'),
            value: userPrefs.encryptedBackup,
            onChanged: (v) =>
                notifier.update(userPrefs.copyWith(encryptedBackup: v)),
          ),
          ListTile(
            title: const Text('Backup & restore'),
            subtitle: const Text('Export, filter, import JSON'),
            leading: const Icon(Icons.backup_rounded),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/backup'),
          ),
          ListTile(
            title: const Text('Clear all expenses'),
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear all data?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(hiveStorageProvider).clearAllData();
                await ref.read(expensesProvider.notifier).load();
              }
            },
          ),
          const _SectionHeader('About'),
          const ListTile(
            title: Text('PayTrack'),
            subtitle: Text('Version 1.0.0 · UPI Expense Tracker'),
          ),
        ],
      ),
    );
  }

  static Future<void> _editLimit(
    BuildContext context, {
    required String title,
    required double current,
    required ValueChanged<double> onSave,
  }) async {
    final controller = TextEditingController(text: current.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) onSave(result);
  }

  String _appName(String? id) {
    if (id == null) return 'Not set';
    return UpiAppInfo.knownApps.where((a) => a.id == id).firstOrNull?.name ?? id;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
