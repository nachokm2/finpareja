import 'package:dio/dio.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/budgets/data/datasources/budget_remote_datasource.dart';
import 'package:flutter_app/features/budgets/data/models/budget_model.dart';
import 'package:flutter_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_app/features/budgets/domain/repositories/budget_repository.dart';
import 'package:fpdart/fpdart.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._remote);
  final BudgetRemoteDataSource _remote;

  Failure _map(DioException e) =>
      e.type == DioExceptionType.connectionError ? const NetworkFailure() : const ServerFailure();

  @override
  Future<Either<Failure, List<BudgetEntity>>> getBudgets({int? mes, int? anio}) async {
    try {
      return Right(await _remote.getBudgets(mes: mes, anio: anio));
    } on DioException catch (e) { return Left(_map(e)); }
    catch (e) { return Left(UnknownFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, BudgetEntity>> createBudget({
    required double montoLimite, int? categoriaId, int? mes, int? anio, double alertaPorcentaje = 80,
  }) async {
    try {
      final model = BudgetModel(
        id: 0, usuarioId: 0, montoLimite: montoLimite, periodo: 'mensual',
        alertaPorcentaje: alertaPorcentaje, categoriaId: categoriaId, mes: mes, anio: anio,
      );
      return Right(await _remote.createBudget(model.toJson()));
    } on DioException catch (e) { return Left(_map(e)); }
    catch (e) { return Left(UnknownFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, void>> deleteBudget(int id) async {
    try {
      await _remote.deleteBudget(id);
      return const Right(null);
    } on DioException catch (e) { return Left(_map(e)); }
    catch (e) { return Left(UnknownFailure(e.toString())); }
  }
}
