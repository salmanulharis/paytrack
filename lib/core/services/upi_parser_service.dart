import 'package:uuid/uuid.dart';

import '../../domain/entities/upi_payment_data.dart';

/// Parses UPI QR codes and builds payment URIs per NPCI UPI intent spec.
class UpiParserService {
  static const _uuid = Uuid();

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
      final normalized = uri.contains('://') ? uri : 'upi://pay?$uri';
      final parsed = Uri.parse(normalized);
      final params = parsed.queryParameters;

      final pa = params['pa'] ?? params['vpa'];
      if (pa == null || pa.isEmpty) return null;

      return UpiPaymentData(
        upiId: Uri.decodeComponent(pa),
        merchantName: params['pn'] != null ? Uri.decodeComponent(params['pn']!) : null,
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

  /// Builds the URI sent to UPI apps. Prefers merging into the scanned QR URI
  /// so Bharat QR fields (mc, tid, etc.) stay intact.
  String buildPaymentUri({
    required String upiId,
    String? merchantName,
    required double amount,
    String currency = 'INR',
    String? transactionNote,
    String? rawQrPayload,
  }) {
    if (rawQrPayload != null && _looksLikeUpiUri(rawQrPayload)) {
      return _mergeIntoScannedUri(
        rawQrPayload,
        upiId: upiId,
        merchantName: merchantName,
        amount: amount,
        currency: currency,
        transactionNote: transactionNote,
      );
    }
    return buildUpiUri(
      upiId: upiId,
      merchantName: merchantName,
      amount: amount,
      currency: currency,
      transactionNote: transactionNote,
    );
  }

  String buildUpiUri({
    required String upiId,
    String? merchantName,
    required double amount,
    String currency = 'INR',
    String? transactionNote,
  }) {
    final params = <String, String>{
      'pa': upiId.trim(),
      'am': amount.toStringAsFixed(2),
      'cu': currency,
      'mode': '00',
      'tr': _transactionRef(),
    };
    final pn = merchantName?.trim();
    if (pn != null && pn.isNotEmpty) {
      params['pn'] = pn;
    }
    final tn = transactionNote?.trim();
    if (tn != null && tn.isNotEmpty) {
      params['tn'] = tn;
    }
    return _formatUpiUri(params);
  }

  bool _looksLikeUpiUri(String raw) {
    final lower = raw.trim().toLowerCase();
    return lower.startsWith('upi://') || lower.contains('upi://pay');
  }

  String _mergeIntoScannedUri(
    String raw, {
    required String upiId,
    String? merchantName,
    required double amount,
    required String currency,
    String? transactionNote,
  }) {
    final normalized = raw.trim().contains('://')
        ? raw.trim()
        : 'upi://pay?${raw.trim()}';
    final parsed = Uri.parse(normalized);
    final params = Map<String, String>.from(parsed.queryParameters);

    params['pa'] = upiId.trim();
    params['am'] = amount.toStringAsFixed(2);
    params['cu'] = params['cu'] ?? currency;
    params['mode'] = params['mode'] ?? '00';
    params['tr'] = params['tr'] ?? _transactionRef();

    final pn = merchantName?.trim();
    if (pn != null && pn.isNotEmpty) {
      params['pn'] = pn;
    }
    final tn = transactionNote?.trim();
    if (tn != null && tn.isNotEmpty) {
      params['tn'] = tn;
    }

    return _formatUpiUri(params);
  }

  /// NPCI-style URI string (wallets expect `upi://pay?pa=...&am=...`).
  String _formatUpiUri(Map<String, String> params) {
    final query = params.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'upi://pay?$query';
  }

  String _transactionRef() {
    return _uuid.v4().replaceAll('-', '').substring(0, 20);
  }
}
