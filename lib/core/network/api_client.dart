import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'dio_interceptor.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(SecureStorageService storageService)
      : _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'Api-Request-Signature': 'mobile-app-request',
    },
  )) {
    print('ApiClient Initialized with Base URL: ${ApiConstants.baseUrl}');
    _dio.interceptors.add(DioInterceptor(storageService));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      requestHeader: true,
      responseBody: true, // 🛡️ Enabled for debugging
      responseHeader: true,
      error: true,
    ));
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    return await _dio.get(path,
        queryParameters: queryParameters, options: options);
  }

  Future<Response> post(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    print('=== API CLIENT POST ===');
    print('PATH: $path');
    print('DATA TYPE: ${data.runtimeType}');
    print('DATA: $data');
    if (options?.headers != null) print('EXTRA HEADERS: ${options!.headers}');
    if (options?.contentType != null) print('CONTENT TYPE: ${options!.contentType}');
    print('======================');
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> patch(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return await _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
