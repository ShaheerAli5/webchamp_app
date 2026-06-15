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

    if (token != null && token.isNotEmpty) {
      // 2. Standard Laravel Authorization header
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 3. Set-up Accept header to ensure server knows we expect JSON
    options.headers['Accept'] = 'application/json';

    if (session != null && session.isNotEmpty) {
      options.headers['Cookie'] = session;
    }

    // ✅ LOG FULL REQUEST AS REQUESTED BY USER
    print('🚀 --- OUTGOING REQUEST ---');
    print('METHOD: ${options.method}');
    print('URL: ${options.uri}');
    
    // Log headers safely
    final safeHeaders = Map<String, dynamic>.from(options.headers);
    if (safeHeaders.containsKey('Authorization')) {
      safeHeaders['Authorization'] = 'Bearer [HIDDEN]';
    }
    print('HEADERS: $safeHeaders');
    print('--------------------------');

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('--- API RESPONSE ---');
    print('URL: ${response.realUri}');
    print('Status: ${response.statusCode}');

    // Capture session if server provides a new one
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      for (final cookie in cookies) {
        if (cookie.contains('PHPSESSID')) {
          final session = cookie.split(';').first;
          _storageService.saveSession(session);
          print('✅ Saved Session: $session');
        }
        if (cookie.contains('XSRF-TOKEN')) {
          // Some Laravel setups might need this
          print('Found XSRF-TOKEN in cookies');
        }
      }
    }
    handler.next(response);
  }
}
