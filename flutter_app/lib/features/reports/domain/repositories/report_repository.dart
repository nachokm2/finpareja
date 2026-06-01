import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/reports/domain/entities/category_breakdown.dart';
import 'package:flutter_app/features/reports/domain/entities/evolution_point.dart';
import 'package:flutter_app/features/reports/domain/entities/net_worth.dart';
import 'package:fpdart/fpdart.dart';

abstract class ReportRepository {
  Future<Either<Failure, CategoryBreakdown>> getCategoryBreakdown({
    required int anio,
    required int mes,
    String tipo = 'gasto',
  });

  Future<Either<Failure, List<EvolutionPoint>>> getEvolution({int meses = 6});

  Future<Either<Failure, NetWorth>> getNetWorth();
}
