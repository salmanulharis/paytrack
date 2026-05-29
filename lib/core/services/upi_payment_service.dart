import 'package:flutter/services.dart';

import '../utils/app_log.dart';
import 'package:url_launcher/url_launcher.dart';

import '../platform/app_platform.dart';
import '../../domain/entities/upi_app_info.dart';
import 'upi/upi_android_launcher.dart';
import 'upi/upi_ios_uri_builder.dart';

class UpiLaunchException implements Exception {
  UpiLaunchException(this.message, {this.packageName, this.appId});

  final String message;
  final String? packageName;
  final String? appId;

  @override
  String toString() => message;
}

/// Cross-platform UPI payment launcher (Android + iOS).
class UpiPaymentService {
  static const _channel = MethodChannel('com.upitracker/upi');

  Future<List<UpiAppInfo>> getInstalledUpiApps() async {
    if (!supportsUpiPayments) return [];

    if (isMobilePlatform) {
      try {
        final result = await _channel.invokeMethod<List<dynamic>>(
          'getInstalledUpiApps',
        );
        if (result != null) {
          final installedPackages = result.cast<String>().toSet();
          final apps = UpiAppInfo.knownApps
              .map((app) => app.copyWith(
                    isInstalled: installedPackages.contains(app.packageName),
                  ))
              .where((app) => app.isInstalled)
              .toList();
          if (apps.isNotEmpty) return apps;
        }
      } catch (e) {
        appLog('Native UPI app detection failed', e);
      }
    }

    if (appPlatform == AppPlatformKind.ios) {
      return _probeIosApps();
    }

    return [];
  }

  Future<List<UpiAppInfo>> _probeIosApps() async {
    final installed = <UpiAppInfo>[];
    for (final app in UpiAppInfo.knownApps) {
      for (final scheme in app.iosSchemes) {
        final probe = Uri.parse('$scheme://');
        if (await canLaunchUrl(probe)) {
          installed.add(app.copyWith(isInstalled: true));
          break;
        }
      }
    }
    if (installed.isEmpty) {
      final generic = Uri.parse('upi://pay');
      if (await canLaunchUrl(generic)) {
        return UpiAppInfo.knownApps.map((a) => a.copyWith(isInstalled: true)).toList();
      }
    }
    return installed;
  }

  Future<bool> launchPayment({
    required String upiUri,
    required String packageName,
    required String appName,
    required String appId,
  }) async {
    if (!supportsUpiPayments) {
      throw UpiLaunchException('UPI payments are only supported on Android and iOS');
    }

    if (packageName.isEmpty && appId != 'other') {
      throw UpiLaunchException('No payment app selected');
    }

    appLog('UPI launch [$appPlatform]: $upiUri app=$appId pkg=$packageName');

    if (appPlatform == AppPlatformKind.android) {
      return _launchAndroid(upiUri, packageName, appName, appId);
    }

    if (appPlatform == AppPlatformKind.ios) {
      return _launchIos(upiUri, packageName, appName, appId);
    }

    throw UpiLaunchException('Unsupported platform for UPI');
  }

  Future<bool> _launchAndroid(
    String upiUri,
    String packageName,
    String appName,
    String appId,
  ) async {
    final viaIntent = await launchAndroidUpiIntent(
      upiUri: upiUri,
      packageName: packageName,
    );
    if (viaIntent) return true;

    try {
      final launched = await _channel.invokeMethod<bool>('launchUpiIntent', {
        'uri': upiUri,
        'package': packageName,
        'appId': appId,
      });
      if (launched == true) return true;
    } on PlatformException catch (e) {
      appLog('Android UPI channel failed', e);
    }

    if (await _openExternalUri(upiUri)) return true;

    throw UpiLaunchException(
      'Could not open $appName. Install or update the app, or choose "Other UPI apps".',
      packageName: packageName,
      appId: appId,
    );
  }

  Future<bool> _launchIos(
    String upiUri,
    String packageName,
    String appName,
    String appId,
  ) async {
    try {
      final launched = await _channel.invokeMethod<bool>('launchUpiIntent', {
        'uri': upiUri,
        'package': packageName,
        'appId': appId,
      });
      if (launched == true) return true;
    } on PlatformException catch (e) {
      appLog('iOS UPI channel failed', e);
    }

    final app = UpiAppInfo.knownApps.where((a) => a.id == appId).firstOrNull;
    if (app != null) {
      final walletUri = UpiIosUriBuilder.walletLaunchUri(app: app, upiUri: upiUri);
      if (walletUri != null && await _openExternalUri(walletUri)) {
        return true;
      }
    }

    if (await _openExternalUri(upiUri)) return true;

    throw UpiLaunchException(
      'Could not open $appName. Install it from the App Store or choose "Other UPI apps".',
      packageName: packageName,
      appId: appId,
    );
  }

  Future<bool> launchGenericChooser(String upiUri) async {
    if (!supportsUpiPayments) return false;

    if (isMobilePlatform) {
      try {
        final launched = await _channel.invokeMethod<bool>('launchUpiChooser', {
          'uri': upiUri,
        });
        if (launched == true) return true;
      } catch (e) {
        appLog('UPI chooser channel failed', e);
      }
    }

    return _openExternalUri(upiUri);
  }

  Future<bool> _openExternalUri(String uriString) async {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return false;
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      appLog('url_launcher failed', e);
    }
    return false;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
