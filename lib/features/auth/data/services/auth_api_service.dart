import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService(this._apiClient);

  Future<Response> login(String email, String password) async {
    return await _apiClient.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      options: Options(contentType: 'application/x-www-form-urlencoded'),
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
    final body = {
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

    print('=== REGISTER BODY ===');
    print(body);
    print('====================');

    final response = await _apiClient.post(
      ApiConstants.vendorRegister,
      data: body,
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );

    return response;
  }
}