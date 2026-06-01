import 'package:dio/dio.dart';
import 'package:flutter_app/features/debts/data/models/debt_model.dart';

class DebtRemoteDataSource {
  const DebtRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<DebtModel>> getDebts() async {
    final resp = await _dio.get('/deudas');
    return (resp.data as List)
        .map((e) => DebtModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DebtModel> createDebt(Map<String, dynamic> body) async {
    final resp = await _dio.post('/deudas', data: body);
    return DebtModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<DebtModel> addPayment(int debtId, Map<String, dynamic> body) async {
    final resp = await _dio.post('/deudas/$debtId/pagos', data: body);
    return DebtModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteDebt(int id) => _dio.delete('/deudas/$id');
}
