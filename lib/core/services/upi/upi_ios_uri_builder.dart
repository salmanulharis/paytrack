import '../../../domain/entities/upi_app_info.dart';

/// Builds iOS wallet-specific deep links from a standard `upi://pay?...` URI.
class UpiIosUriBuilder {
  const UpiIosUriBuilder._();

  static String? walletLaunchUri({
    required UpiAppInfo app,
    required String upiUri,
  }) {
    if (app.iosSchemes.isEmpty) return null;

    final query = _extractQuery(upiUri);
    if (query == null || query.isEmpty) return null;

    for (final scheme in app.iosSchemes) {
      final uri = _build(scheme: scheme, payPath: app.iosPayPath, query: query);
      if (uri != null) return uri;
    }
    return null;
  }

  static String? _extractQuery(String upiUri) {
    final parsed = Uri.tryParse(upiUri);
    if (parsed == null) return null;
    if (parsed.query.isNotEmpty) return parsed.query;
    final idx = upiUri.indexOf('?');
    if (idx >= 0 && idx < upiUri.length - 1) {
      return upiUri.substring(idx + 1);
    }
    return null;
  }

  static String? _build({
    required String scheme,
    required String payPath,
    required String query,
  }) {
    final segments = payPath.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) {
      return '$scheme://pay?$query';
    }
    if (segments.length == 1) {
      return '$scheme://${segments.first}?$query';
    }
    final host = segments.first;
    final path = segments.skip(1).join('/');
    return '$scheme://$host/$path?$query';
  }
}
