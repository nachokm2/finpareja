import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/savings/domain/entities/saving_goal_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class SavingGoalRepository {
  Future<Either<Failure, List<SavingGoalEntity>>> getGoals();
  Future<Either<Failure, SavingGoalEntity>> createGoal({
    required String nombre,
    required double montoObjetivo,
    String? descripcion,
    String? icono,
    DateTime? fechaObjetivo,
  });
  Future<Either<Failure, SavingGoalEntity>> addContribution({
    required int goalId,
    required double monto,
    required DateTime fecha,
    String? nota,
  });
  Future<Either<Failure, void>> deleteGoal(int id);
}
