import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    int page = 1,
    int pageSize = 30,
    String? tipo,
    int? mes,
    int? anio,
  });

  Future<Either<Failure, TransactionEntity>> createTransaction({
    required String tipo,
    required double monto,
    required DateTime fecha,
    String? descripcion,
    int? categoriaId,
    bool esCompartido = false,
    double porcentajeUsuario = 100,
    int? parejaId,
    String moneda = 'CLP',
    String? notas,
  });

  Future<Either<Failure, TransactionEntity>> updateTransaction({
    required int id,
    String? tipo,
    double? monto,
    DateTime? fecha,
    String? descripcion,
    int? categoriaId,
  });

  Future<Either<Failure, void>> deleteTransaction(int id);
}
