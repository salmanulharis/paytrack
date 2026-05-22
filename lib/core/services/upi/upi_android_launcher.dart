import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';

/// Android-only UPI intent launcher (no-op on other platforms).
Future<bool> launchAndroidUpiIntent({
  required String upiUri,
  required String packageName,
}) async {
  if (!Platform.isAndroid) return false;

  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: upiUri,
      package: packageName,
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
    return true;
  } catch (e) {
    debugPrint('AndroidIntent UPI launch failed: $e');
    return false;
  }
}
