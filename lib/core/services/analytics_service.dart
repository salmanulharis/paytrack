import 'package:collection/collection.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_status.dart';
import '../../domain/entities/expense_tag.dart';

class SpendingInsight {
  const SpendingInsight({
    required this.message,
    required this.type,
    this.percentChange,
  });

  final String message;
  final InsightType type;
  final double? percentChange;
}

enum InsightType { increase, decrease, warning, info }

class CategorySpending {
  const CategorySpending({
    required this.tagId,
    required this.tagName,
    required this.amount,
    required this.colorValue,
    required this.percentage,
  });

  final String tagId;
  final String tagName;
  final double amount;
  final int colorValue;
  final double percentage;
}

class AnalyticsService {
  double totalForPeriod(List<Expense> expenses, DateTime start, DateTime end) {
    return expenses
        .where((e) =>
            e.status == ExpenseStatus.success &&
            !e.createdAt.isBefore(start) &&
            !e.createdAt.isAfter(end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double todayTotal(List<Expense> expenses) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    return totalForPeriod(expenses, start, end);
  }

  double weekTotal(List<Expense> expenses) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(start.year, start.month, start.day);
    return totalForPeriod(expenses, weekStart, now);
  }

  double monthTotal(List<Expense> expenses) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return totalForPeriod(expenses, start, now);
  }

  List<Map<String, dynamic>> dailyChartData(
    List<Expense> expenses, {
    int days = 7,
  }) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final total = totalForPeriod(expenses, start, end.subtract(const Duration(milliseconds: 1)));
      return {
        'day': _weekdayLabel(day.weekday),
        'date': day,
        'amount': total,
      };
    });
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }

  List<CategorySpending> categoryBreakdown(
    List<Expense> expenses,
    List<ExpenseTag> tags,
    DateTime start,
    DateTime end,
  ) {
    final filtered = expenses.where((e) =>
        e.status == ExpenseStatus.success &&
        !e.createdAt.isBefore(start) &&
        !e.createdAt.isAfter(end));

    final tagTotals = <String, double>{};
    for (final expense in filtered) {
      for (final tagId in expense.tagIds) {
        tagTotals[tagId] = (tagTotals[tagId] ?? 0) + expense.amount / expense.tagIds.length;
      }
    }

    final total = tagTotals.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return [];

    return tagTotals.entries.map((entry) {
      final tag = tags.firstWhereOrNull((t) => t.id == entry.key);
      return CategorySpending(
        tagId: entry.key,
        tagName: tag?.name ?? 'Unknown',
        amount: entry.value,
        colorValue: tag?.colorValue ?? 0xFF636E72,
        percentage: (entry.value / total) * 100,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<SpendingInsight> generateInsights(
    List<Expense> expenses,
    List<ExpenseTag> tags,
  ) {
    final insights = <SpendingInsight>[];
    final now = DateTime.now();

    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(milliseconds: 1));

    final thisWeek = totalForPeriod(
      expenses,
      DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day),
      now,
    );
    final lastWeek = totalForPeriod(expenses, lastWeekStart, lastWeekEnd);

    if (lastWeek > 0 && thisWeek > 0) {
      final change = ((thisWeek - lastWeek) / lastWeek) * 100;
      if (change.abs() >= 10) {
        insights.add(SpendingInsight(
          message: change > 0
              ? 'Spending is up ${change.toStringAsFixed(0)}% compared to last week'
              : 'You saved ${(-change).toStringAsFixed(0)}% compared to last week — great job!',
          type: change > 0 ? InsightType.warning : InsightType.decrease,
          percentChange: change,
        ));
      }
    }

    final monthStart = DateTime(now.year, now.month, 1);
    final breakdown = categoryBreakdown(expenses, tags, monthStart, now);
    if (breakdown.isNotEmpty) {
      final top = breakdown.first;
      insights.add(SpendingInsight(
        message: '${top.tagName} is your top category at ₹${top.amount.toStringAsFixed(0)} this month',
        type: InsightType.info,
      ));

      if (breakdown.length > 1) {
        final food = breakdown.firstWhereOrNull((c) => c.tagId == 'food');
        if (food != null && food.percentage > 35) {
          insights.add(SpendingInsight(
            message: 'Food spending is ${food.percentage.toStringAsFixed(0)}% of your monthly budget',
            type: InsightType.warning,
          ));
        }
      }
    }

    final pending = expenses.where((e) => e.status == ExpenseStatus.pending).length;
    if (pending > 0) {
      insights.add(SpendingInsight(
        message: 'You have $pending pending transaction${pending > 1 ? 's' : ''} to confirm',
        type: InsightType.warning,
      ));
    }

    if (insights.isEmpty) {
      insights.add(SpendingInsight(
        message: 'Track every UPI payment to unlock personalized insights',
        type: InsightType.info,
      ));
    }

    return insights;
  }

  Map<DateTime, double> spendingHeatmap(List<Expense> expenses, int year, int month) {
    final map = <DateTime, double>{};
    for (final e in expenses) {
      if (e.status != ExpenseStatus.success) continue;
      if (e.createdAt.year == year && e.createdAt.month == month) {
        final day = DateTime(year, month, e.createdAt.day);
        map[day] = (map[day] ?? 0) + e.amount;
      }
    }
    return map;
  }
}
