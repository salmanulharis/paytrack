import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/expense_actions.dart';
import '../../../core/utils/tag_icon_helper.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/month_selector_bar.dart';
import '../../../domain/entities/expense.dart';

class CategoryExpensesSheet extends ConsumerStatefulWidget {
  const CategoryExpensesSheet({
    super.key,
    required this.tagId,
    required this.tagName,
    required this.iconName,
    required this.colorValue,
    required this.initialMonth,
  });

  final String tagId;
  final String tagName;
  final String iconName;
  final int colorValue;
  final DateTime initialMonth;

  static Future<void> show(
    BuildContext context, {
    required String tagId,
    required String tagName,
    required String iconName,
    required int colorValue,
    required DateTime initialMonth,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryExpensesSheet(
        tagId: tagId,
        tagName: tagName,
        iconName: iconName,
        colorValue: colorValue,
        initialMonth: initialMonth,
      ),
    );
  }

  @override
  ConsumerState<CategoryExpensesSheet> createState() =>
      _CategoryExpensesSheetState();
}

class _CategoryExpensesSheetState extends ConsumerState<CategoryExpensesSheet> {
  late DateTime _focusedMonth;
  CategoryExpenseSort _sort = CategoryExpenseSort.newest;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.initialMonth.year, widget.initialMonth.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _focusedMonth.year == now.year && _focusedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    final color = Color(widget.colorValue);
    final bounds = analytics.monthPeriodBounds(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final categoryExpenses = analytics.sortCategoryExpenses(
      analytics.expensesForCategory(
        expenses,
        widget.tagId,
        bounds.start,
        bounds.end,
      ),
      _sort,
    );
    final total = analytics.categoryTotal(categoryExpenses);
    final monthLabel = DateFormat('MMMM yyyy').format(_focusedMonth);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        TagIconHelper.iconFor(widget.iconName),
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tagName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            CurrencyFormatter.format(total),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MonthSelectorBar(
                  label: monthLabel,
                  canGoNext: !_isCurrentMonth,
                  onPrevious: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                      );
                    });
                  },
                  onNext: () {
                    if (_isCurrentMonth) return;
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                      );
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                child: Row(
                  children: [
                    Text(
                      '${categoryExpenses.length} transaction${categoryExpenses.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    PopupMenuButton<CategoryExpenseSort>(
                      initialValue: _sort,
                      tooltip: 'Sort',
                      onSelected: (value) => setState(() => _sort = value),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: CategoryExpenseSort.newest,
                          child: Text('Newest first'),
                        ),
                        PopupMenuItem(
                          value: CategoryExpenseSort.oldest,
                          child: Text('Oldest first'),
                        ),
                        PopupMenuItem(
                          value: CategoryExpenseSort.highestAmount,
                          child: Text('Highest amount'),
                        ),
                        PopupMenuItem(
                          value: CategoryExpenseSort.lowestAmount,
                          child: Text('Lowest amount'),
                        ),
                      ],
                      child: Row(
                        children: [
                          const Icon(Icons.sort_rounded, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            _sortLabel(_sort),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: categoryExpenses.isEmpty
                    ? const EmptyState(
                        message: 'No expenses in this category',
                        subtitle: 'Try another month or add new expenses.',
                        icon: Icons.receipt_long_outlined,
                        compact: true,
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                        itemCount: categoryExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = categoryExpenses[index];
                          return _CategoryExpenseRow(
                            expense: expense,
                            index: index,
                            onChanged: () => setState(() {}),
                            onTap: () {
                              Navigator.of(context).pop();
                              context.push('/expense/${expense.id}');
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _sortLabel(CategoryExpenseSort sort) {
    return switch (sort) {
      CategoryExpenseSort.newest => 'Newest',
      CategoryExpenseSort.oldest => 'Oldest',
      CategoryExpenseSort.highestAmount => 'Highest',
      CategoryExpenseSort.lowestAmount => 'Lowest',
    };
  }
}

class _CategoryExpenseRow extends ConsumerWidget {
  const _CategoryExpenseRow({
    required this.expense,
    required this.index,
    required this.onTap,
    required this.onChanged,
  });

  final Expense expense;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = _expenseTitle(expense);
    final date = DateFormat('d MMM').format(expense.createdAt);
    final time = DateFormat('h:mm a').format(expense.createdAt);
    final payment = expense.paymentAppName ??
        expense.paymentSource ??
        (expense.isManual ? 'Manual' : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => ExpenseActions.showActionsSheet(
          context,
          ref,
          expense,
          onDeleted: onChanged,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        expense.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.65),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$date · $time',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (payment != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            payment,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.format(expense.amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
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
                        onDeleted: onChanged,
                      );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 260.ms, delay: (30 * index).ms)
        .slideX(begin: 0.03, end: 0);
  }

  String _expenseTitle(Expense expense) {
    if (expense.merchantName != null && expense.merchantName!.isNotEmpty) {
      return expense.merchantName!;
    }
    if (expense.notes != null && expense.notes!.isNotEmpty) {
      return expense.notes!;
    }
    return 'Expense';
  }
}
