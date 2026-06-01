import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_app/features/budgets/domain/repositories/budget_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetBudgetsUseCase {
  const GetBudgetsUseCase(this._repository);
  final BudgetRepository _repository;
  Future<Either<Failure, List<BudgetEntity>>> call({int? mes, int? anio}) =>
      _repository.getBudgets(mes: mes, anio: anio);
}
