import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/savings/data/datasources/saving_goal_remote_datasource.dart';
import 'package:flutter_app/features/savings/data/repositories/saving_goal_repository_impl.dart';
import 'package:flutter_app/features/savings/domain/entities/saving_goal_entity.dart';
import 'package:flutter_app/features/savings/domain/usecases/add_contribution_usecase.dart';
import 'package:flutter_app/features/savings/domain/usecases/get_saving_goals_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _savingsRepoProvider = FutureProvider((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return SavingGoalRepositoryImpl(SavingGoalRemoteDataSource(dio));
});

final savingGoalsProvider = AsyncNotifierProvider<SavingGoalsNotifier, List<SavingGoalEntity>>(SavingGoalsNotifier.new);

class SavingGoalsNotifier extends AsyncNotifier<List<SavingGoalEntity>> {
  @override
  Future<List<SavingGoalEntity>> build() => _fetch();

  Future<List<SavingGoalEntity>> _fetch() async {
    final repo = await ref.read(_savingsRepoProvider.future);
    final result = await GetSavingGoalsUseCase(repo).call();
    return result.fold((f) => throw Exception(f.message), (list) => list);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> addContribution(int goalId, double monto) async {
    final repo = await ref.read(_savingsRepoProvider.future);
    final result = await AddContributionUseCase(repo).call(
      goalId: goalId, monto: monto, fecha: DateTime.now(),
    );
    return result.fold((f) => false, (updated) {
      state.whenData((list) {
        state = AsyncValue.data(list.map((g) => g.id == goalId ? updated : g).toList());
      });
      return true;
    });
  }
}
