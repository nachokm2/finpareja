import 'package:dio/dio.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:flutter_app/features/reports/domain/entities/category_breakdown.dart';
import 'package:flutter_app/features/reports/domain/entities/evolution_point.dart';
import 'package:flutter_app/features/reports/domain/entities/net_worth.dart';
import 'package:flutter_app/features/reports/domain/repositories/report_repository.dart';
import 'package:fpdart/fpdart.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._remote);
  final ReportRemoteDataSource _remote;

  Failure _mapDio(DioException e) =>
      e.type == DioExceptionType.connectionError
          ? const NetworkFailure()
          : ServerFailure('Error ${e.response?.statusCode}');

  @override
  Future<Either<Failure, CategoryBreakdown>> getCategoryBreakdown({
    required int anio,
    required int mes,
    String tipo = 'gasto',
  }) async {
    try {
      return Right(await _remote.getCategoryBreakdown(
        anio: anio,
        mes: mes,
        tipo: tipo,
      ));
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<EvolutionPoint>>> getEvolution({
    int meses = 6,
  }) async {
    try {
      return Right(await _remote.getEvolution(meses: meses));
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NetWorth>> getNetWorth() async {
    try {
      return Right(await _remote.getNetWorth());
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
