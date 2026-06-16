import 'package:dio/dio.dart';
import 'package:flutter_app/core/utils/num_parser.dart';
import 'package:flutter_app/features/recurring/domain/entities/recurring_entity.dart';

class RecurringRemoteDataSource {
  const RecurringRemoteDataSource(this._dio);
  final Dio _dio;

  RecurringEntity _fromJson(Map<String, dynamic> m) => RecurringEntity(
        id: m['id'] as int,
        tipo: m['tipo'] as String,
        monto: NumParser.toDouble(m['monto']),
        frecuencia: m['frecuencia'] as String? ?? 'mensual',
        proximaFecha: DateTime.parse(m['proxima_fecha'] as String),
        activo: m['activo'] as bool? ?? true,
        descripcion: m['descripcion'] as String?,
        categoriaId: m['categoria_id'] as int?,
      );

  Future<List<RecurringEntity>> list() async {
    final resp = await _dio.get('/recurrentes');
    return (resp.data as List)
        .map((e) => _fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String tipo,
    required double monto,
    required String frecuencia,
    required DateTime proximaFecha,
    String? descripcion,
    int? categoriaId,
  }) async {
    await _dio.post('/recurrentes', data: {
      'tipo': tipo,
      'monto': monto,
      'frecuencia': frecuencia,
      'proxima_fecha':
          '${proximaFecha.year}-${proximaFecha.month.toString().padLeft(2, '0')}-${proximaFecha.day.toString().padLeft(2, '0')}',
      if (descripcion != null) 'descripcion': descripcion,
      if (categoriaId != null) 'categoria_id': categoriaId,
    });
  }

  Future<void> setActive(int id, bool activo) async {
    await _dio.patch('/recurrentes/$id', data: {'activo': activo});
  }

  Future<void> delete(int id) async => _dio.delete('/recurrentes/$id');

  /// Materializa las recurrentes vencidas. Devuelve cuántas se crearon.
  Future<int> process() async {
    final resp = await _dio.post('/recurrentes/procesar');
    return (resp.data as Map<String, dynamic>)['creadas'] as int? ?? 0;
  }
}
