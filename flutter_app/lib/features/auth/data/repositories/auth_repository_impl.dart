import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.remote, required this.storage});

  final AuthRemoteDataSource remote;
  final FlutterSecureStorage storage;

  @override
  Future<Either<Failure, void>> login(String email, String password) async {
    try {
      final resp = await remote.login(email, password);
      final access = resp['access_token'] as String;
      final refresh = resp['refresh_token'] as String;
      await saveTokens(access, refresh);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String? avatarUrl,
  }) async {
    try {
      await remote.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        avatarUrl: avatarUrl,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final data = await remote.me();
      return Right(UserModel.fromJson(data));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken != null) {
      await remote.logout(refreshToken);
    }
    await clearTokens();
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }

  @override
  Future<String?> getAccessToken() => storage.read(key: 'access_token');

  Failure _mapDioError(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.connectionError =>
          const NetworkFailure(),
        DioExceptionType.badResponse => e.response?.statusCode == 401
            ? const AuthFailure()
            : ServerFailure('Error ${e.response?.statusCode ?? 'desconocido'}'),
        _ => const UnknownFailure(),
      };
}
