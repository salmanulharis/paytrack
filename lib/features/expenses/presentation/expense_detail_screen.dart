import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/expense_actions.dart';
import '../../../core/utils/tag_icon_helper.dart';
import '../../../core/widgets/gradient_button.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    final tags = ref.watch(tagsProvider);
    final expense = expenses.where((e) => e.id == id).firstOrNull;

    if (expense == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Expense not found')),
      );
    }

    final expenseTags =
        tags.where((t) => expense.tagIds.contains(t.id)).toList();
    final dateFormat = DateFormat('EEEE, d MMM yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => ExpenseActions.navigateToEdit(context, id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete',
            onPressed: () => ExpenseActions.confirmDelete(
              context,
              ref,
              expense,
              onDeleted: () {
                if (context.mounted) context.pop();
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            CurrencyFormatter.format(expense.amount, showDecimals: true),
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            expense.merchantName ?? 'Expense',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${dateFormat.format(expense.createdAt)} · ${timeFormat.format(expense.createdAt)}',
          ),
          const SizedBox(height: 24),
          _DetailRow('Status', expense.status.label),
          if (expense.upiId != null) _DetailRow('UPI ID', expense.upiId!),
          if (expense.paymentAppName != null)
            _DetailRow('Payment app', expense.paymentAppName!),
          if (expense.paymentSource != null)
            _DetailRow('Payment method', expense.paymentSource!),
          if (expense.notes != null && expense.notes!.isNotEmpty)
            _DetailRow('Notes', expense.notes!),
          const SizedBox(height: 16),
          Text('Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: expenseTags.map((tag) {
              return Chip(
                avatar: Icon(TagIconHelper.iconFor(tag.iconName), size: 18),
                label: Text(tag.name),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Edit expense',
            icon: Icons.edit_rounded,
            onPressed: () => ExpenseActions.navigateToEdit(context, id),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ExpenseActions.confirmDelete(
              context,
              ref,
              expense,
              onDeleted: () {
                if (context.mounted) context.pop();
              },
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete expense'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
              ),
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
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
