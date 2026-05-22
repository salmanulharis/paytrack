import 'package:equatable/equatable.dart';

class PendingPayment extends Equatable {
  const PendingPayment({
    required this.id,
    required this.amount,
    required this.tagIds,
    required this.upiId,
    required this.startedAt,
    this.merchantName,
    this.notes,
    this.paymentAppId,
    this.paymentAppName,
    this.transactionNote,
  });

  final String id;
  final double amount;
  final List<String> tagIds;
  final String upiId;
  final DateTime startedAt;
  final String? merchantName;
  final String? notes;
  final String? paymentAppId;
  final String? paymentAppName;
  final String? transactionNote;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'tagIds': tagIds,
        'upiId': upiId,
        'startedAt': startedAt.toIso8601String(),
        'merchantName': merchantName,
        'notes': notes,
        'paymentAppId': paymentAppId,
        'paymentAppName': paymentAppName,
        'transactionNote': transactionNote,
      };

  factory PendingPayment.fromJson(Map<String, dynamic> json) => PendingPayment(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        tagIds: List<String>.from(json['tagIds'] as List),
        upiId: json['upiId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        merchantName: json['merchantName'] as String?,
        notes: json['notes'] as String?,
        paymentAppId: json['paymentAppId'] as String?,
        paymentAppName: json['paymentAppName'] as String?,
        transactionNote: json['transactionNote'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        amount,
        tagIds,
        upiId,
        startedAt,
        merchantName,
        notes,
        paymentAppId,
        paymentAppName,
        transactionNote,
      ];
}
