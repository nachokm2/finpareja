import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/features/auth/domain/entities/user.dart';
import 'package:flutter_app/features/auth/presentation/providers/auth_provider.dart';

final profileProvider = FutureProvider<User>((ref) async {
  final useCase = await ref.watch(getProfileUseCaseProvider.future);
  final result = await useCase.call();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (user) => user,
  );
});
