import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/app_platform.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/upi_payment_service.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/widgets/floating_form_scaffold.dart';
import '../../../core/widgets/merchant_amount_banner.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../domain/entities/note_field_mode.dart';
import '../../../domain/entities/upi_app_info.dart';
import 'upi_app_picker_sheet.dart';

class ExpenseMetadataScreen extends ConsumerStatefulWidget {
  const ExpenseMetadataScreen({
    super.key,
    required this.upiId,
    this.merchantName,
    this.prefilledAmount,
    this.rawUpiUri,
  });

  final String upiId;
  final String? merchantName;
  final double? prefilledAmount;
  /// Original scanned QR payload — merged into payment URI for wallet compatibility.
  final String? rawUpiUri;

  @override
  ConsumerState<ExpenseMetadataScreen> createState() => _ExpenseMetadataScreenState();
}

class _ExpenseMetadataScreenState extends ConsumerState<ExpenseMetadataScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _isPaying = false;

  bool get _hasMerchantAmount =>
      widget.prefilledAmount != null && widget.prefilledAmount! > 0;

  @override
  void initState() {
    super.initState();
    if (_hasMerchantAmount) {
      final a = widget.prefilledAmount!;
      _amountController.text = a == a.roundToDouble()
          ? a.toStringAsFixed(0)
          : a.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _validateNote(NoteFieldMode mode) {
    if (mode == NoteFieldMode.disabled) return true;
    if (mode == NoteFieldMode.optional) return true;
    return _notesController.text.trim().isNotEmpty;
  }

  String _noteLabel(NoteFieldMode mode) {
    return switch (mode) {
      NoteFieldMode.mandatory => 'Reason / note *',
      NoteFieldMode.optional => 'Reason / note (optional)',
      NoteFieldMode.disabled => '',
    };
  }

  Future<bool> _checkLimits(double amount) async {
    final prefs = ref.read(userPreferencesProvider);
    if (!prefs.limitAlertsEnabled) return true;

    final expenses = ref.read(expensesProvider);
    final limitService = ref.read(spendingLimitServiceProvider);
    final daily = limitService.dailyStatus(
      prefs: prefs,
      expenses: expenses,
      pendingAmount: amount,
    );
    final monthly = limitService.monthlyStatus(
      prefs: prefs,
      expenses: expenses,
      pendingAmount: amount,
    );

    if (!daily.isExceeded && !monthly.isExceeded) return true;

    final messages = <String>[];
    if (daily.isExceeded && daily.message != null) messages.add(daily.message!);
    if (monthly.isExceeded && monthly.message != null) {
      messages.add(monthly.message!);
    }

    if (!mounted) return false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Spending limit warning'),
        content: Text(messages.join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue anyway'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  Future<void> _pay() async {
    if (!supportsUpiPayments) {
      _showSnack('UPI payments are available on Android and iOS only');
      return;
    }

    final userPrefs = ref.read(userPreferencesProvider);
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showSnack('Enter a valid amount');
      return;
    }
    if (_selectedTags.isEmpty) {
      _showSnack('Select at least one category');
      return;
    }
    if (!_validateNote(userPrefs.noteFieldMode)) {
      _showSnack('Please enter a reason or note before continuing');
      return;
    }

    if (!await _checkLimits(amount)) return;

    final sprefs = ref.read(sharedPreferencesProvider);
    final alwaysDefault =
        sprefs.getBool(AppConstants.prefAlwaysUseDefaultApp) ?? false;
    final defaultAppId = sprefs.getString(AppConstants.prefDefaultUpiApp);

    UpiAppInfo? app;

    if (alwaysDefault && defaultAppId != null) {
      final apps = await ref.read(upiPaymentServiceProvider).getInstalledUpiApps();
      app = apps.where((a) => a.id == defaultAppId).firstOrNull;
      if (app == null) {
        final known = UpiAppInfo.knownApps
            .where((a) => a.id == defaultAppId)
            .firstOrNull;
        if (known != null && known.packageName.isNotEmpty) {
          final installed = await ref
              .read(upiPaymentServiceProvider)
              .getInstalledUpiApps();
          if (installed.any((a) => a.packageName == known.packageName)) {
            app = known;
          }
        }
      }
    }

    if (!mounted) return;
    app ??= await UpiAppPickerSheet.show(context);
    if (app == null || !mounted) return;
    final selectedApp = app;

    if (widget.upiId.trim().isEmpty) {
      _showSnack('Invalid UPI ID from QR — scan again');
      return;
    }

    if (selectedApp.packageName.isEmpty && selectedApp.id != 'other') {
      final installed =
          await ref.read(upiPaymentServiceProvider).getInstalledUpiApps();
      if (!installed.any((a) => a.id == selectedApp.id)) {
        _showSnack(
          '${selectedApp.name} is not installed — pick another app or "Other UPI apps"',
        );
        return;
      }
    }

    setState(() => _isPaying = true);

    try {
      ref.read(authSessionServiceProvider).suspendLockForExternalFlow();

      final flow = ref.read(paymentFlowServiceProvider);
      final notesValue = userPrefs.noteFieldMode == NoteFieldMode.disabled
          ? null
          : _notesController.text.trim();

      if (selectedApp.id == 'other') {
        await flow.startPaymentViaChooser(
          upiId: widget.upiId,
          amount: amount,
          tagIds: _selectedTags.toList(),
          merchantName: widget.merchantName,
          notes: notesValue,
          rawQrPayload: widget.rawUpiUri,
        );
      } else {
        await flow.startPaymentFlow(
          upiId: widget.upiId,
          amount: amount,
          tagIds: _selectedTags.toList(),
          merchantName: widget.merchantName,
          notes: notesValue,
          rawQrPayload: widget.rawUpiUri,
          paymentAppId: selectedApp.id,
          paymentAppName: selectedApp.name,
          packageName: selectedApp.packageName,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete payment in your UPI app, then return to PayTrack'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on UpiLaunchException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack(
        'Could not open payment app. Try another UPI app or install a supported wallet.',
      );
      appLog('Payment launch failed', e);
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsProvider);
    final userPrefs = ref.watch(userPreferencesProvider);
    final amountLocked =
        _hasMerchantAmount && !userPrefs.allowEditMerchantAmount;

    return FloatingFormScaffold(
      title: 'Before you pay',
      actionLabel: 'Continue to payment',
      actionIcon: Icons.payment_rounded,
      isLoading: _isPaying,
      onAction: _isPaying ? null : _pay,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.merchantName != null) ...[
            Text('Merchant', style: Theme.of(context).textTheme.bodySmall),
            Text(
              widget.merchantName!,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(widget.upiId, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
          ],
          if (_hasMerchantAmount) ...[
            MerchantAmountBanner(locked: amountLocked),
            const SizedBox(height: 16),
          ],
          Text('Amount *', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            readOnly: amountLocked,
            enabled: !amountLocked,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: amountLocked
                ? null
                : [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 36,
                  color: amountLocked
                      ? Theme.of(context).disabledColor
                      : null,
                ),
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: '0',
              filled: amountLocked,
              suffixIcon: amountLocked
                  ? const Icon(Icons.lock_outline_rounded)
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          Text('Category *', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => TagChip(
                    tag: tag,
                    selected: _selectedTags.contains(tag.id),
                    onTap: () {
                      setState(() {
                        if (_selectedTags.contains(tag.id)) {
                          _selectedTags.remove(tag.id);
                        } else {
                          _selectedTags.add(tag.id);
                        }
                      });
                      HapticFeedback.selectionClick();
                    },
                  ),
                )
                .toList(),
          ),
          if (userPrefs.noteFieldMode != NoteFieldMode.disabled) ...[
            const SizedBox(height: 24),
            Text(
              _noteLabel(userPrefs.noteFieldMode),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: userPrefs.noteFieldMode == NoteFieldMode.mandatory
                    ? 'Required — e.g. Lunch with team'
                    : 'Add a note...',
              ),
            ),
          ],
        ],
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
