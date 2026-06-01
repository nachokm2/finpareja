class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.esSistema,
    this.icono,
    this.color,
    this.usuarioId,
    this.parejaId,
  });

  final int id;
  final String nombre;
  final String tipo; // 'ingreso' | 'gasto'
  final bool esSistema;
  final String? icono;
  final String? color;
  final int? usuarioId;
  final int? parejaId;
}
