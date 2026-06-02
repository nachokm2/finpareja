import 'package:flutter_app/core/utils/num_parser.dart';
import 'package:flutter_app/features/savings/domain/entities/saving_goal_entity.dart';

class SavingGoalModel extends SavingGoalEntity {
  const SavingGoalModel({
    required super.id, required super.usuarioId, required super.nombre,
    required super.montoObjetivo, required super.montoActual, required super.moneda,
    required super.estado, required super.progresoPorcentaje, required super.createdAt,
    super.descripcion, super.icono, super.color, super.fechaObjetivo, super.parejaId,
  });

  factory SavingGoalModel.fromJson(Map<String, dynamic> json) => SavingGoalModel(
        id: json['id'] as int,
        usuarioId: json['usuario_id'] as int,
        nombre: json['nombre'] as String,
        montoObjetivo: NumParser.toDouble(json['monto_objetivo']),
        montoActual: NumParser.toDouble(json['monto_actual']),
        moneda: json['moneda'] as String? ?? 'CLP',
        estado: json['estado'] as String? ?? 'activa',
        progresoPorcentaje: NumParser.toDouble(json['progreso_porcentaje']),
        createdAt: DateTime.parse(json['created_at'] as String),
        descripcion: json['descripcion'] as String?,
        icono: json['icono'] as String?,
        color: json['color'] as String?,
        parejaId: json['pareja_id'] as int?,
        fechaObjetivo: json['fecha_objetivo'] != null
            ? DateTime.parse(json['fecha_objetivo'] as String)
            : null,
      );
}
