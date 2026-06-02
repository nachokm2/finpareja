import 'package:dio/dio.dart';
import 'package:flutter_app/core/utils/num_parser.dart';
import 'package:flutter_app/features/reports/domain/entities/category_breakdown.dart';
import 'package:flutter_app/features/reports/domain/entities/evolution_point.dart';
import 'package:flutter_app/features/reports/domain/entities/net_worth.dart';

class ReportRemoteDataSource {
  const ReportRemoteDataSource(this._dio);
  final Dio _dio;

  Future<CategoryBreakdown> getCategoryBreakdown({
    required int anio,
    required int mes,
    String tipo = 'gasto',
  }) async {
    final resp = await _dio.get(
      '/reportes/por-categoria',
      queryParameters: {'anio': anio, 'mes': mes, 'tipo': tipo},
    );
    final data = resp.data as Map<String, dynamic>;
    final slices = (data['categorias'] as List)
        .map((e) {
          final m = e as Map<String, dynamic>;
          return CategorySlice(
            id: m['id'] as int,
            nombre: m['nombre'] as String,
            total: NumParser.toDouble(m['total']),
            porcentaje: NumParser.toDouble(m['porcentaje']),
            icono: m['icono'] as String?,
            color: m['color'] as String?,
          );
        })
        .toList();
    return CategoryBreakdown(
      anio: data['anio'] as int,
      mes: data['mes'] as int,
      tipo: data['tipo'] as String,
      slices: slices,
    );
  }

  Future<List<EvolutionPoint>> getEvolution({int meses = 6}) async {
    final resp = await _dio.get(
      '/reportes/evolucion',
      queryParameters: {'meses': meses},
    );
    final data = resp.data as Map<String, dynamic>;
    return (data['meses'] as List).map((e) {
      final m = e as Map<String, dynamic>;
      return EvolutionPoint(
        anio: m['anio'] as int,
        mes: m['mes'] as int,
        ingresos: NumParser.toDouble(m['ingresos']),
        gastos: NumParser.toDouble(m['gastos']),
      );
    }).toList();
  }

  Future<NetWorth> getNetWorth() async {
    final resp = await _dio.get('/reportes/patrimonio');
    final data = resp.data as Map<String, dynamic>;
    return NetWorth(
      ingresosAcumulados: NumParser.toDouble(data['ingresos_acumulados']),
      gastosAcumulados: NumParser.toDouble(data['gastos_acumulados']),
      patrimonioNeto: NumParser.toDouble(data['patrimonio_neto']),
    );
  }
}
