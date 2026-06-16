import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/budgets/data/datasources/budget_remote_datasource.dart';
import 'package:flutter_app/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:flutter_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_app/features/budgets/domain/usecases/create_budget_usecase.dart';
import 'package:flutter_app/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _budgetRepoProvider = FutureProvider((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return BudgetRepositoryImpl(BudgetRemoteDataSource(dio));
});

final budgetsProvider = AsyncNotifierProvider<BudgetsNotifier, List<BudgetEntity>>(BudgetsNotifier.new);

class BudgetsNotifier extends AsyncNotifier<List<BudgetEntity>> {
  @override
  Future<List<BudgetEntity>> build() => _fetch();

  Future<List<BudgetEntity>> _fetch() async {
    final repo = await ref.read(_budgetRepoProvider.future);
    final now = DateTime.now();
    final result = await GetBudgetsUseCase(repo).call(mes: now.month, anio: now.year);
    return result.fold((f) => throw Exception(f.message), (list) => list);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> create({required double montoLimite, int? categoriaId}) async {
    final repo = await ref.read(_budgetRepoProvider.future);
    final now = DateTime.now();
    final result = await CreateBudgetUseCase(repo).call(
      montoLimite: montoLimite, categoriaId: categoriaId,
      mes: now.month, anio: now.year,
    );
    return result.fold((f) => false, (b) {
      state.whenData((list) => state = AsyncValue.data([...list, b]));
      return true;
    });
  }

  Future<bool> edit({
    required int id,
    double? montoLimite,
    double? alertaPorcentaje,
  }) async {
    final repo = await ref.read(_budgetRepoProvider.future);
    final result = await repo.updateBudget(
      id: id, montoLimite: montoLimite, alertaPorcentaje: alertaPorcentaje,
    );
    if (result.isRight()) {
      await refresh(); // recalcula uso/alerta con los nuevos valores
      return true;
    }
    return false;
  }

  Future<bool> delete(int id) async {
    final repo = await ref.read(_budgetRepoProvider.future);
    final result = await repo.deleteBudget(id);
    if (result.isRight()) {
      await refresh();
      return true;
    }
    return false;
  }
}
