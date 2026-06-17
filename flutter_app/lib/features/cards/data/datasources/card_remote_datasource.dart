import 'package:dio/dio.dart';
import 'package:flutter_app/core/utils/num_parser.dart';
import 'package:flutter_app/features/cards/domain/entities/card_entities.dart';

class CardRemoteDataSource {
  const CardRemoteDataSource(this._dio);
  final Dio _dio;

  String _fecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  CreditCardEntity _card(Map<String, dynamic> m) => CreditCardEntity(
        id: m['id'] as int,
        nombre: m['nombre'] as String? ?? 'Tarjeta',
        emisor: m['emisor'] as String?,
        ultimosDigitos: m['ultimos_digitos'] as String?,
        cupo: NumParser.toDoubleOrNull(m['cupo']),
        color: m['color'] as String?,
        saldoPendiente: NumParser.toDouble(m['saldo_pendiente']),
        totalCompras: NumParser.toDouble(m['total_compras']),
        totalPagado: NumParser.toDouble(m['total_pagado']),
        cupoDisponible: NumParser.toDoubleOrNull(m['cupo_disponible']),
      );

  CardPurchaseEntity _purchase(Map<String, dynamic> m) => CardPurchaseEntity(
        id: m['id'] as int,
        descripcion: m['descripcion'] as String?,
        monto: NumParser.toDouble(m['monto']),
        fecha: DateTime.parse(m['fecha'] as String),
        cuotas: m['cuotas'] as int? ?? 1,
        valorCuota: NumParser.toDoubleOrNull(m['valor_cuota']),
        interes: NumParser.toDoubleOrNull(m['interes']),
        deuda: NumParser.toDouble(m['deuda']),
        categoriaId: m['categoria_id'] as int?,
      );

  CardPaymentEntity _payment(Map<String, dynamic> m) => CardPaymentEntity(
        id: m['id'] as int,
        monto: NumParser.toDouble(m['monto']),
        fecha: DateTime.parse(m['fecha'] as String),
        nota: m['nota'] as String?,
      );

  Future<List<CreditCardEntity>> listCards() async {
    final resp = await _dio.get('/tarjetas');
    return (resp.data as List)
        .map((e) => _card(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCard({
    required String nombre,
    String? emisor,
    String? ultimosDigitos,
    double? cupo,
    String? color,
  }) async {
    await _dio.post('/tarjetas', data: {
      'nombre': nombre,
      if (emisor != null && emisor.isNotEmpty) 'emisor': emisor,
      if (ultimosDigitos != null && ultimosDigitos.isNotEmpty)
        'ultimos_digitos': ultimosDigitos,
      if (cupo != null) 'cupo': cupo,
      if (color != null) 'color': color,
    });
  }

  Future<void> deleteCard(int id) async => _dio.delete('/tarjetas/$id');

  Future<List<CardPurchaseEntity>> listPurchases(int cardId) async {
    final resp = await _dio.get('/tarjetas/$cardId/compras');
    return (resp.data as List)
        .map((e) => _purchase(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addPurchase({
    required int cardId,
    required double monto,
    required DateTime fecha,
    String? descripcion,
    int cuotas = 1,
    double? valorCuota,
    double? interes,
    int? categoriaId,
  }) async {
    await _dio.post('/tarjetas/$cardId/compras', data: {
      'monto': monto,
      'fecha': _fecha(fecha),
      'cuotas': cuotas,
      if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
      if (valorCuota != null) 'valor_cuota': valorCuota,
      if (interes != null) 'interes': interes,
      if (categoriaId != null) 'categoria_id': categoriaId,
    });
  }

  Future<void> deletePurchase(int cardId, int purchaseId) async =>
      _dio.delete('/tarjetas/$cardId/compras/$purchaseId');

  Future<List<CardPaymentEntity>> listPayments(int cardId) async {
    final resp = await _dio.get('/tarjetas/$cardId/pagos');
    return (resp.data as List)
        .map((e) => _payment(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addPayment({
    required int cardId,
    required double monto,
    required DateTime fecha,
    String? nota,
  }) async {
    await _dio.post('/tarjetas/$cardId/pagos', data: {
      'monto': monto,
      'fecha': _fecha(fecha),
      if (nota != null && nota.isNotEmpty) 'nota': nota,
    });
  }
}
