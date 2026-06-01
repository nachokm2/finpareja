import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_app/features/budgets/domain/repositories/budget_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateBudgetUseCase {
  const CreateBudgetUseCase(this._repository);
  final BudgetRepository _repository;
  Future<Either<Failure, BudgetEntity>> call({
    required double montoLimite,
    int? categoriaId,
    int? mes,
    int? anio,
    double alertaPorcentaje = 80,
  }) => _repository.createBudget(
        montoLimite: montoLimite, categoriaId: categoriaId,
        mes: mes, anio: anio, alertaPorcentaje: alertaPorcentaje,
      );
}
