/// Patrimonio neto acumulado del usuario (todos los movimientos históricos).
class NetWorth {
  const NetWorth({
    required this.ingresosAcumulados,
    required this.gastosAcumulados,
    required this.patrimonioNeto,
  });

  final double ingresosAcumulados;
  final double gastosAcumulados;
  final double patrimonioNeto;
}
