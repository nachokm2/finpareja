class BudgetEntity {
  const BudgetEntity({
    required this.id,
    required this.usuarioId,
    required this.montoLimite,
    required this.periodo,
    required this.alertaPorcentaje,
    this.categoriaId,
    this.mes,
    this.anio,
    this.montoGastado = 0,
    this.porcentajeUsado = 0,
    this.alertaActiva = false,
  });

  final int id;
  final int usuarioId;
  final int? categoriaId;
  final double montoLimite;
  final String periodo;
  final int? mes;
  final int? anio;
  final double alertaPorcentaje;
  final double montoGastado;
  final double porcentajeUsado;
  final bool alertaActiva;

  double get montoDisponible => montoLimite - montoGastado;
  bool get excedido => montoGastado > montoLimite;
}
