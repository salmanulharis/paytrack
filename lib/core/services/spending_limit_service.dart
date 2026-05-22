import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_status.dart';
import '../../domain/entities/limit_status.dart';
import '../../domain/entities/user_preferences.dart';

class SpendingLimitService {
  SpendingLimitService(this._prefs);

  final SharedPreferences _prefs;

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> recordDailyExcessIfNeeded({
    required UserPreferences prefs,
    required List<Expense> expenses,
    required DateTime date,
  }) async {
    if (!prefs.compensationEnabled || !prefs.dailyLimitEnabled) return;

    final status = dailyStatus(prefs: prefs, expenses: expenses, date: date);
    if (status.excessOverLimit > 0) {
      final nextDay = date.add(const Duration(days: 1));
      await _prefs.setDouble(
        '${AppConstants.prefCompensationPrefix}${_dateKey(nextDay)}',
        status.excessOverLimit,
      );
    }
  }

  Future<void> resetCompensation() async {
    final keys = _prefs.getKeys().where(
          (k) => k.startsWith(AppConstants.prefCompensationPrefix),
        );
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  double _compensationFor(DateTime date) {
    final key = '${AppConstants.prefCompensationPrefix}${_dateKey(date)}';
    return _prefs.getDouble(key) ?? 0;
  }

  double _spentOnDate(List<Expense> expenses, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return expenses
        .where((e) =>
            e.status == ExpenseStatus.success &&
            !e.createdAt.isBefore(start) &&
            e.createdAt.isBefore(end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double _spentInMonth(List<Expense> expenses, DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 1);
    return expenses
        .where((e) =>
            e.status == ExpenseStatus.success &&
            !e.createdAt.isBefore(start) &&
            e.createdAt.isBefore(end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  LimitStatus dailyStatus({
    required UserPreferences prefs,
    required List<Expense> expenses,
    DateTime? date,
    double? pendingAmount,
  }) {
    final d = date ?? DateTime.now();
    if (!prefs.dailyLimitEnabled) {
      return const LimitStatus(
        label: 'Daily',
        spent: 0,
        effectiveLimit: 0,
        baseLimit: 0,
        percentUsed: 0,
        isExceeded: false,
        isApproaching: false,
      );
    }

    final base = prefs.dailyLimitAmount;
    final reduction =
        prefs.compensationEnabled ? _compensationFor(d) : 0.0;
    final effective = (base - reduction).clamp(0.0, double.infinity);
    final spent = _spentOnDate(expenses, d) + (pendingAmount ?? 0);
    final percent = effective > 0 ? (spent / effective).clamp(0.0, 2.0) : 0;
    final exceeded = effective > 0 && spent > effective;
    final approaching = !exceeded &&
        effective > 0 &&
        percent >= AppConstants.limitWarningThreshold;

    String? message;
    if (exceeded) {
      message =
          'Daily limit exceeded by ₹${(spent - effective).toStringAsFixed(0)}';
    } else if (approaching) {
      message =
          'You have used ${(percent * 100).toStringAsFixed(0)}% of today\'s limit';
    } else if (reduction > 0) {
      message =
          '₹${reduction.toStringAsFixed(0)} deducted from today due to yesterday\'s overspend';
    }

    return LimitStatus(
      label: 'Daily',
      spent: spent,
      effectiveLimit: effective,
      baseLimit: base,
      percentUsed: percent.toDouble(),
      isExceeded: exceeded,
      isApproaching: approaching,
      compensationReduction: reduction,
      excessOverLimit: exceeded ? spent - effective : 0,
      message: message,
    );
  }

  LimitStatus monthlyStatus({
    required UserPreferences prefs,
    required List<Expense> expenses,
    DateTime? date,
    double? pendingAmount,
  }) {
    final d = date ?? DateTime.now();
    if (!prefs.monthlyLimitEnabled) {
      return const LimitStatus(
        label: 'Monthly',
        spent: 0,
        effectiveLimit: 0,
        baseLimit: 0,
        percentUsed: 0,
        isExceeded: false,
        isApproaching: false,
      );
    }

    final base = prefs.monthlyLimitAmount;
    final spent = _spentInMonth(expenses, d) + (pendingAmount ?? 0);
    final percent = base > 0 ? (spent / base).clamp(0.0, 2.0) : 0;
    final exceeded = spent > base;
    final approaching =
        !exceeded && percent >= AppConstants.limitWarningThreshold;

    String? message;
    if (exceeded) {
      message =
          'Monthly limit exceeded by ₹${(spent - base).toStringAsFixed(0)}';
    } else if (approaching) {
      message =
          'You have used ${(percent * 100).toStringAsFixed(0)}% of this month\'s limit';
    }

    return LimitStatus(
      label: 'Monthly',
      spent: spent,
      effectiveLimit: base,
      baseLimit: base,
      percentUsed: percent.toDouble(),
      isExceeded: exceeded,
      isApproaching: approaching,
      excessOverLimit: exceeded ? spent - base : 0,
      message: message,
    );
  }
}
