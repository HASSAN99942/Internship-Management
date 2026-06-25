import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/token_store.dart';
import 'api_error.dart';

/// Single Dio instance used throughout the app.
/// Auth interceptor: attaches bearer token; on 401 refreshes once (with a
/// Completer lock so concurrent 401s only trigger one refresh); on refresh
/// failure clears tokens so GoRouter redirect sends user to /login.
Dio createDioClient() {
  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  final dio = Dio(
    BaseOptions(
      baseUrl: '$baseUrl/api/v1/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(_AuthInterceptor(dio));
  return dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);
  final Dio _dio;

  // Completer lock — ensures only one token refresh runs at a time.
  static Completer<String?>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStore.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(_wrapError(err));
    }

    // Auth endpoints that should never trigger a token refresh on 401.
    final path = err.requestOptions.path;
    if (path.contains('auth/refresh/') || path.contains('auth/logout/')) {
      // A 401 here means the refresh/logout token itself is invalid — clear everything.
      await tokenStore.clearTokens();
      return handler.next(_wrapError(err));
    }
    if (path.contains('auth/login/') || path.contains('auth/register/')) {
      // Wrong credentials — pass the error straight through; don't touch stored tokens.
      return handler.next(_wrapError(err));
    }

    // Another request is already refreshing — wait for its result.
    if (_refreshCompleter != null) {
      final newToken = await _refreshCompleter!.future;
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          return handler.resolve(await _dio.fetch(err.requestOptions));
        } catch (_) {}
      }
      return handler.next(_wrapError(err));
    }

    // This request owns the refresh.
    _refreshCompleter = Completer<String?>();
    String? newAccess;

    final refreshToken = await tokenStore.getRefreshToken();
    if (refreshToken != null) {
      try {
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: _dio.options.baseUrl,
            headers: {'Content-Type': 'application/json'},
          ),
        );
        final resp = await refreshDio.post(
          'auth/refresh/',
          data: {'refresh': refreshToken},
        );
        newAccess = resp.data['access'] as String?;
        if (newAccess != null) {
          await tokenStore.saveTokens(
              access: newAccess, refresh: refreshToken);
        }
      } catch (_) {
        // Refresh failed — newAccess stays null.
      }
    }

    _refreshCompleter!.complete(newAccess);
    _refreshCompleter = null;

    if (newAccess != null) {
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      try {
        return handler.resolve(await _dio.fetch(err.requestOptions));
      } catch (_) {}
    }

    // Refresh failed entirely — clear tokens; router redirect takes over.
    await tokenStore.clearTokens();
    handler.next(_wrapError(err));
  }

  DioException _wrapError(DioException err) {
    final resp = err.response;
    if (resp != null) {
      final apiErr = ApiError.fromResponse(resp.statusCode ?? 0, resp.data);
      return DioException(
        requestOptions: err.requestOptions,
        error: apiErr,
        response: resp,
        type: err.type,
      );
    }
    return DioException(
      requestOptions: err.requestOptions,
      error: ApiError.network(err.message ?? 'Network error'),
      type: err.type,
    );
  }
}

/// Build an absolute media URL from a (potentially relative) path returned
/// by the API, e.g. "/media/cvs/file.pdf" → "http://host:8000/media/cvs/file.pdf".
String buildMediaUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  return '$base${path.startsWith('/') ? '' : '/'}$path';
}

// Global singleton — import and use `apiClient` anywhere.
final apiClient = createDioClient();
