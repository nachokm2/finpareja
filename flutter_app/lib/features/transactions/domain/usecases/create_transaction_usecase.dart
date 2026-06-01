import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateTransactionUseCase {
  const CreateTransactionUseCase(this._repository);
  final TransactionRepository _repository;

  Future<Either<Failure, TransactionEntity>> call({
    required String tipo,
    required double monto,
    required DateTime fecha,
    String? descripcion,
    int? categoriaId,
    bool esCompartido = false,
    String moneda = 'CLP',
    String? notas,
  }) =>
      _repository.createTransaction(
        tipo: tipo,
        monto: monto,
        fecha: fecha,
        descripcion: descripcion,
        categoriaId: categoriaId,
        esCompartido: esCompartido,
        moneda: moneda,
        notas: notas,
      );
}
