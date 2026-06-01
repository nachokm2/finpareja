/// Ingresos y gastos agregados de un mes concreto en la serie temporal.
class EvolutionPoint {
  const EvolutionPoint({
    required this.anio,
    required this.mes,
    required this.ingresos,
    required this.gastos,
  });

  final int anio;
  final int mes;
  final double ingresos;
  final double gastos;

  double get balance => ingresos - gastos;
}
