import 'package:dio/dio.dart';
import 'package:flutter_app/features/transactions/data/models/transaction_model.dart';

class TransactionRemoteDataSource {
  const TransactionRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<TransactionModel>> getTransactions({
    int page = 1,
    int pageSize = 30,
    String? tipo,
    int? mes,
    int? anio,
  }) async {
    final resp = await _dio.get(
      '/transacciones',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (tipo != null) 'tipo': tipo,
        if (mes != null) 'mes': mes,
        if (anio != null) 'anio': anio,
      },
    );
    final data = resp.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> body) async {
    final resp = await _dio.post('/transacciones', data: body);
    return TransactionModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<TransactionModel> updateTransaction(
      int id, Map<String, dynamic> body) async {
    final resp = await _dio.patch('/transacciones/$id', data: body);
    return TransactionModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteTransaction(int id) async {
    await _dio.delete('/transacciones/$id');
  }

  /// Descarga el CSV de todas las transacciones del usuario.
  Future<String> exportCsv() async {
    final resp = await _dio.get<String>(
      '/transacciones/export',
      options: Options(responseType: ResponseType.plain),
    );
    return resp.data ?? '';
  }
}
