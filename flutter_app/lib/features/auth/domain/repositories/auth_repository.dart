import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> login(String email, String password);

  Future<Either<Failure, void>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String? avatarUrl,
  });

  Future<Either<Failure, User>> getProfile();

  /// Siempre retorna void — los tokens se limpian localmente
  /// independientemente de si el backend responde.
  Future<void> logout();

  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<void> clearTokens();
  Future<String?> getAccessToken();
}
