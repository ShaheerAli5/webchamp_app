import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _keyAccounts = 'saved_accounts';
  static const String _keyActiveId = 'active_account_id';
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';
  static const String _keySession = 'session_cookie';
  static const String _keyPasswordPrefix = 'pwd_';
  static const String _keyRememberMe = 'remember_me_creds';

  // --- Multi-Account Management ---

  Future<void> saveAccount(Map<String, dynamic> accountData, {String? password}) async {
    final accounts = await getSavedAccounts();
    final String id = accountData['id'].toString();
    final String email = accountData['email'] ?? '';
    
    // Replace if exists, otherwise add
    accounts.removeWhere((a) => a['id'].toString() == id);
    accounts.add(accountData);
    
    await _storage.write(key: _keyAccounts, value: jsonEncode(accounts));
    await setActiveAccountId(id);
    
    if (password != null && email.isNotEmpty) {
      await saveAccountPassword(email, password);
    }

    // Legacy sync
    if (accountData.containsKey('token')) {
      await saveToken(accountData['token'].toString());
    }
    await saveUserData(jsonEncode(accountData));
  }

  Future<List<Map<String, dynamic>>> getSavedAccounts() async {
    final data = await _storage.read(key: _keyAccounts);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (e) {
      return [];
    }
  }

  Future<void> setActiveAccountId(String id) async {
    await _storage.write(key: _keyActiveId, value: id);
    
    // Sync current session pointers
    final accounts = await getSavedAccounts();
    final active = accounts.firstWhere(
      (a) => a['id'].toString() == id, 
      orElse: () => <String, dynamic>{}
    );
    
    if (active.isNotEmpty) {
      if (active['token'] != null) await saveToken(active['token'].toString());
      await saveUserData(jsonEncode(active));
    }
  }

  Future<String?> getActiveAccountId() async {
    return await _storage.read(key: _keyActiveId);
  }

  Future<void> removeAccount(String id) async {
    final accounts = await getSavedAccounts();
    final account = accounts.firstWhere((a) => a['id'].toString() == id, orElse: () => {});
    if (account.isNotEmpty) {
      final email = account['email'] ?? '';
      if (email.isNotEmpty) await removeAccountPassword(email);
    }

    accounts.removeWhere((a) => a['id'].toString() == id);
    await _storage.write(key: _keyAccounts, value: jsonEncode(accounts));
    
    final activeId = await getActiveAccountId();
    if (activeId == id) {
      if (accounts.isNotEmpty) {
        await setActiveAccountId(accounts.first['id'].toString());
      } else {
        await _storage.delete(key: _keyActiveId);
        await clearAuthData();
      }
    }
  }

  // --- Password Management ---

  Future<void> saveAccountPassword(String email, String password) async {
    await _storage.write(key: '$_keyPasswordPrefix$email', value: password);
  }

  Future<String?> getAccountPassword(String email) async {
    return await _storage.read(key: '$_keyPasswordPrefix$email');
  }

  Future<void> removeAccountPassword(String email) async {
    await _storage.delete(key: '$_keyPasswordPrefix$email');
  }

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
}
