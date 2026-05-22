import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'auth_service.dart';

/// Fintech-style unlock grace period while switching to UPI apps / scanner.
class AuthSessionService {
  AuthSessionService(this._prefs, this._auth);

  final SharedPreferences _prefs;
  final AuthService _auth;

  DateTime? _lastUnlockedAt;
  DateTime? _lockSuspendedUntil;

  int get gracePeriodMinutes =>
      _prefs.getInt(AppConstants.prefLockGraceMinutes) ?? 3;

  /// Call after successful PIN/biometric unlock.
  void recordUnlock() {
    _lastUnlockedAt = DateTime.now();
    _lockSuspendedUntil = null;
  }

  /// Call before opening scanner, UPI app, or any external payment flow.
  void suspendLockForExternalFlow() {
    final until = DateTime.now().add(Duration(minutes: gracePeriodMinutes));
    _lockSuspendedUntil = until;
    _lastUnlockedAt = DateTime.now();
  }

  /// Refresh grace on user interaction inside the app.
  void touchActivity() {
    if (_lastUnlockedAt != null) {
      _lastUnlockedAt = DateTime.now();
    }
  }

  /// Whether the lock screen should show on resume / cold start.
  Future<bool> shouldRequireLock({bool isColdStart = false}) async {
    if (!await _auth.shouldLock()) return false;

    final now = DateTime.now();

    if (_lockSuspendedUntil != null && now.isBefore(_lockSuspendedUntil!)) {
      return false;
    }

    if (isColdStart && _lastUnlockedAt == null) {
      return true;
    }

    if (_lastUnlockedAt == null) {
      return true;
    }

    final grace = Duration(minutes: gracePeriodMinutes);
    return now.difference(_lastUnlockedAt!) >= grace;
  }

  Future<void> setGracePeriodMinutes(int minutes) async {
    await _prefs.setInt(
      AppConstants.prefLockGraceMinutes,
      minutes.clamp(1, 10),
    );
  }
}
