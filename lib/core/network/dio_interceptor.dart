import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class DioInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  DioInterceptor(this._storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storageService.getToken();
    final session = await _storageService.getSession();

    // 1. Remove ANY existing token parameters to prevent URL truncation
    options.queryParameters.remove('token');
    options.queryParameters.remove('api_token');

    if (token != null) {
      // 2. Standard Laravel Authorization header (The only one needed)
      options.headers['Authorization'] = 'Bearer $token';

      // 3. Set-up Accept header to ensure server knows we expect JSON
      options.headers['Accept'] = 'application/json';
    }

    if (session != null) {
      options.headers['Cookie'] = session;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Capture session if server provides a new one
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      for (final cookie in cookies) {
        if (cookie.contains('PHPSESSID')) {
          _storageService.saveSession(cookie.split(';').first);
          break;
        }
      }
    }
    handler.next(response);
  }
}
