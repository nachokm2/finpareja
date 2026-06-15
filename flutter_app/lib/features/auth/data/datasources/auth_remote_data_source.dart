import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await dio
        .post('/auth/login', data: {'email': email, 'password': password});
    return resp.data;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String? avatarUrl,
  }) async {
    final payload = {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
      if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
    };
    final resp = await dio.post('/auth/register', data: payload);
    return resp.data;
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final resp =
        await dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
    return resp.data;
  }

  Future<Map<String, dynamic>> me() async {
    final resp = await dio.get('/auth/me');
    return resp.data;
  }

  Future<void> forgotPassword(String email) async {
    await dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await dio.post('/auth/reset-password', data: {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }

  /// Notifica al backend que el refresh token debe invalidarse.
  /// Si el endpoint aún no existe, se ignora el error para no
  /// bloquear el flujo de cierre de sesión en el cliente.
  Future<void> logout(String refreshToken) async {
    try {
      await dio.post('/auth/logout', data: {'refresh_token': refreshToken});
    } catch (_) {
      // Best-effort: continuar con la limpieza local aunque el backend falle
    }
  }
}
