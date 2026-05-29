import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_status.dart';
import '../../domain/entities/expense_tag.dart';
import '../utils/currency_formatter.dart';
import '../utils/expense_actions.dart';
import '../theme/paytrack_theme_extension.dart';
import '../utils/tag_icon_helper.dart';

class ExpenseListTile extends ConsumerWidget {
  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.tags,
    this.onTap,
    this.onDeleted,
    this.index = 0,
    this.showActions = true,
  });

  final Expense expense;
  final List<ExpenseTag> tags;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final int index;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryTag =
        tags.where((t) => expense.tagIds.contains(t.id)).firstOrNull;
    final color =
        primaryTag != null ? Color(primaryTag.colorValue) : Colors.grey;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: showActions ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (_) async {
        await ExpenseActions.confirmDelete(context, ref, expense,
            onDeleted: onDeleted);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: showActions
              ? () => ExpenseActions.showActionsSheet(
                    context,
                    ref,
                    expense,
                    onDeleted: onDeleted,
                  )
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: PayTrackThemeExtension.of(context).cardShadows,
            ),
            child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    primaryTag != null
                        ? TagIconHelper.iconFor(primaryTag.iconName)
                        : Icons.payment_rounded,
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.merchantName ?? primaryTag?.name ?? 'Expense',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(expense, primaryTag),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
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
                if (showActions)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          ExpenseActions.navigateToEdit(context, expense.id);
                        case 'delete':
                          ExpenseActions.confirmDelete(
                            context,
                            ref,
                            expense,
                            onDeleted: onDeleted,
                          );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            'Delete',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          ),
        ),
      ),
    )
        .animate(delay: (50 * index).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }

  String _subtitle(Expense expense, ExpenseTag? tag) {
    final parts = <String>[];
    if (tag != null) parts.add(tag.name);
    if (expense.notes != null && expense.notes!.isNotEmpty) {
      parts.add(expense.notes!);
    } else if (expense.paymentAppName != null) {
      parts.add(expense.paymentAppName!);
    } else if (expense.paymentSource != null) {
      parts.add(expense.paymentSource!);
    }
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
