import 'package:intl/intl.dart';

/// Utilidad de formateo de fechas en español (Chile).
abstract class DateFormatter {
  static final _short = DateFormat('d MMM', 'es_CL');
  static final _medium = DateFormat('d \'de\' MMMM yyyy', 'es_CL');
  static final _monthYear = DateFormat('MMMM yyyy', 'es_CL');

  /// Formato corto: "3 ene" / "15 dic"
  static String short(DateTime date) => _short.format(date);

  /// Formato legible: "3 de enero 2026"
  static String medium(DateTime date) => _medium.format(date);

  /// Solo mes y año: "enero 2026"
  static String monthYear(DateTime date) => _monthYear.format(date);

  /// "Hoy", "Ayer" o formato corto
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return short(date);
  }

  /// Nombre del mes en español: "enero"
  static String monthName(int month) {
    return DateFormat('MMMM', 'es_CL').format(DateTime(2000, month));
  }
}
