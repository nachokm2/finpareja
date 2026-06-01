import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/investments/data/datasources/investment_remote_datasource.dart';
import 'package:flutter_app/features/investments/data/repositories/investment_repository_impl.dart';
import 'package:flutter_app/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter_app/features/investments/domain/repositories/investment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _investmentRepoProvider =
    FutureProvider<InvestmentRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return InvestmentRepositoryImpl(InvestmentRemoteDataSource(dio));
});

final investmentsProvider =
    AsyncNotifierProvider<InvestmentsNotifier, List<InvestmentEntity>>(
  InvestmentsNotifier.new,
);

class InvestmentsNotifier extends AsyncNotifier<List<InvestmentEntity>> {
  @override
  Future<List<InvestmentEntity>> build() => _fetch();

  Future<List<InvestmentEntity>> _fetch() async {
    final repo = await ref.read(_investmentRepoProvider.future);
    final result = await repo.getInvestments();
    return result.fold((f) => throw Exception(f.message), (list) => list);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> create({
    required String nombre,
    String? tipo,
    double? cantidad,
    double? precioCompra,
    double? precioActual,
  }) async {
    final repo = await ref.read(_investmentRepoProvider.future);
    final result = await repo.createInvestment(
      nombre: nombre,
      tipo: tipo,
      cantidad: cantidad,
      precioCompra: precioCompra,
      precioActual: precioActual,
    );
    return result.fold((f) => false, (inv) {
      state.whenData((list) => state = AsyncValue.data([inv, ...list]));
      return true;
    });
  }

  Future<bool> delete(int id) async {
    final repo = await ref.read(_investmentRepoProvider.future);
    final result = await repo.deleteInvestment(id);
    return result.fold((f) => false, (_) {
      state.whenData((list) {
        state = AsyncValue.data(list.where((i) => i.id != id).toList());
      });
      return true;
    });
  }
}
