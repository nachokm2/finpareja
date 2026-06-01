import 'package:dio/dio.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/investments/data/datasources/investment_remote_datasource.dart';
import 'package:flutter_app/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter_app/features/investments/domain/repositories/investment_repository.dart';
import 'package:fpdart/fpdart.dart';

class InvestmentRepositoryImpl implements InvestmentRepository {
  const InvestmentRepositoryImpl(this._remote);
  final InvestmentRemoteDataSource _remote;

  Failure _mapDio(DioException e) =>
      e.type == DioExceptionType.connectionError
          ? const NetworkFailure()
          : ServerFailure('Error ${e.response?.statusCode}');

  @override
  Future<Either<Failure, List<InvestmentEntity>>> getInvestments() async {
    try {
      return Right(await _remote.getInvestments());
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InvestmentEntity>> createInvestment({
    required String nombre,
    String? tipo,
    String? simbolo,
    double? cantidad,
    double? precioCompra,
    double? precioActual,
  }) async {
    try {
      final inv = await _remote.createInvestment({
        'nombre': nombre,
        if (tipo != null) 'tipo': tipo,
        if (simbolo != null) 'simbolo': simbolo,
        if (cantidad != null) 'cantidad': cantidad,
        if (precioCompra != null) 'precio_compra': precioCompra,
        if (precioActual != null) 'precio_actual': precioActual,
        'moneda': 'CLP',
      });
      return Right(inv);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InvestmentEntity>> updatePrice({
    required int id,
    required double precioActual,
  }) async {
    try {
      final inv = await _remote.updateInvestment(id, {
        'precio_actual': precioActual,
      });
      return Right(inv);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvestment(int id) async {
    try {
      await _remote.deleteInvestment(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
