import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_constants.dart';
import 'dio_interceptor.dart';
import 'cache_interceptor.dart';
import 'performance_interceptor.dart';
import 'retry_interceptor.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  final Dio _dio;
  final CacheInterceptor cacheInterceptor = CacheInterceptor();
  late final DioInterceptor _dioInterceptor;
  VoidCallback? onUnauthorized;

  ApiClient(SecureStorageService storageService, {this.onUnauthorized})
      : _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 120), // Increased for long videos
    receiveTimeout: const Duration(seconds: 120), // Increased for long videos
    sendTimeout: const Duration(seconds: 300),    // Increased to 5 minutes for large uploads
    contentType: null,
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'Api-Request-Signature': 'mobile-app-request',
    },
  )) {
    if (kDebugMode) {
      print('ApiClient Initialized with Base URL: ${ApiConstants.baseUrl}');
    }
    _dioInterceptor = DioInterceptor(storageService, onUnauthorized: () {
      onUnauthorized?.call();
    });
    
    _dio.interceptors.add(PerformanceInterceptor());
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
    _dio.interceptors.add(cacheInterceptor);
    _dio.interceptors.add(_dioInterceptor);
    _dio.interceptors.add(LogInterceptor(
      requestBody: false, // Reduced log noise for performance
      requestHeader: true,
      responseBody: false, // Reduced log noise
      responseHeader: false,
      error: true,
    ));
  }

  void printLog(String message) {
    if (kDebugMode) {
      print(message);
    }
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
