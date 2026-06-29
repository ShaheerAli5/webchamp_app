import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';
  static const String _keySession = 'session_cookie';
  static const String _keyRememberMe = 'remember_me_creds';

  // --- Core Session Methods ---

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> saveUserData(String userDataJson) async {
    await _storage.write(key: _keyUser, value: userDataJson);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: _keyUser);
  }

  Future<void> saveSession(String session) async {
    await _storage.write(key: _keySession, value: session);
  }

  Future<String?> getSession() async {
    return await _storage.read(key: _keySession);
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
    await _storage.delete(key: _keySession);
  }

  // --- Remember Me Helpers ---

  Future<void> saveRememberMe(String email, String password) async {
    await _storage.write(key: _keyRememberMe, value: jsonEncode({'email': email, 'password': password}));
  }

  Future<Map<String, String>?> getRememberMe() async {
    final data = await _storage.read(key: _keyRememberMe);
    if (data == null) return null;
    try {
      final Map<String, dynamic> decoded = jsonDecode(data);
      return {'email': decoded['email'].toString(), 'password': decoded['password'].toString()};
    } catch (e) {
      return null;
    }
  }

  Future<void> clearRememberMe() async {
    await _storage.delete(key: _keyRememberMe);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // --- Generic Helpers ---

  Future<void> saveTokenByKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getTokenByKey(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> removeTokenByKey(String key) async {
    await _storage.delete(key: key);
  }
}
