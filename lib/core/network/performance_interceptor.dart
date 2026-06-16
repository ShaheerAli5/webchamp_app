import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PerformanceInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logPerformance(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logPerformance(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _logPerformance(RequestOptions options, int? statusCode) {
    final startTime = options.extra['startTime'] as int?;
    if (startTime != null) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;
      debugPrint('⏱️ [PERFORMANCE] ${options.method} ${options.path} - Status: $statusCode - Time: ${duration}ms');
      
      if (duration > 1000) {
        debugPrint('⚠️ [SLOW API] This request took more than 1 second!');
      }
    }
  }
}
