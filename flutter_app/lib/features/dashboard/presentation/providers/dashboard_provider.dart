import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/dashboard/domain/entities/monthly_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final monthlySummaryProvider =
    FutureProvider<MonthlySummary>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  final now = DateTime.now();
  final resp = await dio.get(
    '/reportes/resumen-mensual',
    queryParameters: {'anio': now.year, 'mes': now.month},
  );
  return MonthlySummary.fromJson(resp.data as Map<String, dynamic>);
});
