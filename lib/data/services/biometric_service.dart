import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'localization_service.dart';

/// Wraps OS biometric auth + secure credential storage.
///
/// Flow: after a successful password login the user can opt in. Credentials are
/// written to the platform keystore; subsequent sign-ins unlock via biometric
/// then re-hit /login so the JWT is always fresh.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  static const _emailKey = 'biometric_email';
  static const _passwordKey = 'biometric_password';
  static const _enabledKey = 'biometric_enabled';
  static const _promptedKey = 'biometric_prompted';

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// True when the device has biometric hardware that the user has enrolled.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// True when stored credentials exist AND the user toggled biometric on.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_enabledKey) ?? false)) return false;
    return await _storage.containsKey(key: _emailKey) &&
        await _storage.containsKey(key: _passwordKey);
  }

  /// True once we've already asked the user (so we don't re-prompt on every login).
  Future<bool> hasPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_promptedKey) ?? false;
  }

  Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promptedKey, true);
  }

  /// Triggers the OS prompt. Returns true on a successful auth.
  Future<bool> authenticate({String? reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason ?? tr('biometric_reason'),
        authMessages: [
          AndroidAuthMessages(
            signInTitle: tr('biometric_sign_in_title'),
            cancelButton: tr('cancel'),
          ),
          IOSAuthMessages(cancelButton: tr('cancel')),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Persist credentials and flip the enabled flag. Caller is expected to
  /// have just verified them via a successful /login.
  Future<void> enable({required String email, required String password}) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    await prefs.setBool(_promptedKey, true);
  }

  Future<void> disable() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
  }

  /// Returns `(email, password)` if enabled, otherwise null.
  Future<({String email, String password})?> readCredentials() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }
}
