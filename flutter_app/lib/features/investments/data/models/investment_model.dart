import 'package:flutter_app/core/utils/num_parser.dart';
import 'package:flutter_app/features/investments/domain/entities/investment_entity.dart';

class InvestmentModel extends InvestmentEntity {
  const InvestmentModel({
    required super.id,
    required super.usuarioId,
    required super.nombre,
    required super.moneda,
    required super.createdAt,
    super.tipo,
    super.simbolo,
    super.cantidad,
    super.precioCompra,
    super.precioActual,
    super.fechaCompra,
    super.notas,
    super.valorActual,
    super.gananciaPerdida,
  });

  factory InvestmentModel.fromJson(Map<String, dynamic> json) =>
      InvestmentModel(
        id: json['id'] as int,
        usuarioId: json['usuario_id'] as int,
        nombre: json['nombre'] as String,
        moneda: json['moneda'] as String? ?? 'CLP',
        createdAt: DateTime.parse(json['created_at'] as String),
        tipo: json['tipo'] as String?,
        simbolo: json['simbolo'] as String?,
        cantidad: NumParser.toDoubleOrNull(json['cantidad']),
        precioCompra: NumParser.toDoubleOrNull(json['precio_compra']),
        precioActual: NumParser.toDoubleOrNull(json['precio_actual']),
        valorActual: NumParser.toDoubleOrNull(json['valor_actual']),
        gananciaPerdida: NumParser.toDoubleOrNull(json['ganancia_perdida']),
        notas: json['notas'] as String?,
        fechaCompra: json['fecha_compra'] != null
            ? DateTime.parse(json['fecha_compra'] as String)
            : null,
      );
}
