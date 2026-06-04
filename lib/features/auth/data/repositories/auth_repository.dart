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
        final token = data['token'] ?? data['data']?['token'];
        final userData = data['user'] ?? data['data']?['user'];

        if (token != null) {
          await _storageService.saveToken(token);
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

  Future<void> registerVendor({
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
      
      if (response.statusCode != 200 && response.statusCode != 201) {
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
    await _storageService.clearAll();
  }
}
