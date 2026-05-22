import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class AuthService {
  AuthService(this._prefs, this._secureStorage);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool get isOnboardingComplete =>
      _prefs.getBool(AppConstants.prefOnboardingDone) ?? false;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(AppConstants.prefOnboardingDone, true);
  }

  bool get isBiometricEnabled =>
      _prefs.getBool(AppConstants.prefBiometricEnabled) ?? false;

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.prefBiometricEnabled, enabled);
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock PayTrack to view your expenses',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPin() async {
    final hash = await _secureStorage.read(key: AppConstants.prefPinHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _secureStorage.write(key: AppConstants.prefPinHash, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: AppConstants.prefPinHash);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  Future<void> removePin() async {
    await _secureStorage.delete(key: AppConstants.prefPinHash);
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('paytrack_$pin');
    return sha256.convert(bytes).toString();
  }

  Future<bool> shouldLock() async {
    return await hasPin() || isBiometricEnabled;
  }
}
