import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../domain/entities/expense_status.dart';

class PaymentConfirmationSheet extends ConsumerWidget {
  const PaymentConfirmationSheet({super.key, required this.pendingId});

  final String pendingId;

  static Future<void> show(BuildContext context, String pendingId) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => PaymentConfirmationSheet(pendingId: pendingId),
    );
  }

  Future<void> _resolve(
    WidgetRef ref,
    BuildContext context,
    ExpenseStatus status,
  ) async {
    HapticFeedback.mediumImpact();
    final flow = ref.read(paymentFlowServiceProvider);
    await flow.completePayment(pendingId: pendingId, status: status);
    await ref.read(expensesProvider.notifier).load();

    if (status == ExpenseStatus.success) {
      final userPrefs = ref.read(userPreferencesProvider);
      await ref.read(spendingLimitServiceProvider).recordDailyExcessIfNeeded(
            prefs: userPrefs,
            expenses: ref.read(expensesProvider),
            date: DateTime.now(),
          );
    }

    ref.read(pendingPaymentProvider.notifier).state = null;
    if (!context.mounted) return;

    Navigator.pop(context);

    if (status == ExpenseStatus.success) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Was the payment successful?',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We cannot verify UPI payments directly. Please confirm so we can record your expense accurately.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Yes, payment succeeded',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () => _resolve(ref, context, ExpenseStatus.success),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _resolve(ref, context, ExpenseStatus.failed),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('Payment failed'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _resolve(ref, context, ExpenseStatus.cancelled),
            child: const Text('I cancelled the payment'),
          ),
        ],
      ),
    );
  }
}
