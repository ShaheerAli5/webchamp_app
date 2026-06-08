import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';
import '../../../../core/storage/secure_storage_service.dart';

class AuthRepository {
  final AuthApiService _apiService;
  final SecureStorageService _storageService;

  AuthRepository(this._apiService, this._storageService);

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);

      if (response.statusCode == 200) {
        final data = response.data;

        // ✅ Read token from correct path
        final token = data['data']?['access_token'] ??
            data['access_token'] ??
            data['token'] ??
            data['data']?['token'];

        // ✅ Read user data from correct path
        final authInfo = data['data']?['auth_info'];
        final profile = authInfo?['profile'];

        final userData = profile != null
            ? <String, dynamic>{
                ...Map<String, dynamic>.from(profile),
                'id': authInfo['id'],
                'uuid': authInfo['uuid'],
                'role_id': authInfo['role_id'],
                'role_title': authInfo['role_title'],
                'vendor_id': authInfo['vendor_id'],
                'vendor_uid': authInfo['vendor_uid'],
                'status': authInfo['status'],
              }
            : data['user'] != null
                ? Map<String, dynamic>.from(data['user'])
                : data['data']?['user'] != null
                    ? Map<String, dynamic>.from(data['data']['user'])
                    : null;

        if (token != null) {
          await _storageService.saveToken(token);
          print('=== TOKEN SAVED ===');
        }

        if (userData != null) {
          await _storageService.saveUserData(jsonEncode(userData));
          return UserModel.fromJson(userData);
        }

        throw Exception('User data not found in response');
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      String errorMessage = 'An error occurred during login';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map;
            errorMessage = errors.values.first.first.toString();
          } else {
            errorMessage = data['message'] ?? errorMessage;
          }
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerVendor({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String mobileNumber,
    required String vendorTitle,
    required String password,
    required String passwordConfirmation,
    required bool termsAndConditions,
  }) async {
    try {
      final response = await _apiService.registerVendor(
        firstName: firstName,
        lastName: lastName,
        email: email,
        username: username,
        mobileNumber: mobileNumber,
        vendorTitle: vendorTitle,
        password: password,
        passwordConfirmation: passwordConfirmation,
        termsAndConditions: termsAndConditions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      String errorMessage = 'An error occurred during registration';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map;
            errorMessage = errors.values.first.first.toString();
          } else {
            errorMessage = data['message'] ?? errorMessage;
          }
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getSavedUser() async {
    final userDataJson = await _storageService.getUserData();
    if (userDataJson != null) {
      return UserModel.fromJson(jsonDecode(userDataJson));
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      print('Logout API error: $e');
    } finally {
      // Always clear local storage even if API fails
      await _storageService.clearAll();
    }
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiService.updatePassword(
        oldPassword: oldPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'Password update failed');
      }
    } on DioException catch (e) {
      String errorMessage = 'An error occurred while updating password';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map;
            errorMessage = errors.values.first.first.toString();
          } else {
            errorMessage = data['message'] ?? errorMessage;
          }
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyTwoFactor({required String code}) async {
    try {
      final response = await _apiService.verifyTwoFactor(code: code);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      String errorMessage = 'Invalid or expired code';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          errorMessage = data['message'] ?? errorMessage;
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      rethrow;
    }
  }
}
