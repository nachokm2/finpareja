import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4C4DDC);
  static const Color accent = Color(0xFFC8C8F4);
  static const Color background = Color(0xFFEDEDFC);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF101010);
  static const Color textGrey = Color(0xFFD4D4D8);
  static const Color cardShadow = Color(0x1A4C4DDC);

  // ── Colores semánticos financieros ────────────────────────────────────────
  // Centralizados aquí para no repetir hex literales por las pantallas.
  static const Color success = Color(0xFF10B981); // ingresos / positivo
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444); // gastos / negativo
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B); // cerca del límite

  /// Color para un tipo de transacción ('ingreso' | 'gasto').
  static Color forTipo(String tipo) => tipo == 'ingreso' ? income : expense;

  /// Semáforo según porcentaje usado de un presupuesto.
  static Color forBudgetUsage({
    required double porcentaje,
    required bool excedido,
  }) {
    if (excedido) return danger;
    if (porcentaje >= 80) return warning;
    return success;
  }
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textDark,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 2,
          shadowColor: AppColors.cardShadow,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.accent,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(
            color: AppColors.textDark, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
