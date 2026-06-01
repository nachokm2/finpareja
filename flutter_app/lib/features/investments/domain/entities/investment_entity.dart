class InvestmentEntity {
  const InvestmentEntity({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.moneda,
    required this.createdAt,
    this.tipo,
    this.simbolo,
    this.cantidad,
    this.precioCompra,
    this.precioActual,
    this.fechaCompra,
    this.notas,
    this.valorActual,
    this.gananciaPerdida,
  });

  final int id;
  final int usuarioId;
  final String nombre;
  final String? tipo; // 'accion'|'fondo'|'deposito'|'criptomoneda'|'bienes_raices'
  final String? simbolo;
  final double? cantidad;
  final double? precioCompra;
  final double? precioActual;
  final String moneda;
  final DateTime? fechaCompra;
  final String? notas;
  final double? valorActual;
  final double? gananciaPerdida;
  final DateTime createdAt;

  bool get tieneGanancia => (gananciaPerdida ?? 0) >= 0;

  /// Rentabilidad % sobre el costo de compra.
  double? get rentabilidad {
    final costo = (precioCompra ?? 0) * (cantidad ?? 0);
    if (costo == 0 || gananciaPerdida == null) return null;
    return gananciaPerdida! / costo * 100;
  }
}
