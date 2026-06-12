// auth_api_service.dart

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';

class AuthApiService {
  final ApiClient _apiClient;
  String? _sessionCookie;

  AuthApiService(this._apiClient);

  void _extractSessionCookie(Response response) {
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      for (final cookie in cookies) {
        if (cookie.contains('PHPSESSID')) {
          _sessionCookie = cookie.split(';').first;
          break;
        }
      }
    }
  }

  Future<Response> login(String email, String password) async {
    return await _apiClient.post(
      ApiConstants.login,
      queryParameters: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> registerVendor({
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
    final params = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'username': username,
      'mobile_number': mobileNumber,
      'vendor_title': vendorTitle,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'terms_and_conditions': termsAndConditions ? '1' : '0',
    };

    final response = await _apiClient.post(
      ApiConstants.vendorRegister,
      data: params,
    );

    _extractSessionCookie(response);
    return response;
  }

  Future<Response> logout() async {
    return await _apiClient.post(
      ApiConstants.logout,
    );
  }

  Future<Response> updatePassword({
    required String oldPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _apiClient.post(
      ApiConstants.updatePassword,
      data: {
        'old_password': oldPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<Response> verifyTwoFactor({
    required String code,
  }) async {
    return await _apiClient.post(
      ApiConstants.twoFactorChallenge,
      data: {
        'verify_via': 'code',
        'code': code,
      },
    );
  }
}