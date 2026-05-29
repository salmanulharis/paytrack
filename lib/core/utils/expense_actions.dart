import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/expense.dart';
import '../providers/app_providers.dart';
import 'currency_formatter.dart';

/// Shared edit / delete flows for expense list and detail screens.
class ExpenseActions {
  ExpenseActions._();

  static void navigateToEdit(BuildContext context, String expenseId) {
    context.push('/edit-expense/$expenseId');
  }

  static Future<void> showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    Expense expense, {
    VoidCallback? onDeleted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('View details'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/expense/${expense.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit expense'),
              onTap: () {
                Navigator.pop(ctx);
                navigateToEdit(context, expense.id);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                'Delete expense',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                confirmDelete(context, ref, expense, onDeleted: onDeleted);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Future<bool> confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense, {
    VoidCallback? onDeleted,
  }) async {
    final title = expense.merchantName ?? 'this expense';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
          'Are you sure you want to delete "$title" '
          '(${CurrencyFormatter.format(expense.amount)})? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return false;

    return deleteWithUndo(context, ref, expense, onDeleted: onDeleted);
  }

  static Future<bool> deleteWithUndo(
    BuildContext context,
    WidgetRef ref,
    Expense expense, {
    VoidCallback? onDeleted,
  }) async {
    final notifier = ref.read(expensesProvider.notifier);
    await notifier.remove(expense.id);
    onDeleted?.call();

    if (!context.mounted) return true;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted ${expense.merchantName ?? 'expense'} '
          '(${CurrencyFormatter.format(expense.amount)})',
        ),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await notifier.add(expense);
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
    return true;
  }
}
