import 'package:flutter/foundation.dart';

/// Cross-platform helpers (no `dart:io` — safe for web builds).
enum AppPlatformKind { android, ios, web, desktop, unknown }

AppPlatformKind get appPlatform {
  if (kIsWeb) return AppPlatformKind.web;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AppPlatformKind.android;
    case TargetPlatform.iOS:
      return AppPlatformKind.ios;
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return AppPlatformKind.desktop;
    case TargetPlatform.fuchsia:
      return AppPlatformKind.unknown;
  }
}

bool get isMobilePlatform =>
    appPlatform == AppPlatformKind.android || appPlatform == AppPlatformKind.ios;

bool get supportsUpiPayments => isMobilePlatform;
