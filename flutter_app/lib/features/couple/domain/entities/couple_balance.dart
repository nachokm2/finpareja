/// Balance neto de gastos compartidos entre los dos miembros.
class CoupleBalance {
  const CoupleBalance({
    required this.balance,
    required this.teDeben,
    required this.debes,
    required this.tieneParejaCompleta,
  });

  /// > 0: la pareja te debe · < 0: tú le debes · 0: a mano.
  final double balance;
  final double teDeben;
  final double debes;
  final bool tieneParejaCompleta;

  bool get aMano => balance == 0;
  bool get teDebenAti => balance > 0;
}
