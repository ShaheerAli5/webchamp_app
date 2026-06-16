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
      
      final String method = options.method.padRight(6);
      final String path = options.path;
      final String status = statusCode?.toString() ?? 'ERR';
      
      debugPrint('⏱️ [PERFORMANCE] $method $path - Status: $status - Time: ${duration}ms');
      
      if (duration > 1000) {
        debugPrint('⚠️ [SLOW API ALERT] ----------------------------------------');
        debugPrint('⚠️ [SLOW API] Request: $method $path');
        debugPrint('⚠️ [SLOW API] Time: ${duration}ms');
        debugPrint('⚠️ [SLOW API] Query Params: ${options.queryParameters}');
        debugPrint('⚠️ [SLOW API ALERT] ----------------------------------------');
      }

      if (duration > 2000) {
        // Here we could integrate with a crash reporting tool like Sentry or Firebase Crashlytics
        // For now, we'll just log it more prominently
        debugPrint('🛑 [CRITICAL SLOW API] $method $path took ${duration}ms');
      }
    }
  }
}
