import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/savings/domain/entities/saving_goal_entity.dart';
import 'package:flutter_app/features/savings/domain/repositories/saving_goal_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetSavingGoalsUseCase {
  const GetSavingGoalsUseCase(this._repository);
  final SavingGoalRepository _repository;
  Future<Either<Failure, List<SavingGoalEntity>>> call() => _repository.getGoals();
}
