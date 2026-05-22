import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/default_tags.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_tag.dart';
import '../../../domain/entities/pending_payment.dart';

class HiveStorage {
  HiveStorage._();
  static HiveStorage? _instance;
  static HiveStorage get instance => _instance ??= HiveStorage._();

  Box<String>? _expensesBox;
  Box<String>? _tagsBox;
  Box<String>? _pendingBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _expensesBox = await Hive.openBox<String>(AppConstants.hiveBoxExpenses);
    _tagsBox = await Hive.openBox<String>(AppConstants.hiveBoxTags);
    _pendingBox = await Hive.openBox<String>(AppConstants.hiveBoxPending);
    await _seedDefaultTagsIfNeeded();
  }

  Future<void> _seedDefaultTagsIfNeeded() async {
    if (_tagsBox!.isEmpty) {
      for (final tag in DefaultTags.all) {
        await _tagsBox!.put(tag.id, jsonEncode(tag.toJson()));
      }
    }
  }

  // Expenses
  Future<List<Expense>> getAllExpenses() async {
    return _expensesBox!.values
        .map((e) => Expense.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveExpense(Expense expense) async {
    await _expensesBox!.put(expense.id, jsonEncode(expense.toJson()));
  }

  Future<void> deleteExpense(String id) async {
    await _expensesBox!.delete(id);
  }

  Future<Expense?> getExpense(String id) async {
    final raw = _expensesBox!.get(id);
    if (raw == null) return null;
    return Expense.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // Tags
  Future<List<ExpenseTag>> getAllTags() async {
    return _tagsBox!.values
        .map((e) => ExpenseTag.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }

  Future<void> saveTag(ExpenseTag tag) async {
    await _tagsBox!.put(tag.id, jsonEncode(tag.toJson()));
  }

  Future<void> deleteTag(String id) async {
    await _tagsBox!.delete(id);
  }

  Future<void> incrementTagUsage(List<String> tagIds) async {
    for (final tagId in tagIds) {
      final raw = _tagsBox!.get(tagId);
      if (raw != null) {
        final tag = ExpenseTag.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        await saveTag(tag.copyWith(usageCount: tag.usageCount + 1));
      }
    }
  }

  // Pending payments
  Future<void> savePending(PendingPayment payment) async {
    await _pendingBox!.put(payment.id, jsonEncode(payment.toJson()));
  }

  Future<PendingPayment?> getPending(String id) async {
    final raw = _pendingBox!.get(id);
    if (raw == null) return null;
    return PendingPayment.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<PendingPayment?> getLatestPending() async {
    if (_pendingBox!.isEmpty) return null;
    final all = _pendingBox!.values
        .map((e) => PendingPayment.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return all.first;
  }

  Future<void> clearPending(String id) async {
    await _pendingBox!.delete(id);
  }

  Future<void> clearAllPending() async {
    await _pendingBox!.clear();
  }

  Future<void> clearAllData() async {
    await _expensesBox!.clear();
    await _pendingBox!.clear();
    await _tagsBox!.clear();
    await _seedDefaultTagsIfNeeded();
  }

  Future<String> exportJson() async {
    final expenses = await getAllExpenses();
    final tags = await getAllTags();
    return jsonEncode({
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> importJson(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    if (data['expenses'] != null) {
      for (final e in data['expenses'] as List) {
        final expense = Expense.fromJson(e as Map<String, dynamic>);
        await saveExpense(expense);
      }
    }
    if (data['tags'] != null) {
      for (final t in data['tags'] as List) {
        final tag = ExpenseTag.fromJson(t as Map<String, dynamic>);
        await saveTag(tag);
      }
    }
  }
}
