import 'package:flutter_app/core/utils/num_parser.dart';
import 'package:flutter_app/features/budgets/domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id, required super.usuarioId, required super.montoLimite,
    required super.periodo, required super.alertaPorcentaje,
    super.categoriaId, super.mes, super.anio,
    super.montoGastado, super.porcentajeUsado, super.alertaActiva,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as int,
        usuarioId: json['usuario_id'] as int,
        montoLimite: NumParser.toDouble(json['monto_limite']),
        periodo: json['periodo'] as String? ?? 'mensual',
        alertaPorcentaje: NumParser.toDouble(json['alerta_porcentaje'], fallback: 80),
        categoriaId: json['categoria_id'] as int?,
        mes: json['mes'] as int?,
        anio: json['anio'] as int?,
        montoGastado: NumParser.toDouble(json['monto_gastado']),
        porcentajeUsado: NumParser.toDouble(json['porcentaje_usado']),
        alertaActiva: json['alerta_activa'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'monto_limite': montoLimite,
        if (categoriaId != null) 'categoria_id': categoriaId,
        if (mes != null) 'mes': mes,
        if (anio != null) 'anio': anio,
        'alerta_porcentaje': alertaPorcentaje,
      };
}
