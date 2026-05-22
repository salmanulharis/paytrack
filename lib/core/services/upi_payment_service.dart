import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/upi_app_info.dart';

class UpiPaymentService {
  static const _channel = MethodChannel('com.upitracker/upi');

  Future<List<UpiAppInfo>> getInstalledUpiApps() async {
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
    }

    // iOS / fallback: return known apps (user picks, system handles)
    return UpiAppInfo.knownApps;
  }

  Future<bool> launchPayment({
    required String upiUri,
    String? packageName,
  }) async {
    if (Platform.isAndroid && packageName != null) {
      try {
        final launched = await _channel.invokeMethod<bool>('launchUpiIntent', {
          'uri': upiUri,
          'package': packageName,
        });
        if (launched == true) return true;
      } catch (e) {
        debugPrint('Android intent launch failed: $e');
      }
    }

    final uri = Uri.parse(upiUri);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> launchGenericChooser(String upiUri) async {
    if (Platform.isAndroid) {
      try {
        final launched = await _channel.invokeMethod<bool>('launchUpiChooser', {
          'uri': upiUri,
        });
        if (launched == true) return true;
      } catch (_) {}
    }
    return launchUrl(
      Uri.parse(upiUri),
      mode: LaunchMode.externalApplication,
    );
  }
}
