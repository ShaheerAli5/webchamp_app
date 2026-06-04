import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  Future<void> saveUserData(String userDataJson) async {
    await _storage.write(key: _keyUser, value: userDataJson);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: _keyUser);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
