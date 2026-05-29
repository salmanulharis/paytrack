import 'package:flutter/foundation.dart';

/// Debug-only logging. Never logs in release builds.
void appLog(String message, [Object? error]) {
  if (!kDebugMode) return;
  if (error != null) {
    debugPrint('$message: $error');
  } else {
    debugPrint(message);
  }
}
