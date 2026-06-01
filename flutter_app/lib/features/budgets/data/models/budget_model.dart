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
        montoLimite: (json['monto_limite'] as num).toDouble(),
        periodo: json['periodo'] as String? ?? 'mensual',
        alertaPorcentaje: (json['alerta_porcentaje'] as num?)?.toDouble() ?? 80.0,
        categoriaId: json['categoria_id'] as int?,
        mes: json['mes'] as int?,
        anio: json['anio'] as int?,
        montoGastado: (json['monto_gastado'] as num?)?.toDouble() ?? 0.0,
        porcentajeUsado: (json['porcentaje_usado'] as num?)?.toDouble() ?? 0.0,
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
