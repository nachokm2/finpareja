import 'package:flutter_app/features/categories/domain/entities/category_entity.dart';

class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.monto,
    required this.moneda,
    required this.fecha,
    required this.esCompartido,
    required this.porcentajeUsuario,
    required this.recurrente,
    required this.createdAt,
    this.descripcion,
    this.categoriaId,
    this.category,
    this.notas,
    this.frecuencia,
  });

  final int id;
  final int usuarioId;
  final String tipo; // 'ingreso' | 'gasto'
  final double monto;
  final String moneda;
  final String? descripcion;
  final DateTime fecha;
  final int? categoriaId;
  final CategoryEntity? category;
  final bool esCompartido;
  final double porcentajeUsuario;
  final bool recurrente;
  final String? frecuencia;
  final String? notas;
  final DateTime createdAt;

  bool get esGasto => tipo == 'gasto';
  bool get esIngreso => tipo == 'ingreso';
}
