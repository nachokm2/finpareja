import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fpdart/fpdart.dart';

class DeleteTransactionUseCase {
  const DeleteTransactionUseCase(this._repository);
  final TransactionRepository _repository;
  Future<Either<Failure, void>> call(int id) => _repository.deleteTransaction(id);
}
