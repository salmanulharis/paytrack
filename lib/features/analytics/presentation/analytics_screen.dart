import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:collection/collection.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/paytrack_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/limit_progress_card.dart';
import '../../../core/widgets/main_tab_bottom_chrome.dart';
import '../../../core/widgets/quick_action_fab_host.dart';
import '../../../core/widgets/month_selector_bar.dart';
import 'category_expenses_sheet.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final tags = ref.watch(tagsProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    final userPrefs = ref.watch(userPreferencesProvider);
    final limitService = ref.watch(spendingLimitServiceProvider);

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final bounds = analytics.monthPeriodBounds(year, month);
    final breakdown = analytics.categoryBreakdown(
      expenses,
      tags,
      bounds.start,
      bounds.end,
    );
    final chartData = analytics.dailyChartData(expenses, days: 30);
    final showTrendChart = analytics.hasChartData(chartData);
    final heatmap = analytics.spendingHeatmap(expenses, year, month);
    final monthTotal = analytics.monthTotalFor(expenses, year, month);
    final hasExpenses = analytics.hasAnySuccessExpense(expenses);
    final monthlyLimit = limitService.monthlyStatus(
      prefs: userPrefs,
      expenses: expenses,
    );
    final heatmapMax = heatmap.values.fold<double>(
      0,
      (max, v) => v > max ? v : max,
    );
    final monthLabel = DateFormat('MMMM yyyy').format(_focusedMonth);

    return QuickActionFabHost(
      child: Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          MonthSelectorBar(
            label: monthLabel,
            canGoNext: !_isCurrentMonth,
            onPrevious: () {
              setState(() {
                _focusedMonth = DateTime(year, month - 1);
              });
            },
            onNext: () {
              if (_isCurrentMonth) return;
              setState(() {
                _focusedMonth = DateTime(year, month + 1);
              });
            },
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly spending',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  CurrencyFormatter.format(monthTotal),
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(fontSize: 32),
                ),
              ],
            ),
          ),
          if (!hasExpenses) ...[
            const SizedBox(height: 32),
            const EmptyState(
              message: 'No spending data available for this period',
              subtitle:
                  'Record expenses to see trends, categories, and your spending calendar.',
              icon: Icons.bar_chart_rounded,
            ),
          ] else ...[
            const SizedBox(height: 20),
            Text('30-day trend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (!showTrendChart)
              const GlassCard(
                child: EmptyState(
                  message: 'No spending in the last 30 days',
                  icon: Icons.show_chart_rounded,
                  compact: true,
                ),
              )
            else
              SizedBox(
                height: 200,
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      barGroups: chartData.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: (e.value['amount'] as double)
                                  .clamp(0, double.infinity),
                              color: Theme.of(context).colorScheme.primary,
                              width: 5,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Category breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a category to view transactions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: 12),
            if (breakdown.isEmpty)
              const GlassCard(
                child: EmptyState(
                  message: 'No category data for this month',
                  subtitle: 'Tagged expenses will appear here.',
                  icon: Icons.pie_chart_outline_rounded,
                  compact: true,
                ),
              )
            else
              ...breakdown.take(6).map((cat) {
                final tag = tags.where((t) => t.id == cat.tagId).firstOrNull;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CategoryBreakdownTile(
                    category: cat,
                    onTap: () => CategoryExpensesSheet.show(
                      context,
                      tagId: cat.tagId,
                      tagName: cat.tagName,
                      iconName: tag?.iconName ?? 'receipt_long',
                      colorValue: cat.colorValue,
                      initialMonth: _focusedMonth,
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            Text(
              'Spending calendar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime(year, month, 1),
                lastDay: DateTime(year, month + 1, 0),
                focusedDay: _isCurrentMonth
                    ? DateTime.now()
                    : DateTime(year, month, 15),
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(formatButtonVisible: false),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) {
                    final total =
                        heatmap[DateTime(day.year, day.month, day.day)];
                    if (total == null || total == 0) return null;
                    final intensity = heatmapMax > 0
                        ? (total / heatmapMax).clamp(0.15, 1.0)
                        : 0.15;
                    final primary = Theme.of(context).colorScheme.primary;
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: intensity * 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: intensity > 0.55
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (userPrefs.monthlyLimitEnabled && _isCurrentMonth) ...[
              const SizedBox(height: 24),
              Text(
                'Budget tracking',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              LimitProgressCard(status: monthlyLimit),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: const MainTabBottomChrome(),
      ),
    );
  }
}

class _CategoryBreakdownTile extends StatelessWidget {
  const _CategoryBreakdownTile({
    required this.category,
    required this.onTap,
  });

  final CategorySpending category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cat = category;
    final color = Color(cat.colorValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                CircularPercentIndicator(
                  radius: 28,
                  lineWidth: 6,
                  percent: (cat.percentage / 100).clamp(0.0, 1.0),
                  progressColor: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                  center: Text(
                    '${cat.percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.tagName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        CurrencyFormatter.format(cat.amount),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideX(begin: 0.02, end: 0);
  }
}
