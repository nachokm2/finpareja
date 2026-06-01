import 'package:dio/dio.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/savings/data/datasources/saving_goal_remote_datasource.dart';
import 'package:flutter_app/features/savings/domain/entities/saving_goal_entity.dart';
import 'package:flutter_app/features/savings/domain/repositories/saving_goal_repository.dart';
import 'package:fpdart/fpdart.dart';

class SavingGoalRepositoryImpl implements SavingGoalRepository {
  const SavingGoalRepositoryImpl(this._remote);
  final SavingGoalRemoteDataSource _remote;

  Failure _map(DioException e) => e.type == DioExceptionType.connectionError
      ? const NetworkFailure() : const ServerFailure();

  @override
  Future<Either<Failure, List<SavingGoalEntity>>> getGoals() async {
    try { return Right(await _remote.getGoals()); }
    on DioException catch (e) { return Left(_map(e)); }
    catch (e) { return Left(UnknownFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, SavingGoalEntity>> createGoal({
    required String nombre, required double montoObjetivo,
    String? descripcion, String? icono, DateTime? fechaObjetivo,
  }) async {
    try {
      return Right(await _remote.createGoal({
        'nombre': nombre, 'monto_objetivo': montoObjetivo,
        if (descripcion != null) 'descripcion': descripcion,
        if (icono != null) 'icono': icono,
        if (fechaObjetivo != null)
          'fecha_objetivo': '${fechaObjetivo.year}-${fechaObjetivo.month.toString().padLeft(2,'0')}-${fechaObjetivo.day.toString().padLeft(2,'0')}',
        'moneda': 'CLP',
      }));
    } on DioException catch (e) { return Left(_map(e)); }
    catch (e) { return Left(UnknownFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, SavingGoalEntity>> addContribution({
    required int goalId, required double monto, required DateTime fecha, String? nota,
  }) async {
    try {
      return Right(await _remote.addContribution(goalId, {
        'monto': monto,
        'fecha': '${fecha.year}-${fecha.month.toString().padLeft(2,'0')}-${fecha.day.toString().padLeft(2,'0')}',
        if (nota != null) 'nota': nota,
      }));
    } on DioException catch (e) { return Left(_map(e)); }
    catch (e) { return Left(UnknownFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, void>> deleteGoal(int id) async {
    try { await _remote.deleteGoal(id); return const Right(null); }
    on DioException catch (e) { return Left(_map(e)); }
    catch (e) { return Left(UnknownFailure(e.toString())); }
  }
}
