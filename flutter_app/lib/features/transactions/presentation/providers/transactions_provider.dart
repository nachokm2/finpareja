import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:flutter_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flutter_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_app/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:flutter_app/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:flutter_app/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _txRepoProvider = FutureProvider((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return TransactionRepositoryImpl(TransactionRemoteDataSource(dio));
});

/// Lista de transacciones del mes actual
final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionEntity>>(
  TransactionsNotifier.new,
);

class TransactionsNotifier extends AsyncNotifier<List<TransactionEntity>> {
  @override
  Future<List<TransactionEntity>> build() => _fetch();

  Future<List<TransactionEntity>> _fetch({
    String? tipo,
    int? mes,
    int? anio,
  }) async {
    final repo = await ref.read(_txRepoProvider.future);
    final now = DateTime.now();
    final result = await GetTransactionsUseCase(repo).call(
      tipo: tipo,
      mes: mes ?? now.month,
      anio: anio ?? now.year,
    );
    return result.fold((f) => throw Exception(f.message), (list) => list);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> create({
    required String tipo,
    required double monto,
    required DateTime fecha,
    String? descripcion,
    int? categoriaId,
    String? notas,
  }) async {
    final repo = await ref.read(_txRepoProvider.future);
    final result = await CreateTransactionUseCase(repo).call(
      tipo: tipo,
      monto: monto,
      fecha: fecha,
      descripcion: descripcion,
      categoriaId: categoriaId,
      notas: notas,
    );
    return result.fold(
      (f) => false,
      (tx) {
        state.whenData((list) {
          state = AsyncValue.data([tx, ...list]);
        });
        return true;
      },
    );
  }

  Future<bool> delete(int id) async {
    final repo = await ref.read(_txRepoProvider.future);
    final result = await DeleteTransactionUseCase(repo).call(id);
    return result.fold(
      (f) => false,
      (_) {
        state.whenData((list) {
          state = AsyncValue.data(list.where((t) => t.id != id).toList());
        });
        return true;
      },
    );
  }
}
