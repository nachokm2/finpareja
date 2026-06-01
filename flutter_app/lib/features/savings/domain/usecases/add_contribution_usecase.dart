import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/savings/domain/entities/saving_goal_entity.dart';
import 'package:flutter_app/features/savings/domain/repositories/saving_goal_repository.dart';
import 'package:fpdart/fpdart.dart';

class AddContributionUseCase {
  const AddContributionUseCase(this._repository);
  final SavingGoalRepository _repository;
  Future<Either<Failure, SavingGoalEntity>> call({
    required int goalId, required double monto,
    required DateTime fecha, String? nota,
  }) => _repository.addContribution(goalId: goalId, monto: monto, fecha: fecha, nota: nota);
}
