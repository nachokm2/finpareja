import 'package:flutter_app/features/categories/domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.nombre,
    required super.tipo,
    required super.esSistema,
    super.icono,
    super.color,
    super.usuarioId,
    super.parejaId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        tipo: json['tipo'] as String,
        esSistema: json['es_sistema'] as bool? ?? false,
        icono: json['icono'] as String?,
        color: json['color'] as String?,
        usuarioId: json['usuario_id'] as int?,
        parejaId: json['pareja_id'] as int?,
      );
}
