import 'package:equatable/equatable.dart';

import 'expense_status.dart';

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.amount,
    required this.tagIds,
    required this.createdAt,
    this.notes,
    this.merchantName,
    this.upiId,
    this.paymentAppId,
    this.paymentAppName,
    this.status = ExpenseStatus.success,
    this.receiptPath,
    this.paymentSource,
    this.isManual = false,
    this.currency = 'INR',
  });

  final String id;
  final double amount;
  final List<String> tagIds;
  final DateTime createdAt;
  final String? notes;
  final String? merchantName;
  final String? upiId;
  final String? paymentAppId;
  final String? paymentAppName;
  final ExpenseStatus status;
  final String? receiptPath;
  final String? paymentSource;
  final bool isManual;
  final String currency;

  Expense copyWith({
    String? id,
    double? amount,
    List<String>? tagIds,
    DateTime? createdAt,
    String? notes,
    String? merchantName,
    String? upiId,
    String? paymentAppId,
    String? paymentAppName,
    ExpenseStatus? status,
    String? receiptPath,
    String? paymentSource,
    bool? isManual,
    String? currency,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      tagIds: tagIds ?? this.tagIds,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      merchantName: merchantName ?? this.merchantName,
      upiId: upiId ?? this.upiId,
      paymentAppId: paymentAppId ?? this.paymentAppId,
      paymentAppName: paymentAppName ?? this.paymentAppName,
      status: status ?? this.status,
      receiptPath: receiptPath ?? this.receiptPath,
      paymentSource: paymentSource ?? this.paymentSource,
      isManual: isManual ?? this.isManual,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'tagIds': tagIds,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'merchantName': merchantName,
        'upiId': upiId,
        'paymentAppId': paymentAppId,
        'paymentAppName': paymentAppName,
        'status': status.name,
        'receiptPath': receiptPath,
        'paymentSource': paymentSource,
        'isManual': isManual,
        'currency': currency,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        tagIds: List<String>.from(json['tagIds'] as List),
        createdAt: DateTime.parse(json['createdAt'] as String),
        notes: json['notes'] as String?,
        merchantName: json['merchantName'] as String?,
        upiId: json['upiId'] as String?,
        paymentAppId: json['paymentAppId'] as String?,
        paymentAppName: json['paymentAppName'] as String?,
        status: ExpenseStatus.fromString(json['status'] as String? ?? 'success'),
        receiptPath: json['receiptPath'] as String?,
        paymentSource: json['paymentSource'] as String?,
        isManual: json['isManual'] as bool? ?? false,
        currency: json['currency'] as String? ?? 'INR',
      );

  @override
  List<Object?> get props => [
        id,
        amount,
        tagIds,
        createdAt,
        notes,
        merchantName,
        upiId,
        paymentAppId,
        paymentAppName,
        status,
        receiptPath,
        paymentSource,
        isManual,
        currency,
      ];
}
