import 'package:flutter_app/core/utils/num_parser.dart';
import 'package:flutter_app/features/categories/data/models/category_model.dart';
import 'package:flutter_app/features/transactions/domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.usuarioId,
    required super.tipo,
    required super.monto,
    required super.moneda,
    required super.fecha,
    required super.esCompartido,
    required super.porcentajeUsuario,
    required super.recurrente,
    required super.createdAt,
    super.descripcion,
    super.categoriaId,
    super.category,
    super.notas,
    super.frecuencia,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final catJson = json['category'] as Map<String, dynamic>?;
    return TransactionModel(
      id: json['id'] as int,
      usuarioId: json['usuario_id'] as int,
      tipo: json['tipo'] as String,
      monto: NumParser.toDouble(json['monto']),
      moneda: json['moneda'] as String? ?? 'CLP',
      descripcion: json['descripcion'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      categoriaId: json['categoria_id'] as int?,
      category: catJson != null ? CategoryModel.fromJson(catJson) : null,
      esCompartido: json['es_compartido'] as bool? ?? false,
      porcentajeUsuario: NumParser.toDouble(json['porcentaje_usuario'], fallback: 100),
      recurrente: json['recurrente'] as bool? ?? false,
      frecuencia: json['frecuencia'] as String?,
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'tipo': tipo,
        'monto': monto,
        'moneda': moneda,
        'fecha':
            '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
        if (descripcion != null) 'descripcion': descripcion,
        if (categoriaId != null) 'categoria_id': categoriaId,
        'es_compartido': esCompartido,
        'porcentaje_usuario': porcentajeUsuario,
        'recurrente': recurrente,
        if (notas != null) 'notas': notas,
      };
}
