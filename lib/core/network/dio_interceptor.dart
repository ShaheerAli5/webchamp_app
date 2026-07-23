import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';

class DioInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final VoidCallback? onUnauthorized;

  DioInterceptor(this._storageService, {this.onUnauthorized});

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

    // 3. Set-up Accept header if not already specified
    if (!options.headers.containsKey('Accept')) {
      options.headers['Accept'] = 'application/json';
    }

    // 🛡️ Option to force stateless (no cookies) for specific API requests
    final bool forceStateless = options.extra['stateless'] == true;

    if (session != null && session.isNotEmpty && !forceStateless) {
      options.headers['Cookie'] = session;
    }

    // ✅ LOG REQUEST ONLY IN DEBUG MODE FOR PERFORMANCE
    if (kDebugMode) {
      print('🚀 --- OUTGOING REQUEST ---');
      print('METHOD: ${options.method}');
      print('URL: ${options.uri}');
      
      // Log headers safely
      final safeHeaders = Map<String, dynamic>.from(options.headers);
      if (safeHeaders.containsKey('Authorization')) {
        safeHeaders['Authorization'] = 'Bearer [HIDDEN]';
      }
      print('HEADERS: $safeHeaders');
      
      if (options.data is FormData) {
        final formData = options.data as FormData;
        print('BODY (FormData):');
        for (final field in formData.fields) {
          print('  Field: ${field.key} = ${field.value}');
        }
        for (final file in formData.files) {
          final contentType = file.value.contentType?.toString() ?? 'unknown';
          print('  File: ${file.key}, name: ${file.value.filename}, size: ${file.value.length}, type: $contentType');
        }
      } else if (options.data != null) {
        print('BODY: ${options.data}');
      }
      print('--------------------------');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('--- API RESPONSE ---');
      print('URL: ${response.realUri}');
      print('Status: ${response.statusCode}');
      
      // Log response body safely
      final data = response.data;
      if (data is String && data.contains('<!DOCTYPE html>')) {
        print('RESPONSE BODY: [HTML CONTENT DETECTED - Possible redirect or error page]');
        // Print first 200 chars of HTML to see titles/errors
        print('BODY PREVIEW: ${data.substring(0, data.length > 500 ? 500 : data.length)}');
      } else {
        print('RESPONSE BODY: $data');
      }
      print('---------------------');
    }

    // Capture session if server provides a new one
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      for (final cookie in cookies) {
        if (cookie.contains('PHPSESSID')) {
          final session = cookie.split(';').first;
          _storageService.saveSession(session);
          if (kDebugMode) {
            print('✅ Saved Session: $session');
          }
        }
        if (cookie.contains('XSRF-TOKEN')) {
          // Some Laravel setups might need this
          if (kDebugMode) {
            print('Found XSRF-TOKEN in cookies');
          }
        }
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      debugPrint('🚨 [API] 401 Unauthorized detected. Triggering logout callback.');
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
