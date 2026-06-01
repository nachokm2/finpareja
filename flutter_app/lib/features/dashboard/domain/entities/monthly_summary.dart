class MonthlySummary {
  const MonthlySummary({
    required this.anio,
    required this.mes,
    required this.ingresos,
    required this.gastos,
    required this.balance,
    required this.tasaAhorro,
  });

  final int anio;
  final int mes;
  final double ingresos;
  final double gastos;
  final double balance;
  final double tasaAhorro;

  factory MonthlySummary.fromJson(Map<String, dynamic> json) =>
      MonthlySummary(
        anio: json['anio'] as int,
        mes: json['mes'] as int,
        ingresos: (json['ingresos'] as num).toDouble(),
        gastos: (json['gastos'] as num).toDouble(),
        balance: (json['balance'] as num).toDouble(),
        tasaAhorro: (json['tasa_ahorro'] as num?)?.toDouble() ?? 0,
      );

  /// 0–100 basado en tasa de ahorro y balance
  int get healthScore {
    if (balance < 0) return 15;
    if (tasaAhorro >= 30) return 95;
    if (tasaAhorro >= 20) return 80;
    if (tasaAhorro >= 10) return 65;
    if (tasaAhorro > 0) return 45;
    return 30;
  }

  String get healthLabel {
    final s = healthScore;
    if (s >= 80) return 'Excelente';
    if (s >= 60) return 'Buena';
    if (s >= 40) return 'Regular';
    return 'Atención';
  }
}
