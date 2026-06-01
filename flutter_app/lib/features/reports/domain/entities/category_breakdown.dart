/// Una porción del gasto/ingreso del mes agrupada por categoría.
class CategorySlice {
  const CategorySlice({
    required this.id,
    required this.nombre,
    required this.total,
    required this.porcentaje,
    this.icono,
    this.color,
  });

  final int id;
  final String nombre;
  final double total;
  final double porcentaje;
  final String? icono;
  final String? color;
}

/// Desglose completo por categoría para un mes y tipo dados.
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.anio,
    required this.mes,
    required this.tipo,
    required this.slices,
  });

  final int anio;
  final int mes;
  final String tipo; // 'gasto' | 'ingreso'
  final List<CategorySlice> slices;

  double get total => slices.fold(0, (sum, s) => sum + s.total);
  bool get isEmpty => slices.isEmpty;
}
