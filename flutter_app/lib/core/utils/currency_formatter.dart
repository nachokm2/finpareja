import 'package:intl/intl.dart';

/// Utilidad de formateo de moneda para el mercado chileno (CLP).
///
/// CLP no tiene decimales. El separador de miles es punto.
/// Ejemplo: 1.234.567
abstract class CurrencyFormatter {
  static final _clp = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final _clpCompact = NumberFormat.compactCurrency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );

  /// Formato completo: $1.234.567
  static String format(num amount) => _clp.format(amount);

  /// Formato compacto para espacios reducidos: $1,2M / $234K
  static String compact(num amount) {
    if (amount.abs() >= 1000000) return _clpCompact.format(amount);
    return format(amount);
  }

  /// Formato con signo para indicar ingreso/gasto:
  /// +$1.234.567 o -$567.000
  static String signed(num amount, {bool isIncome = true}) {
    final prefix = isIncome ? '+' : '-';
    return '$prefix${format(amount.abs())}';
  }
}
