import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/upi_app_info.dart';

class UpiLaunchException implements Exception {
  UpiLaunchException(this.message, {this.packageName});

  final String message;
  final String? packageName;

  @override
  String toString() => message;
}

class UpiPaymentService {
  static const _channel = MethodChannel('com.upitracker/upi');

  Future<List<UpiAppInfo>> getInstalledUpiApps({String? verifyUri}) async {
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<List<dynamic>>(
          'getInstalledUpiApps',
        );
        if (result != null) {
          final installedPackages = result.cast<String>().toSet();
          return UpiAppInfo.knownApps
              .map((app) => app.copyWith(
                    isInstalled: installedPackages.contains(app.packageName),
                  ))
              .where((app) => app.isInstalled)
              .toList();
        }
      } catch (e) {
        debugPrint('UPI app detection failed: $e');
      }
      return [];
    }

    return UpiAppInfo.knownApps;
  }

  /// Opens the selected wallet via explicit Android package intent.
  Future<bool> launchPayment({
    required String upiUri,
    required String packageName,
    required String appName,
  }) async {
    if (packageName.isEmpty) {
      throw UpiLaunchException('No payment app selected');
    }

    if (Platform.isAndroid) {
      try {
        final launched = await _channel.invokeMethod<bool>('launchUpiIntent', {
          'uri': upiUri,
          'package': packageName,
        });
        if (launched == true) return true;

        throw UpiLaunchException(
          'Could not open $appName. Install it and try again, or pick "Other UPI apps".',
          packageName: packageName,
        );
      } on PlatformException catch (e) {
        throw UpiLaunchException(
          'Failed to launch $appName: ${e.message}',
          packageName: packageName,
        );
      }
    }

    final uri = Uri.parse(upiUri);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  Future<bool> launchGenericChooser(String upiUri) async {
    if (Platform.isAndroid) {
      try {
        final launched = await _channel.invokeMethod<bool>('launchUpiChooser', {
          'uri': upiUri,
        });
        return launched == true;
      } catch (e) {
        debugPrint('UPI chooser failed: $e');
        return false;
      }
    }

    final uri = Uri.parse(upiUri);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
