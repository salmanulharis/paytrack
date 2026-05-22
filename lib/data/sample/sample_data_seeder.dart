import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_status.dart';
import '../datasources/local/hive_storage.dart';

class SampleDataSeeder {
  SampleDataSeeder._();

  static const _seededKey = 'sample_data_seeded';

  static Future<void> seedIfEmpty(
    HiveStorage storage,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool(_seededKey) == true) return;

    final existing = await storage.getAllExpenses();
    if (existing.isNotEmpty) {
      await prefs.setBool(_seededKey, true);
      return;
    }

    final uuid = const Uuid();
    final now = DateTime.now();

    final samples = [
      Expense(
        id: uuid.v4(),
        amount: 450,
        tagIds: ['food'],
        createdAt: now.subtract(const Duration(hours: 2)),
        merchantName: 'Swiggy',
        upiId: 'swiggy@ybl',
        paymentAppName: 'Google Pay',
        paymentAppId: 'gpay',
        status: ExpenseStatus.success,
      ),
      Expense(
        id: uuid.v4(),
        amount: 1200,
        tagIds: ['fuel'],
        createdAt: now.subtract(const Duration(days: 1)),
        merchantName: 'Indian Oil',
        status: ExpenseStatus.success,
        isManual: true,
        paymentSource: 'UPI',
      ),
      Expense(
        id: uuid.v4(),
        amount: 299,
        tagIds: ['subscriptions'],
        createdAt: now.subtract(const Duration(days: 2)),
        merchantName: 'Netflix',
        status: ExpenseStatus.success,
      ),
      Expense(
        id: uuid.v4(),
        amount: 3500,
        tagIds: ['groceries'],
        createdAt: now.subtract(const Duration(days: 3)),
        merchantName: 'BigBasket',
        paymentAppName: 'PhonePe',
        paymentAppId: 'phonepe',
        status: ExpenseStatus.success,
      ),
      Expense(
        id: uuid.v4(),
        amount: 850,
        tagIds: ['travel'],
        createdAt: now.subtract(const Duration(days: 5)),
        merchantName: 'Uber',
        status: ExpenseStatus.success,
      ),
    ];

    for (final expense in samples) {
      await storage.saveExpense(expense);
      await storage.incrementTagUsage(expense.tagIds);
    }

    await prefs.setBool(_seededKey, true);
  }
}
