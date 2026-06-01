import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class BudgetRepository {
  Future<Either<Failure, List<BudgetEntity>>> getBudgets({int? mes, int? anio});
  Future<Either<Failure, BudgetEntity>> createBudget({
    required double montoLimite,
    int? categoriaId,
    int? mes,
    int? anio,
    double alertaPorcentaje = 80,
  });
  Future<Either<Failure, void>> deleteBudget(int id);
}
