import 'package:dio/dio.dart';
import 'package:flutter_app/core/utils/num_parser.dart';
import 'package:flutter_app/features/couple/domain/entities/couple_balance.dart';
import 'package:flutter_app/features/couple/domain/entities/couple_info.dart';
import 'package:flutter_app/features/couple/domain/entities/couple_summary.dart';

class CoupleRemoteDataSource {
  const CoupleRemoteDataSource(this._dio);
  final Dio _dio;

  /// Devuelve null si el usuario no pertenece a ninguna pareja (404).
  Future<CoupleInfo?> getMyCouple() async {
    try {
      final resp = await _dio.get('/parejas/me');
      final m = resp.data as Map<String, dynamic>;
      return CoupleInfo(
        id: m['id'] as int,
        nombre: m['nombre'] as String?,
        currency: m['currency'] as String? ?? 'CLP',
        memberCount: m['member_count'] as int? ?? 1,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<CoupleSummary> getSummary() async {
    final resp = await _dio.get('/parejas/resumen');
    final m = resp.data as Map<String, dynamic>;
    final miembros = (m['miembros'] as List).map((e) {
      final mm = e as Map<String, dynamic>;
      return CoupleMemberSummary(
        usuarioId: mm['usuario_id'] as int,
        nombre: mm['nombre'] as String? ?? 'Usuario',
        avatar: mm['avatar'] as String?,
        rol: mm['rol'] as String? ?? 'member',
        ingresos: NumParser.toDouble(mm['ingresos']),
        gastos: NumParser.toDouble(mm['gastos']),
        patrimonio: NumParser.toDouble(mm['patrimonio']),
        porcentaje: NumParser.toDouble(mm['porcentaje']),
      );
    }).toList();
    return CoupleSummary(
      parejaId: m['pareja_id'] as int,
      patrimonioCombinado: NumParser.toDouble(m['patrimonio_combinado']),
      miembros: miembros,
    );
  }

  Future<void> createCouple(String? nombre) async {
    await _dio.post('/parejas', data: {if (nombre != null) 'nombre': nombre});
  }

  Future<String> invite(String email) async {
    final resp = await _dio.post('/parejas/invite', data: {'email': email});
    return (resp.data as Map<String, dynamic>)['token'] as String;
  }

  Future<void> accept(String token) async {
    await _dio.post('/parejas/accept', data: {'token': token});
  }

  Future<CoupleBalance> getBalance() async {
    final resp = await _dio.get('/parejas/balance');
    final m = resp.data as Map<String, dynamic>;
    return CoupleBalance(
      balance: NumParser.toDouble(m['balance']),
      teDeben: NumParser.toDouble(m['te_deben']),
      debes: NumParser.toDouble(m['debes']),
      tieneParejaCompleta: m['tiene_pareja_completa'] as bool? ?? false,
    );
  }

  /// Registra un pago del usuario actual a su pareja para saldar deuda.
  Future<void> settle(double monto) async {
    final now = DateTime.now();
    await _dio.post('/parejas/liquidar', data: {
      'monto': monto,
      'fecha':
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    });
  }
}
