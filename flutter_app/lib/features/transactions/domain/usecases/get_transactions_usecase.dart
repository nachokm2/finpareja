import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetTransactionsUseCase {
  const GetTransactionsUseCase(this._repository);
  final TransactionRepository _repository;

  Future<Either<Failure, List<TransactionEntity>>> call({
    int page = 1,
    int pageSize = 30,
    String? tipo,
    int? mes,
    int? anio,
  }) =>
      _repository.getTransactions(
        page: page,
        pageSize: pageSize,
        tipo: tipo,
        mes: mes,
        anio: anio,
      );
}
