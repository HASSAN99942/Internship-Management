import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/user.dart';

class AuthRepository {
  const AuthRepository(this._dio);
  final Dio _dio;

  /// POST /api/v1/auth/login/ → access + refresh tokens
  Future<AuthTokens> login(String email, String password) async {
    final resp = await _dio.post(
      'auth/login/',
      data: {'email': email, 'password': password},
    );
    return AuthTokens.fromJson(resp.data as Map<String, dynamic>);
  }

  /// POST /api/v1/auth/register/
  /// payload: { email, password, first_name, last_name, role, profile: {...} }
  Future<void> register(Map<String, dynamic> payload) async {
    await _dio.post('auth/register/', data: payload);
  }

  /// POST /api/v1/auth/refresh/
  Future<String> refresh(String refreshToken) async {
    final resp = await _dio.post(
      'auth/refresh/',
      data: {'refresh': refreshToken},
    );
    return resp.data['access'] as String;
  }

  /// POST /api/v1/auth/logout/ — blacklists the refresh token server-side.
  Future<void> logout(String refreshToken) async {
    await _dio.post('auth/logout/', data: {'refresh': refreshToken});
  }

  /// GET /api/v1/me/ — full user + role profile
  Future<User> me() async {
    final resp = await _dio.get('me/');
    return User.fromJson(resp.data as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(apiClient),
);
