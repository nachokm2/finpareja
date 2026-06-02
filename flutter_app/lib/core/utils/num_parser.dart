/// Parseo robusto de valores numéricos provenientes del backend.
///
/// Pydantic v2 serializa los campos `Decimal` (montos, porcentajes) como
/// STRING en JSON: "28500.00" en vez de 28500.0. Hacer `as num` sobre eso
/// lanza "type 'String' is not a subtype of type 'num'". Estas funciones
/// aceptan tanto número como string.
abstract class NumParser {
  /// Convierte a double; devuelve [fallback] si es null o no parseable.
  static double toDouble(Object? value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Convierte a double o null (para campos opcionales sin valor por defecto).
  static double? toDoubleOrNull(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
