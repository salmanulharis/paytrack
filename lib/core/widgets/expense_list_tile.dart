import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_status.dart';
import '../../domain/entities/expense_tag.dart';
import '../utils/currency_formatter.dart';
import '../utils/tag_icon_helper.dart';

class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.tags,
    this.onTap,
    this.index = 0,
  });

  final Expense expense;
  final List<ExpenseTag> tags;
  final VoidCallback? onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final primaryTag = tags.where((t) => expense.tagIds.contains(t.id)).firstOrNull;
    final color = primaryTag != null ? Color(primaryTag.colorValue) : Colors.grey;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          primaryTag != null
              ? TagIconHelper.iconFor(primaryTag.iconName)
              : Icons.payment_rounded,
          color: color,
        ),
      ),
      title: Text(
        expense.merchantName ?? primaryTag?.name ?? 'Expense',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _subtitle(expense, primaryTag),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.format(expense.amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (expense.status != ExpenseStatus.success)
            Text(
              expense.status.label,
              style: TextStyle(
                fontSize: 11,
                color: _statusColor(expense.status),
              ),
            ),
        ],
      ),
    )
        .animate(delay: (50 * index).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }

  String _subtitle(Expense expense, ExpenseTag? tag) {
    final parts = <String>[];
    if (tag != null) parts.add(tag.name);
    if (expense.paymentAppName != null) parts.add(expense.paymentAppName!);
    return parts.join(' · ');
  }

  Color _statusColor(ExpenseStatus status) {
    return switch (status) {
      ExpenseStatus.success => Colors.green,
      ExpenseStatus.pending => Colors.orange,
      ExpenseStatus.failed => Colors.red,
      ExpenseStatus.cancelled => Colors.grey,
    };
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
