import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/debts/domain/entities/debt_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class DebtRepository {
  Future<Either<Failure, List<DebtEntity>>> getDebts();

  Future<Either<Failure, DebtEntity>> createDebt({
    required String acreedor,
    required double montoOriginal,
    String? descripcion,
    double tasaInteres = 0,
    String? tipo,
    DateTime? fechaVencimiento,
  });

  Future<Either<Failure, DebtEntity>> addPayment({
    required int debtId,
    required double monto,
    required DateTime fecha,
    String? nota,
  });

  Future<Either<Failure, void>> deleteDebt(int id);
}
