/// Aporte de un miembro al patrimonio combinado de la pareja.
class CoupleMemberSummary {
  const CoupleMemberSummary({
    required this.usuarioId,
    required this.nombre,
    required this.rol,
    required this.ingresos,
    required this.gastos,
    required this.patrimonio,
    required this.porcentaje,
  });

  final int usuarioId;
  final String nombre;
  final String rol;
  final double ingresos;
  final double gastos;
  final double patrimonio;
  final double porcentaje;
}

/// Resumen consolidado del patrimonio de la pareja.
class CoupleSummary {
  const CoupleSummary({
    required this.parejaId,
    required this.patrimonioCombinado,
    required this.miembros,
  });

  final int parejaId;
  final double patrimonioCombinado;
  final List<CoupleMemberSummary> miembros;
}
