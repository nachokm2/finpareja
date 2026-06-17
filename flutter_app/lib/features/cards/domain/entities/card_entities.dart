/// Tarjeta de crédito con su resumen de deuda (control financiero, sin pagos).
class CreditCardEntity {
  const CreditCardEntity({
    required this.id,
    required this.nombre,
    required this.saldoPendiente,
    required this.totalCompras,
    required this.totalPagado,
    this.emisor,
    this.ultimosDigitos,
    this.cupo,
    this.color,
    this.cupoDisponible,
  });

  final int id;
  final String nombre;
  final String? emisor;
  final String? ultimosDigitos;
  final double? cupo;
  final String? color;
  final double saldoPendiente;
  final double totalCompras;
  final double totalPagado;
  final double? cupoDisponible;

  double get usoCupo =>
      (cupo != null && cupo! > 0) ? (saldoPendiente / cupo!).clamp(0.0, 1.0) : 0.0;
}

/// Compra registrada en una tarjeta (contado o en cuotas).
class CardPurchaseEntity {
  const CardPurchaseEntity({
    required this.id,
    required this.monto,
    required this.fecha,
    required this.cuotas,
    required this.deuda,
    this.descripcion,
    this.categoriaId,
    this.valorCuota,
    this.interes,
  });

  final int id;
  final String? descripcion;
  final double monto;
  final DateTime fecha;
  final int cuotas;
  final double? valorCuota;
  final double? interes;
  final double deuda;
  final int? categoriaId;

  bool get esCuotas => cuotas > 1;
}

/// Pago realizado a la deuda de una tarjeta.
class CardPaymentEntity {
  const CardPaymentEntity({
    required this.id,
    required this.monto,
    required this.fecha,
    this.nota,
  });

  final int id;
  final double monto;
  final DateTime fecha;
  final String? nota;
}
