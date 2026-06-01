import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/debts/data/datasources/debt_remote_datasource.dart';
import 'package:flutter_app/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:flutter_app/features/debts/domain/entities/debt_entity.dart';
import 'package:flutter_app/features/debts/domain/repositories/debt_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _debtRepoProvider = FutureProvider<DebtRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return DebtRepositoryImpl(DebtRemoteDataSource(dio));
});

final debtsProvider =
    AsyncNotifierProvider<DebtsNotifier, List<DebtEntity>>(DebtsNotifier.new);

class DebtsNotifier extends AsyncNotifier<List<DebtEntity>> {
  @override
  Future<List<DebtEntity>> build() => _fetch();

  Future<List<DebtEntity>> _fetch() async {
    final repo = await ref.read(_debtRepoProvider.future);
    final result = await repo.getDebts();
    return result.fold((f) => throw Exception(f.message), (list) => list);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> create({
    required String acreedor,
    required double montoOriginal,
    String? tipo,
  }) async {
    final repo = await ref.read(_debtRepoProvider.future);
    final result = await repo.createDebt(
      acreedor: acreedor,
      montoOriginal: montoOriginal,
      tipo: tipo,
    );
    return result.fold((f) => false, (debt) {
      state.whenData((list) => state = AsyncValue.data([debt, ...list]));
      return true;
    });
  }

  Future<bool> addPayment(int debtId, double monto) async {
    final repo = await ref.read(_debtRepoProvider.future);
    final result = await repo.addPayment(
      debtId: debtId,
      monto: monto,
      fecha: DateTime.now(),
    );
    return result.fold((f) => false, (updated) {
      state.whenData((list) {
        state = AsyncValue.data(
            list.map((d) => d.id == debtId ? updated : d).toList());
      });
      return true;
    });
  }

  Future<bool> delete(int id) async {
    final repo = await ref.read(_debtRepoProvider.future);
    final result = await repo.deleteDebt(id);
    return result.fold((f) => false, (_) {
      state.whenData((list) {
        state = AsyncValue.data(list.where((d) => d.id != id).toList());
      });
      return true;
    });
  }
}
