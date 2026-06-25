import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _accessKey = 'access_token';
const _refreshKey = 'refresh_token';

// Native storage — Keychain on iOS, Keystore on Android.
const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Platform-aware JWT token store.
///
/// Web:    SharedPreferences → plain localStorage; no WebCrypto required,
///         so it works on HTTP (dev server accessed via IP address).
/// Native: FlutterSecureStorage → OS keychain / encrypted keystore.
class TokenStore {
  TokenStore._();

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, access);
      await prefs.setString(_refreshKey, refresh);
    } else {
      await Future.wait([
        _secureStorage.write(key: _accessKey, value: access),
        _secureStorage.write(key: _refreshKey, value: refresh),
      ]);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessKey);
    }
    return _secureStorage.read(key: _accessKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshKey);
    }
    return _secureStorage.read(key: _refreshKey);
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
    } else {
      await Future.wait([
        _secureStorage.delete(key: _accessKey),
        _secureStorage.delete(key: _refreshKey),
      ]);
    }
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

final tokenStore = TokenStore._();
