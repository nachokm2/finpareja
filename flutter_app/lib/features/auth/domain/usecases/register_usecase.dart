import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> call({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String? avatarUrl,
  }) =>
      _repository.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        avatarUrl: avatarUrl,
      );
}
