import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paytrack_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/home_primary_actions.dart';
import '../../../core/widgets/limit_progress_card.dart';
import '../../../core/widgets/main_tab_bottom_chrome.dart';
import '../../../core/widgets/quick_action_fab_host.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    final tags = ref.watch(tagsProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    final userPrefs = ref.watch(userPreferencesProvider);
    final limitService = ref.watch(spendingLimitServiceProvider);
    final dailyLimit = limitService.dailyStatus(
      prefs: userPrefs,
      expenses: expenses,
    );
    final monthlyLimit = limitService.monthlyStatus(
      prefs: userPrefs,
      expenses: expenses,
    );

    final today = analytics.todayTotal(expenses);
    final week = analytics.weekTotal(expenses);
    final month = analytics.monthTotal(expenses);
    final chartData = analytics.dailyChartData(expenses);
    final showChart = analytics.hasChartData(chartData);
    final insights = analytics.generateInsights(expenses, tags);
    final hasExpenses = analytics.hasAnySuccessExpense(expenses);

    return QuickActionFabHost(
      child: Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'PayTrack',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.push('/search'),
                          icon: const Icon(Icons.search_rounded),
                        ),
                        IconButton(
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.settings_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _HeroCard(today: today, week: week, month: month),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: HomePrimaryActions(
                  onAddExpense: () => context.push('/manual-expense'),
                  onScan: () => context.push('/scanner'),
                ),
              ),
            ),
            if (userPrefs.dailyLimitEnabled && userPrefs.limitAlertsEnabled)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LimitProgressCard(status: dailyLimit),
                ),
              ),
            if (userPrefs.monthlyLimitEnabled && userPrefs.limitAlertsEnabled)
              SliverToBoxAdapter(child: LimitProgressCard(status: monthlyLimit)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Insights', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => context.go('/analytics'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
            ),
            if (!hasExpenses)
              const SliverToBoxAdapter(
                child: EmptyState(
                  message: 'No expenses recorded yet',
                  subtitle: 'Add an expense or scan a QR to start tracking.',
                  icon: Icons.insights_outlined,
                  compact: true,
                ),
              )
            else if (insights.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  message: 'Keep tracking to unlock insights',
                  subtitle: 'Insights appear once you have more spending history.',
                  icon: Icons.lightbulb_outline_rounded,
                  compact: true,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final insight = insights[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              _insightIcon(insight.type),
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                insight.message,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: insights.length.clamp(0, 3),
                ),
              ),
            if (showChart)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '7-day spending',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
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
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: chartData.asMap().entries.map((e) {
                                    return FlSpot(
                                      e.key.toDouble(),
                                      e.value['amount'] as double,
                                    );
                                  }).toList(),
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.primary,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: PayTrackThemeExtension.of(context)
                                        .chartAreaFill,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _insightIcon(InsightType type) {
    return switch (type) {
      InsightType.increase => Icons.trending_up_rounded,
      InsightType.decrease => Icons.trending_down_rounded,
      InsightType.warning => Icons.warning_amber_rounded,
      InsightType.info => Icons.lightbulb_outline_rounded,
    };
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.today,
    required this.week,
    required this.month,
  });

  final double today;
  final double week;
  final double month;

  @override
  Widget build(BuildContext context) {
    final heroShadow = PayTrackThemeExtension.of(context).heroShadow;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: heroShadow,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's spending",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(today),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatChip(label: 'This week', value: CurrencyFormatter.compact(week)),
              const SizedBox(width: 16),
              _StatChip(label: 'This month', value: CurrencyFormatter.compact(month)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
