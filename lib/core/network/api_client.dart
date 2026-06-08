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
      'Content-Type': 'application/json',
      'Api-Request-Signature': 'mobile-app-request',
    },
  )) {
    _dio.interceptors.add(DioInterceptor(storageService));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      requestHeader: true,
      responseBody: true,
      responseHeader: true,
      error: true,
    ));
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
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
    print('======================');
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}