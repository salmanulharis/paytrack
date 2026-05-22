import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    final tags = ref.watch(tagsProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final breakdown = analytics.categoryBreakdown(expenses, tags, monthStart, now);
    final chartData = analytics.dailyChartData(expenses, days: 30);
    final heatmap = analytics.spendingHeatmap(expenses, now.year, now.month);
    final monthTotal = analytics.monthTotal(expenses);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly spending', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  CurrencyFormatter.format(monthTotal),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('30-day trend', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: chartData.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: (e.value['amount'] as double).clamp(0, double.infinity),
                          color: AppColors.primary,
                          width: 4,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Category breakdown', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (breakdown.isEmpty)
            const Text('No data for this month')
          else
            ...breakdown.take(6).map((cat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 28,
                      lineWidth: 6,
                      percent: (cat.percentage / 100).clamp(0.0, 1.0),
                      progressColor: Color(cat.colorValue),
                      backgroundColor: Color(cat.colorValue).withValues(alpha: 0.15),
                      center: Text(
                        '${cat.percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.tagName, style: Theme.of(context).textTheme.titleMedium),
                          Text(CurrencyFormatter.format(cat.amount)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
          Text('Spending calendar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: TableCalendar(
              firstDay: DateTime(now.year, now.month, 1),
              lastDay: DateTime(now.year, now.month + 1, 0),
              focusedDay: now,
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(formatButtonVisible: false),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) {
                  final total = heatmap[DateTime(day.year, day.month, day.day)];
                  if (total == null || total == 0) return null;
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: (total / 5000).clamp(0.15, 0.9),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 12,
                          color: total > 2000 ? Colors.white : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Budget tracking', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monthly budget goal'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (monthTotal / 50000).clamp(0.0, 1.0),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  color: monthTotal > 50000 ? AppColors.error : AppColors.success,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  '${CurrencyFormatter.format(monthTotal)} of ₹50,000',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
