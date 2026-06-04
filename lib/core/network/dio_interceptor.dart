import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class DioInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  DioInterceptor(this._storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle unauthorized (e.g., logout or refresh token)
    }
    super.onError(err, handler);
  }
}
