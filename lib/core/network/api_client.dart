import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'dio_interceptor.dart';
import 'cache_interceptor.dart';
import 'performance_interceptor.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  final Dio _dio;
  final CacheInterceptor cacheInterceptor = CacheInterceptor();

  ApiClient(SecureStorageService storageService)
      : _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 120), // Added send timeout for large uploads
    contentType: null,
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'Api-Request-Signature': 'mobile-app-request',
    },
  )) {
    print('ApiClient Initialized with Base URL: ${ApiConstants.baseUrl}');
    _dio.interceptors.add(PerformanceInterceptor());
    _dio.interceptors.add(cacheInterceptor);
    _dio.interceptors.add(DioInterceptor(storageService));
    _dio.interceptors.add(LogInterceptor(
      requestBody: false, // Reduced log noise for performance
      requestHeader: true,
      responseBody: false, // Reduced log noise
      responseHeader: false,
      error: true,
    ));
  }

  void printLog(String message) {
    print(message);
  }

  /// Sets the current user to isolate cache and provide user-specific logging.
  void setCurrentUser(String? token, {String? userId}) {
    cacheInterceptor.setCurrentUser(token);
    if (userId != null) {
      printLog('👤 [USER] Active User ID: $userId');
    }
  }

  int get cacheCount => cacheInterceptor.cacheCount;

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return await _dio.get(path,
        queryParameters: queryParameters, options: options, cancelToken: cancelToken);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  Future<Response> put(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> patch(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    return await _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> delete(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
