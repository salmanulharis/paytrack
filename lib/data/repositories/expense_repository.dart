import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_status.dart';
import '../datasources/local/hive_storage.dart';

class ExpenseRepository {
  ExpenseRepository(this._storage);

  final HiveStorage _storage;

  Future<List<Expense>> getAll() => _storage.getAllExpenses();

  Future<Expense?> getById(String id) => _storage.getExpense(id);

  Future<void> save(Expense expense, {bool incrementTags = true}) async {
    await _storage.saveExpense(expense);
    if (incrementTags) {
      await _storage.incrementTagUsage(expense.tagIds);
    }
  }

  Future<void> delete(String id) => _storage.deleteExpense(id);

  Future<void> updateStatus(String id, ExpenseStatus status) async {
    final expense = await _storage.getExpense(id);
    if (expense != null) {
      await _storage.saveExpense(expense.copyWith(status: status));
    }
  }

  Future<List<Expense>> search({
    String? query,
    List<String>? tagIds,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? paymentAppId,
    ExpenseStatus? status,
  }) async {
    var expenses = await _storage.getAllExpenses();

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      expenses = expenses.where((e) {
        return (e.merchantName?.toLowerCase().contains(q) ?? false) ||
            (e.notes?.toLowerCase().contains(q) ?? false) ||
            (e.upiId?.toLowerCase().contains(q) ?? false) ||
            e.amount.toString().contains(q);
      }).toList();
    }

    if (tagIds != null && tagIds.isNotEmpty) {
      expenses = expenses
          .where((e) => e.tagIds.any((t) => tagIds.contains(t)))
          .toList();
    }

    if (startDate != null) {
      expenses = expenses.where((e) => !e.createdAt.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      expenses = expenses.where((e) => !e.createdAt.isAfter(endDate)).toList();
    }
    if (minAmount != null) {
      expenses = expenses.where((e) => e.amount >= minAmount).toList();
    }
    if (maxAmount != null) {
      expenses = expenses.where((e) => e.amount <= maxAmount).toList();
    }
    if (paymentAppId != null) {
      expenses =
          expenses.where((e) => e.paymentAppId == paymentAppId).toList();
    }
    if (status != null) {
      expenses = expenses.where((e) => e.status == status).toList();
    }

    return expenses;
  }
}
