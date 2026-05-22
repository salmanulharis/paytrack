import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/tag_icon_helper.dart';

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

    final expenseTags = tags.where((t) => expense.tagIds.contains(t.id)).toList();
    final dateFormat = DateFormat('EEEE, d MMM yyyy · HH:mm');

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete expense?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(expensesProvider.notifier).remove(id);
                if (context.mounted) Navigator.pop(context);
              }
            },
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
          Text(dateFormat.format(expense.createdAt)),
          const SizedBox(height: 24),
          _DetailRow('Status', expense.status.label),
          if (expense.upiId != null) _DetailRow('UPI ID', expense.upiId!),
          if (expense.paymentAppName != null)
            _DetailRow('Payment app', expense.paymentAppName!),
          if (expense.paymentSource != null)
            _DetailRow('Payment source', expense.paymentSource!),
          if (expense.notes != null) _DetailRow('Notes', expense.notes!),
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
