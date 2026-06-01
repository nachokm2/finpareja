import 'package:dio/dio.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/debts/data/datasources/debt_remote_datasource.dart';
import 'package:flutter_app/features/debts/domain/entities/debt_entity.dart';
import 'package:flutter_app/features/debts/domain/repositories/debt_repository.dart';
import 'package:fpdart/fpdart.dart';

class DebtRepositoryImpl implements DebtRepository {
  const DebtRepositoryImpl(this._remote);
  final DebtRemoteDataSource _remote;

  Failure _mapDio(DioException e) =>
      e.type == DioExceptionType.connectionError
          ? const NetworkFailure()
          : ServerFailure('Error ${e.response?.statusCode}');

  String _fecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<Either<Failure, List<DebtEntity>>> getDebts() async {
    try {
      return Right(await _remote.getDebts());
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DebtEntity>> createDebt({
    required String acreedor,
    required double montoOriginal,
    String? descripcion,
    double tasaInteres = 0,
    String? tipo,
    DateTime? fechaVencimiento,
  }) async {
    try {
      final debt = await _remote.createDebt({
        'acreedor': acreedor,
        'monto_original': montoOriginal,
        'tasa_interes': tasaInteres,
        if (descripcion != null) 'descripcion': descripcion,
        if (tipo != null) 'tipo': tipo,
        if (fechaVencimiento != null)
          'fecha_vencimiento': _fecha(fechaVencimiento),
      });
      return Right(debt);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DebtEntity>> addPayment({
    required int debtId,
    required double monto,
    required DateTime fecha,
    String? nota,
  }) async {
    try {
      final debt = await _remote.addPayment(debtId, {
        'monto': monto,
        'fecha': _fecha(fecha),
        if (nota != null) 'nota': nota,
      });
      return Right(debt);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDebt(int id) async {
    try {
      await _remote.deleteDebt(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
