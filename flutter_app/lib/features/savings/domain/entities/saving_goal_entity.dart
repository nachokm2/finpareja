class SavingGoalEntity {
  const SavingGoalEntity({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.montoObjetivo,
    required this.montoActual,
    required this.moneda,
    required this.estado,
    required this.progresoPorcentaje,
    required this.createdAt,
    this.descripcion,
    this.icono,
    this.color,
    this.fechaObjetivo,
    this.parejaId,
  });

  final int id;
  final int usuarioId;
  final int? parejaId;
  final String nombre;
  final String? descripcion;
  final double montoObjetivo;
  final double montoActual;
  final String moneda;
  final String? icono;
  final String? color;
  final DateTime? fechaObjetivo;
  final String estado;
  final double progresoPorcentaje;
  final DateTime createdAt;

  double get montoFaltante => (montoObjetivo - montoActual).clamp(0, double.infinity);
  bool get estaCompletada => estado == 'completada';
}
