import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:flutter_app/features/reports/data/repositories/report_repository_impl.dart';
import 'package:flutter_app/features/reports/domain/entities/category_breakdown.dart';
import 'package:flutter_app/features/reports/domain/entities/evolution_point.dart';
import 'package:flutter_app/features/reports/domain/entities/net_worth.dart';
import 'package:flutter_app/features/reports/domain/repositories/report_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _reportRepoProvider = FutureProvider<ReportRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return ReportRepositoryImpl(ReportRemoteDataSource(dio));
});

/// Desglose de gastos por categoría del mes actual (para el donut chart).
final categoryBreakdownProvider =
    FutureProvider<CategoryBreakdown>((ref) async {
  final repo = await ref.watch(_reportRepoProvider.future);
  final now = DateTime.now();
  final result = await repo.getCategoryBreakdown(
    anio: now.year,
    mes: now.month,
    tipo: 'gasto',
  );
  return result.fold((f) => throw Exception(f.message), (b) => b);
});

/// Evolución ingresos vs gastos de los últimos 6 meses (para el bar chart).
final evolutionProvider =
    FutureProvider<List<EvolutionPoint>>((ref) async {
  final repo = await ref.watch(_reportRepoProvider.future);
  final result = await repo.getEvolution(meses: 6);
  return result.fold((f) => throw Exception(f.message), (list) => list);
});

/// Patrimonio neto acumulado.
final netWorthProvider = FutureProvider<NetWorth>((ref) async {
  final repo = await ref.watch(_reportRepoProvider.future);
  final result = await repo.getNetWorth();
  return result.fold((f) => throw Exception(f.message), (nw) => nw);
});
