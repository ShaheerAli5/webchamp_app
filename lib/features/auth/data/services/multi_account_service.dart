import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/saved_account_model.dart';

class MultiAccountService {
  final SecureStorageService _storageService;

  MultiAccountService(this._storageService);

  static const String _keySavedAccounts = 'saved_accounts';
  static const String _keyActiveAccountId = 'active_account_id';

  // Simple lock to prevent race conditions during writes
  Future<void>? _writeLock;

  Future<T> _synchronized<T>(Future<T> Function() action) async {
    final previousLock = _writeLock;
    final completer = Completer<T>();
    _writeLock = completer.future.then((_) => null, onError: (_) => null);

    try {
      await previousLock;
      final result = await action();
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    }
  }

  /// Saves or updates an account in the saved accounts list.
  Future<void> saveAccount(SavedAccountModel account) async {
    debugPrint('💾 [MULTI-ACCOUNT] saveAccount called for: ${account.email}');
    await _synchronized(() async {
      final accounts = await getSavedAccounts();
      debugPrint('💾 [MULTI-ACCOUNT] Current saved accounts count: ${accounts.length}');
      
      final existingIndex = accounts.indexWhere(
        (a) => a.userId == account.userId || a.email == account.email
      );

      final updatedAccount = account.copyWith(
        isCurrentAccount: true,
        lastUsedAt: DateTime.now(),
        needsReauth: false,
      );

      if (existingIndex != -1) {
        debugPrint('💾 [MULTI-ACCOUNT] Updating existing account at index: $existingIndex');
        accounts[existingIndex] = updatedAccount;
      } else {
        debugPrint('💾 [MULTI-ACCOUNT] Adding new account to list');
        accounts.add(updatedAccount);
      }

      // Mark all other accounts as not current
      for (int i = 0; i < accounts.length; i++) {
        if (accounts[i].userId != updatedAccount.userId) {
          accounts[i] = accounts[i].copyWith(isCurrentAccount: false);
        }
      }

      // Sort by lastUsedAt (newest first)
      accounts.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));

      await _saveAccountsList(accounts);
      await _storageService.saveToken(updatedAccount.accessToken);
      await _storageService.saveUserData(jsonEncode(updatedAccount.userData));
      await _setActiveAccountId(updatedAccount.userId);
      debugPrint('💾 [MULTI-ACCOUNT] Account selection state updated in storage. Total accounts: ${accounts.length}');
    });
  }

  /// Retrieves the list of all saved accounts.
  Future<List<SavedAccountModel>> getSavedAccounts() async {
    debugPrint('🔍 [MULTI-ACCOUNT] getSavedAccounts starting...');
    try {
      final String? accountsJson = await _storageService.getTokenByKey(_keySavedAccounts);
      debugPrint('🔍 [MULTI-ACCOUNT] Raw JSON from storage: ${accountsJson != null ? "FOUND" : "NULL/EMPTY"}');
      
      if (accountsJson == null || accountsJson.isEmpty) {
        debugPrint('🔍 [MULTI-ACCOUNT] No accounts found in main key. Checking migration...');
        final migrated = await _performMigration();
        if (migrated.isNotEmpty) {
          debugPrint('🔍 [MULTI-ACCOUNT] Migrated ${migrated.length} accounts.');
          return migrated;
        }
        return [];
      }

      final List<dynamic> decoded = jsonDecode(accountsJson);
      final list = decoded.map((item) => SavedAccountModel.fromMap(item)).toList();
      
      debugPrint('🔍 [MULTI-ACCOUNT] Successfully loaded ${list.length} accounts.');
      
      // Sort by lastUsedAt
      list.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      return list;
    } catch (e, stack) {
      debugPrint('❌ [MULTI-ACCOUNT] Error loading saved accounts: $e');
      debugPrint('❌ [MULTI-ACCOUNT] Stacktrace: $stack');
      // Graceful corruption handling
      return [];
    }
  }

  /// Sets an account as the active one and syncs storage.
  Future<void> switchAccount(String userId) async {
    await _synchronized(() async {
      final accounts = await getSavedAccounts();
      final index = accounts.indexWhere((a) => a.userId == userId);
      
      if (index != -1) {
        // Update isCurrentAccount flags and lastUsedAt
        for (int i = 0; i < accounts.length; i++) {
          if (i == index) {
            accounts[i] = accounts[i].copyWith(
              isCurrentAccount: true,
              lastUsedAt: DateTime.now(),
            );
          } else {
            accounts[i] = accounts[i].copyWith(isCurrentAccount: false);
          }
        }

        final targetAccount = accounts[index];
        
        // Sort by lastUsedAt
        accounts.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));

        await _saveAccountsList(accounts);
        await _storageService.saveToken(targetAccount.accessToken);
        await _storageService.saveUserData(jsonEncode(targetAccount.userData));
        await _setActiveAccountId(userId);
      }
    });
  }

  /// Removes an account from saved accounts.
  Future<void> removeAccount(String userId) async {
    await _synchronized(() async {
      final accounts = await getSavedAccounts();
      accounts.removeWhere((a) => a.userId == userId);
      
      await _saveAccountsList(accounts);
      
      final activeId = await getActiveAccountId();
      if (activeId == userId) {
        await _storageService.clearAuthData();
        await _storageService.removeTokenByKey(_keyActiveAccountId);
      }
    });
  }

  /// Marks an account as needing re-authentication (e.g., when refresh token fails).
  Future<void> markAsNeedsReauth(String userId) async {
    await _synchronized(() async {
      final accounts = await getSavedAccounts();
      final index = accounts.indexWhere((a) => a.userId == userId);
      if (index != -1) {
        accounts[index] = accounts[index].copyWith(needsReauth: true);
        await _saveAccountsList(accounts);
      }
    });
  }

  /// Gets the ID of the currently active account.
  Future<String?> getActiveAccountId() async {
    return await _storageService.getTokenByKey(_keyActiveAccountId);
  }

  /// Internal helper to save the full list.
  Future<void> _saveAccountsList(List<SavedAccountModel> accounts) async {
    final String encoded = jsonEncode(accounts.map((a) => a.toMap()).toList());
    await _storageService.saveTokenByKey(_keySavedAccounts, encoded);
  }

  /// Internal helper to set active ID.
  Future<void> _setActiveAccountId(String userId) async {
    await _storageService.saveTokenByKey(_keyActiveAccountId, userId);
  }

  /// Clears only the current session, keeps saved accounts.
  Future<void> clearCurrentSession() async {
    await _storageService.clearAuthData();
    // Keep the active ID so we know who was last logged in for UI purposes
  }

  /// Migrates single account from old keys to the new list format.
  Future<List<SavedAccountModel>> _performMigration() async {
    try {
      final token = await _storageService.getToken();
      final userDataJson = await _storageService.getUserData();
      
      if (token != null && userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        final userModel = SavedAccountModel(
          userId: userData['id']?.toString() ?? 'unknown',
          name: userData['name'] ?? 'User',
          email: userData['email'] ?? '',
          accessToken: token,
          loginTimestamp: DateTime.now(),
          lastUsedAt: DateTime.now(),
          isCurrentAccount: true,
          userData: Map<String, dynamic>.from(userData),
        );
        
        final list = [userModel];
        await _saveAccountsList(list);
        await _setActiveAccountId(userModel.userId);
        return list;
      }
    } catch (e) {
      debugPrint('Migration failed: $e');
    }
    return [];
  }
}
