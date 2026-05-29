/// Routes where the global quick-action FAB may appear (strict whitelist).
///
/// Enforced by mounting [QuickActionFabHost] only on these screens — not by
/// parsing GoRouter state (which is unreliable with shell + push navigation).
const quickActionFabAllowedRoutes = <String>{
  '/',
  '/expenses',
  '/analytics',
};

/// Normalizes a path for documentation/tests.
String normalizeRoutePath(String path) {
  var normalized = path.trim();
  if (normalized.isEmpty) return '/';
  final queryIndex = normalized.indexOf('?');
  if (queryIndex >= 0) {
    normalized = normalized.substring(0, queryIndex);
  }
  if (!normalized.startsWith('/')) {
    normalized = '/$normalized';
  }
  if (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

/// Whether [location] is a main-tab route (for tests and docs).
bool quickActionFabVisibleOnRoute(
  String location, {
  bool paymentInProgress = false,
}) {
  if (paymentInProgress) return false;
  return quickActionFabAllowedRoutes.contains(normalizeRoutePath(location));
}

bool shouldShowQuickActionFab({
  required String location,
  required bool floatingEnabled,
  bool paymentInProgress = false,
}) {
  if (!floatingEnabled) return false;
  return quickActionFabVisibleOnRoute(
    location,
    paymentInProgress: paymentInProgress,
  );
}
