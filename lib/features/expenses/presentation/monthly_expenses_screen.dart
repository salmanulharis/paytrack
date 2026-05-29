import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paytrack_theme_extension.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_tag.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/expense_list_tile.dart';
import '../../../core/widgets/main_tab_bottom_chrome.dart';
import '../../../core/widgets/quick_action_fab_host.dart';
import '../../../core/widgets/month_selector_bar.dart';

class MonthlyExpensesScreen extends ConsumerStatefulWidget {
  const MonthlyExpensesScreen({super.key});

  @override
  ConsumerState<MonthlyExpensesScreen> createState() =>
      _MonthlyExpensesScreenState();
}

class _MonthlyExpensesScreenState extends ConsumerState<MonthlyExpensesScreen> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _focusedMonth.year == now.year && _focusedMonth.month == now.month;
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    if (_isCurrentMonth) return;
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final tags = ref.watch(tagsProvider);
    final analytics = ref.watch(analyticsServiceProvider);

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final monthTotal = analytics.monthTotalFor(expenses, year, month);
    final grouped = analytics.expensesGroupedByDay(expenses, year, month);
    final sortedDays = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final monthLabel = DateFormat('MMMM yyyy').format(_focusedMonth);

    return QuickActionFabHost(
      child: Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Expenses',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                child: MonthSelectorBar(
                  label: monthLabel,
                  canGoNext: !_isCurrentMonth,
                  onPrevious: _previousMonth,
                  onNext: _nextMonth,
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _MonthlyTotalCard(total: monthTotal),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
            ),
            if (sortedDays.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  message: 'No spending data available for this period',
                  subtitle: 'Expenses you record will appear here, grouped by day.',
                  icon: Icons.calendar_month_outlined,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final day = sortedDays[index];
                    final dayExpenses = grouped[day]!;
                    final dayTotal = analytics.dayTotal(expenses, day);
                    return _DaySection(
                      day: day,
                      dayTotal: dayTotal,
                      expenses: dayExpenses,
                      tags: tags,
                      sectionIndex: index,
                      onExpenseChanged: () => setState(() {}),
                    );
                  },
                  childCount: sortedDays.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
      bottomNavigationBar: const MainTabBottomChrome(),
      ),
    );
  }
}

class _MonthlyTotalCard extends StatelessWidget {
  const _MonthlyTotalCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final heroShadow = PayTrackThemeExtension.of(context).heroShadow;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: heroShadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total this month',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.dayTotal,
    required this.expenses,
    required this.tags,
    required this.sectionIndex,
    required this.onExpenseChanged,
  });

  final DateTime day;
  final double dayTotal;
  final List<Expense> expenses;
  final List<ExpenseTag> tags;
  final int sectionIndex;
  final VoidCallback onExpenseChanged;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy').format(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                CurrencyFormatter.format(dayTotal),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        ...expenses.asMap().entries.map((entry) {
          final expense = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ExpenseListTile(
              expense: expense,
              tags: tags,
              index: sectionIndex + entry.key,
              onTap: () => context.push('/expense/${expense.id}'),
              onDeleted: onExpenseChanged,
            ),
          );
        }),
      ],
    )
        .animate()
        .fadeIn(duration: 280.ms, delay: (40 * sectionIndex).ms)
        .slideX(begin: 0.02, end: 0);
  }
}
