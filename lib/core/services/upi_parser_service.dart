import '../../domain/entities/upi_payment_data.dart';

/// Parses UPI QR codes and payment URIs per NPCI UPI specification.
class UpiParserService {
  UpiPaymentData? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.toLowerCase().startsWith('upi://') ||
        trimmed.toLowerCase().contains('upi://pay')) {
      return _parseUri(trimmed);
    }

    if (trimmed.startsWith('{')) {
      return _parseJsonQr(trimmed);
    }

    return _parseUri('upi://pay?$trimmed');
  }

  UpiPaymentData? _parseUri(String uri) {
    try {
      final normalized = uri.contains('://')
          ? uri
          : 'upi://pay?$uri';
      final parsed = Uri.parse(normalized);
      final params = parsed.queryParameters;

      final pa = params['pa'] ?? params['vpa'];
      if (pa == null || pa.isEmpty) return null;

      return UpiPaymentData(
        upiId: pa,
        merchantName: params['pn'],
        amount: params['am'] != null ? double.tryParse(params['am']!) : null,
        currency: params['cu'] ?? 'INR',
        transactionNote: params['tn'] ?? params['note'],
        rawPayload: uri,
      );
    } catch (_) {
      return null;
    }
  }

  UpiPaymentData? _parseJsonQr(String json) {
    try {
      // Simple key extraction for Bharat QR JSON
      final paMatch = RegExp(r'pa=([^&\s"]+)').firstMatch(json);
      final pnMatch = RegExp(r'pn=([^&\s"]+)').firstMatch(json);
      final amMatch = RegExp(r'am=([^&\s"]+)').firstMatch(json);

      final upiId = paMatch?.group(1);
      if (upiId == null) return null;

      return UpiPaymentData(
        upiId: Uri.decodeComponent(upiId),
        merchantName: pnMatch != null
            ? Uri.decodeComponent(pnMatch.group(1)!)
            : null,
        amount: amMatch != null ? double.tryParse(amMatch.group(1)!) : null,
        currency: 'INR',
        rawPayload: json,
      );
    } catch (_) {
      return null;
    }
  }

  String buildUpiUri({
    required String upiId,
    String? merchantName,
    required double amount,
    String currency = 'INR',
    String? transactionNote,
  }) {
    final params = <String, String>{
      'pa': upiId,
      'am': amount.toStringAsFixed(2),
      'cu': currency,
    };
    if (merchantName != null && merchantName.isNotEmpty) {
      params['pn'] = merchantName;
    }
    if (transactionNote != null && transactionNote.isNotEmpty) {
      params['tn'] = transactionNote;
    }
    return Uri(queryParameters: params).replace(
      scheme: 'upi',
      host: 'pay',
    ).toString();
  }
}
