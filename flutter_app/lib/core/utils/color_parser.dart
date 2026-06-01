import 'package:flutter/material.dart';

/// Convierte un string hex (#RRGGBB o RRGGBB) a [Color].
/// Devuelve [fallback] si el formato es inválido o el valor es null.
abstract class ColorParser {
  static Color fromHex(String? hex, {Color fallback = const Color(0xFF4C4DDC)}) {
    if (hex == null || hex.isEmpty) return fallback;
    var value = hex.replaceFirst('#', '').trim();
    if (value.length == 6) value = 'FF$value'; // agrega alpha opaco
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}
