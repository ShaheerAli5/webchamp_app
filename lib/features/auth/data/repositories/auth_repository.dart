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
      print('=== ATTEMPTING LOGIN ===');
      print('Email: $email');

      final response = await _apiService.login(email, password);

      print('Login Status Code: ${response.statusCode}');
      final data = response.data;
      print('Login Response Data: $data');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if the response body indicates a failure despite 200 OK
        if (data is Map && (data['reaction'] == 0 || data['status'] == 'failed' || data['result'] == 'failed')) {
          final errorMsg = data['message'] ?? 'Login failed';
          print('Login failed in body: $errorMsg');
          throw Exception(errorMsg);
        }

        // ✅ Check for Laravel validation errors returned with status 200
        if (data is Map && data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          final errorMsg = firstError is List ? firstError.first.toString() : firstError.toString();
          print('Validation error in body: $errorMsg');
          throw Exception(errorMsg);
        }

        // 1. Try to find the token
        final token = data['data']?['access_token'] ??
            data['access_token'] ??
            data['token'] ??
            data['data']?['token'] ??
            data['data']?['auth_token'];

        print('Extracted Token: ${token != null ? "FOUND" : "NOT FOUND"}');

        // 2. Try to find user data
        final authInfo = data['data']?['auth_info'] ?? data['auth_info'];
        final profile = authInfo?['profile'] ?? data['data']?['profile'] ?? data['profile'];

        Map<String, dynamic>? userData;

        if (profile != null && authInfo != null) {
          userData = <String, dynamic>{
            ...Map<String, dynamic>.from(profile),
            'id': authInfo['id'],
            'uuid': authInfo['uuid'],
            'role_id': authInfo['role_id'],
            'role_title': authInfo['role_title'],
            'vendor_id': authInfo['vendor_id'],
            'vendor_uid': authInfo['vendor_uid'],
            'status': authInfo['status'],
          };
        } else if (data['user'] != null) {
          userData = Map<String, dynamic>.from(data['user']);
        } else if (data['data']?['user'] != null) {
          userData = Map<String, dynamic>.from(data['data']['user']);
        } else if (profile != null) {
          // If we have profile but no authInfo, use what we have
          userData = Map<String, dynamic>.from(profile);
        } else if (data['data'] is Map && (data['data'] as Map).containsKey('id')) {
          userData = Map<String, dynamic>.from(data['data']);
        }

        print('Extracted User Data: ${userData != null ? "FOUND" : "NOT FOUND"}');

        if (token != null && userData != null) {
          await _storageService.saveToken(token.toString());
          await _storageService.saveUserData(jsonEncode(userData));
          print('=== TOKEN AND USER DATA SAVED ===');
          return UserModel.fromJson(userData);
        }

        if (token == null && userData != null) {
          throw Exception('Login successful but security token is missing. Please contact support.');
        }

        if (userData == null && token != null) {
          throw Exception('Login successful but user profile data is missing.');
        }

        // If we got 200/201 but couldn't find user data, check if it's a "success" message
        if (data is Map && data['message'] != null && (data['reaction'] == 1 || data['status'] == 'success')) {
          throw Exception('Login successful but required data is missing from response. ${data['message']}');
        }

        throw Exception('User data not found in response. Please contact support.');
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      print('DioError during login: ${e.message}');
      print('DioError response: ${e.response?.data}');
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
      print('Unexpected error during login: $e');
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

      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Check for Laravel validation errors returned with status 200
        if (data is Map && data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          final errorMsg = firstError is List ? firstError.first.toString() : firstError.toString();
          throw Exception(errorMsg);
        }
        return data;
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
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
    final token = await _storageService.getToken();
    if (token == null || token.isEmpty) return null;

    final userDataJson = await _storageService.getUserData();
    if (userDataJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userDataJson));
      } catch (e) {
        print('Error decoding saved user data: $e');
        return null;
      }
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