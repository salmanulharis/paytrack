import 'package:equatable/equatable.dart';

class UpiPaymentData extends Equatable {
  const UpiPaymentData({
    required this.upiId,
    this.merchantName,
    this.amount,
    this.currency = 'INR',
    this.transactionNote,
    this.rawPayload,
  });

  final String upiId;
  final String? merchantName;
  final double? amount;
  final String currency;
  final String? transactionNote;
  final String? rawPayload;

  UpiPaymentData copyWith({
    String? upiId,
    String? merchantName,
    double? amount,
    String? currency,
    String? transactionNote,
    String? rawPayload,
  }) {
    return UpiPaymentData(
      upiId: upiId ?? this.upiId,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transactionNote: transactionNote ?? this.transactionNote,
      rawPayload: rawPayload ?? this.rawPayload,
    );
  }

  @override
  List<Object?> get props =>
      [upiId, merchantName, amount, currency, transactionNote, rawPayload];
}
