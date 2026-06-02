import 'package:flutter_app/core/utils/num_parser.dart';
import 'package:flutter_app/features/debts/domain/entities/debt_entity.dart';

class DebtModel extends DebtEntity {
  const DebtModel({
    required super.id,
    required super.usuarioId,
    required super.acreedor,
    required super.montoOriginal,
    required super.montoPendiente,
    required super.tasaInteres,
    required super.estado,
    required super.createdAt,
    super.descripcion,
    super.fechaInicio,
    super.fechaVencimiento,
    super.tipo,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) => DebtModel(
        id: json['id'] as int,
        usuarioId: json['usuario_id'] as int,
        acreedor: json['acreedor'] as String,
        montoOriginal: NumParser.toDouble(json['monto_original']),
        montoPendiente: NumParser.toDouble(json['monto_pendiente']),
        tasaInteres: NumParser.toDouble(json['tasa_interes']),
        estado: json['estado'] as String? ?? 'activa',
        createdAt: DateTime.parse(json['created_at'] as String),
        descripcion: json['descripcion'] as String?,
        tipo: json['tipo'] as String?,
        fechaInicio: json['fecha_inicio'] != null
            ? DateTime.parse(json['fecha_inicio'] as String)
            : null,
        fechaVencimiento: json['fecha_vencimiento'] != null
            ? DateTime.parse(json['fecha_vencimiento'] as String)
            : null,
      );
}
