import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CacheInterceptor extends Interceptor {
  final Map<String, Response> _cache = {};
  String? _currentUserToken;
  
  // Cache durations in milliseconds
  static const int defaultCacheDuration = 60000; // 1 minute

  /// Sets the current user token to isolate cache between users.
  void setCurrentUser(String? token) {
    if (_currentUserToken != token) {
      debugPrint('👤 [CACHE] User switched. Clearing old cache.');
      clear();
      _currentUserToken = token;
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method != 'GET') {
      return handler.next(options);
    }

    final bool useCache = options.extra['useCache'] == true;
    final bool refresh = options.extra['refresh'] == true;

    if (useCache && !refresh) {
      final cacheKey = _getCacheKey(options);
      final cachedResponse = _cache[cacheKey];

      if (cachedResponse != null) {
        final cacheTime = cachedResponse.requestOptions.extra['cacheTime'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        final duration = options.extra['cacheDuration'] ?? defaultCacheDuration;

        if (now - cacheTime < duration) {
          debugPrint('🎯 [CACHE] Hit: ${options.path}');
          return handler.resolve(cachedResponse);
        } else {
          _cache.remove(cacheKey);
          debugPrint('⌛ [CACHE] Expired: ${options.path}');
        }
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method == 'GET' && response.requestOptions.extra['useCache'] == true) {
      final cacheKey = _getCacheKey(response.requestOptions);
      response.requestOptions.extra['cacheTime'] = DateTime.now().millisecondsSinceEpoch;
      _cache[cacheKey] = response;
      debugPrint('💾 [CACHE] Saved: ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  String _getCacheKey(RequestOptions options) {
    // Include user token in cache key for isolation
    return '${_currentUserToken ?? 'anonymous'}_${options.path}_${options.queryParameters.toString()}';
  }

  void invalidateCache(String pathPattern) {
    _cache.removeWhere((key, value) => key.contains(pathPattern));
    debugPrint('🧹 [CACHE] Invalidated: $pathPattern');
  }

  void clear() {
    _cache.clear();
    debugPrint('🧹 [CACHE] All cleared.');
  }

  int get cacheCount => _cache.length;
}
