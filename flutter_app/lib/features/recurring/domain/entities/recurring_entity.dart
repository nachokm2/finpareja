/// Plantilla de transacción recurrente (mensual/semanal).
class RecurringEntity {
  const RecurringEntity({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.frecuencia,
    required this.proximaFecha,
    required this.activo,
    this.descripcion,
    this.categoriaId,
  });

  final int id;
  final String tipo; // 'ingreso' | 'gasto'
  final double monto;
  final String frecuencia; // 'mensual' | 'semanal'
  final DateTime proximaFecha;
  final bool activo;
  final String? descripcion;
  final int? categoriaId;

  bool get esGasto => tipo == 'gasto';
  String get frecuenciaLabel => frecuencia == 'semanal' ? 'Semanal' : 'Mensual';
}
