import 'package:dio/dio.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:flutter_app/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fpdart/fpdart.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._remote);
  final TransactionRemoteDataSource _remote;

  Failure _mapDio(DioException e) =>
      e.type == DioExceptionType.connectionError
          ? const NetworkFailure('Error de conexion')
          : ServerFailure('Error ${e.response?.statusCode}');

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    int page = 1,
    int pageSize = 30,
    String? tipo,
    int? mes,
    int? anio,
  }) async {
    try {
      final list = await _remote.getTransactions(
        page: page,
        pageSize: pageSize,
        tipo: tipo,
        mes: mes,
        anio: anio,
      );
      return Right(list);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> createTransaction({
    required String tipo,
    required double monto,
    required DateTime fecha,
    String? descripcion,
    int? categoriaId,
    bool esCompartido = false,
    String moneda = 'CLP',
    String? notas,
  }) async {
    try {
      final model = TransactionModel(
        id: 0,
        usuarioId: 0,
        tipo: tipo,
        monto: monto,
        moneda: moneda,
        fecha: fecha,
        esCompartido: esCompartido,
        porcentajeUsuario: 100,
        recurrente: false,
        createdAt: DateTime.now(),
        descripcion: descripcion,
        categoriaId: categoriaId,
        notas: notas,
      );
      final result = await _remote.createTransaction(model.toCreateJson());
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> updateTransaction({
    required int id,
    String? tipo,
    double? monto,
    DateTime? fecha,
    String? descripcion,
    int? categoriaId,
  }) async {
    try {
      final body = <String, dynamic>{
        if (tipo != null) 'tipo': tipo,
        if (monto != null) 'monto': monto,
        if (fecha != null)
          'fecha':
              '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
        if (descripcion != null) 'descripcion': descripcion,
        if (categoriaId != null) 'categoria_id': categoriaId,
      };
      final result = await _remote.updateTransaction(id, body);
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(int id) async {
    try {
      await _remote.deleteTransaction(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
