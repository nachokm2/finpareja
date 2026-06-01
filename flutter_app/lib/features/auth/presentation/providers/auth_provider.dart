import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_app/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:flutter_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Repositorio de autenticación.
/// Usa el [dioProvider] compartido para que los interceptores JWT
/// (refresh automático) sean los mismos que usan los módulos financieros.
final authRepositoryProvider = FutureProvider<AuthRepositoryImpl>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  const storage = FlutterSecureStorage();
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSource(dio),
    storage: storage,
  );
});

final loginUseCaseProvider = FutureProvider<LoginUseCase>((ref) async {
  final repo = await ref.watch(authRepositoryProvider.future);
  return LoginUseCase(repo);
});

final registerUseCaseProvider = FutureProvider<RegisterUseCase>((ref) async {
  final repo = await ref.watch(authRepositoryProvider.future);
  return RegisterUseCase(repo);
});

final getProfileUseCaseProvider = FutureProvider<GetProfileUseCase>((ref) async {
  final repo = await ref.watch(authRepositoryProvider.future);
  return GetProfileUseCase(repo);
});
