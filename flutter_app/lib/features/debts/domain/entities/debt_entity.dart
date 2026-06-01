class DebtEntity {
  const DebtEntity({
    required this.id,
    required this.usuarioId,
    required this.acreedor,
    required this.montoOriginal,
    required this.montoPendiente,
    required this.tasaInteres,
    required this.estado,
    required this.createdAt,
    this.descripcion,
    this.fechaInicio,
    this.fechaVencimiento,
    this.tipo,
  });

  final int id;
  final int usuarioId;
  final String acreedor;
  final String? descripcion;
  final double montoOriginal;
  final double montoPendiente;
  final double tasaInteres;
  final DateTime? fechaInicio;
  final DateTime? fechaVencimiento;
  final String? tipo; // 'credito'|'hipoteca'|'personal'|'tarjeta'
  final String estado; // 'activa' | 'pagada'
  final DateTime createdAt;

  double get montoPagado =>
      (montoOriginal - montoPendiente).clamp(0, montoOriginal);

  /// Progreso de pago 0.0–1.0
  double get progreso =>
      montoOriginal == 0 ? 0 : (montoPagado / montoOriginal).clamp(0.0, 1.0);

  bool get estaPagada => estado == 'pagada' || montoPendiente <= 0;
}
