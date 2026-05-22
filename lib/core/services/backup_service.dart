import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../../data/datasources/local/hive_storage.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_status.dart';
import '../../domain/entities/expense_tag.dart';

class BackupExportFilters {
  const BackupExportFilters({
    this.startDate,
    this.endDate,
    this.tagIds,
    this.status,
    this.paymentAppId,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? tagIds;
  final ExpenseStatus? status;
  final String? paymentAppId;
}

enum ImportMode { merge, replace }

class BackupValidationException implements Exception {
  BackupValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BackupService {
  BackupService({
    required HiveStorage storage,
    required ExpenseRepository expenseRepo,
  })  : _storage = storage,
        _expenseRepo = expenseRepo;

  final HiveStorage _storage;
  final ExpenseRepository _expenseRepo;

  Future<String> exportBackup({
    BackupExportFilters? filters,
    bool encrypt = false,
    String? encryptionKey,
  }) async {
    var expenses = await _storage.getAllExpenses();
    if (filters != null) {
      expenses = await _expenseRepo.search(
        startDate: filters.startDate,
        endDate: filters.endDate,
        tagIds: filters.tagIds,
        status: filters.status,
        paymentAppId: filters.paymentAppId,
      );
    }
    final tags = await _storage.getAllTags();

    final payload = {
      'version': AppConstants.backupFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': AppConstants.appName,
      'expenseCount': expenses.length,
      'tagCount': tags.length,
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
      if (filters != null)
        'filters': {
          'startDate': filters.startDate?.toIso8601String(),
          'endDate': filters.endDate?.toIso8601String(),
          'tagIds': filters.tagIds,
          'status': filters.status?.name,
          'paymentAppId': filters.paymentAppId,
        },
    };

    final json = jsonEncode(payload);
    if (!encrypt) return json;

    final key = encryptionKey ?? 'paytrack_default_backup_key';
    final keyBytes = enc.Key.fromUtf8(key.padRight(32).substring(0, 32));
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(keyBytes));
    final encrypted = encrypter.encrypt(json, iv: iv);
    return jsonEncode({
      'encrypted': true,
      'iv': iv.base64,
      'data': encrypted.base64,
    });
  }

  Map<String, dynamic> _parsePayload(String raw, {String? decryptionKey}) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw BackupValidationException('Invalid backup: root must be an object');
    }

    if (decoded['encrypted'] == true) {
      final key = decryptionKey ?? 'paytrack_default_backup_key';
      final keyBytes = enc.Key.fromUtf8(key.padRight(32).substring(0, 32));
      final iv = enc.IV.fromBase64(decoded['iv'] as String);
      final encrypter = enc.Encrypter(enc.AES(keyBytes));
      final decrypted = encrypter.decrypt64(decoded['data'] as String, iv: iv);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    }

    return decoded;
  }

  void validateStructure(Map<String, dynamic> data) {
    final version = data['version'];
    if (version == null) {
      throw BackupValidationException('Missing backup version');
    }
    if (version is! int || version > AppConstants.backupFormatVersion) {
      throw BackupValidationException('Unsupported backup version: $version');
    }
    if (data['expenses'] != null && data['expenses'] is! List) {
      throw BackupValidationException('Invalid expenses array');
    }
    if (data['tags'] != null && data['tags'] is! List) {
      throw BackupValidationException('Invalid tags array');
    }

    if (data['expenses'] != null) {
      for (final item in data['expenses'] as List) {
        if (item is! Map<String, dynamic>) {
          throw BackupValidationException('Malformed expense entry');
        }
        Expense.fromJson(item);
      }
    }
    if (data['tags'] != null) {
      for (final item in data['tags'] as List) {
        if (item is! Map<String, dynamic>) {
          throw BackupValidationException('Malformed tag entry');
        }
        ExpenseTag.fromJson(item);
      }
    }
  }

  Future<ImportResult> importBackup(
    String raw, {
    required ImportMode mode,
    String? decryptionKey,
  }) async {
    try {
      final data = _parsePayload(raw, decryptionKey: decryptionKey);
      validateStructure(data);

      if (mode == ImportMode.replace) {
        await _storage.clearAllData();
      }

      var expenseCount = 0;
      var tagCount = 0;

      if (data['tags'] != null) {
        for (final t in data['tags'] as List) {
          final tag = ExpenseTag.fromJson(t as Map<String, dynamic>);
          await _storage.saveTag(tag);
          tagCount++;
        }
      }

      if (data['expenses'] != null) {
        for (final e in data['expenses'] as List) {
          final expense = Expense.fromJson(e as Map<String, dynamic>);
          await _storage.saveExpense(expense);
          expenseCount++;
        }
      }

      return ImportResult(
        expensesImported: expenseCount,
        tagsImported: tagCount,
        mode: mode,
      );
    } catch (e) {
      debugPrint('Import failed: $e');
      if (e is BackupValidationException) rethrow;
      throw BackupValidationException('Could not parse backup: $e');
    }
  }
}

class ImportResult {
  const ImportResult({
    required this.expensesImported,
    required this.tagsImported,
    required this.mode,
  });

  final int expensesImported;
  final int tagsImported;
  final ImportMode mode;
}
