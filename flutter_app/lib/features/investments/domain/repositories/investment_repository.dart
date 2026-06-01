import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/investments/domain/entities/investment_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class InvestmentRepository {
  Future<Either<Failure, List<InvestmentEntity>>> getInvestments();

  Future<Either<Failure, InvestmentEntity>> createInvestment({
    required String nombre,
    String? tipo,
    String? simbolo,
    double? cantidad,
    double? precioCompra,
    double? precioActual,
  });

  Future<Either<Failure, InvestmentEntity>> updatePrice({
    required int id,
    required double precioActual,
  });

  Future<Either<Failure, void>> deleteInvestment(int id);
}
