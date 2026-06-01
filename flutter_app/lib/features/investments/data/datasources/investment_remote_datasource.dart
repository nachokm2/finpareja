import 'package:dio/dio.dart';
import 'package:flutter_app/features/investments/data/models/investment_model.dart';

class InvestmentRemoteDataSource {
  const InvestmentRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<InvestmentModel>> getInvestments() async {
    final resp = await _dio.get('/inversiones');
    return (resp.data as List)
        .map((e) => InvestmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InvestmentModel> createInvestment(Map<String, dynamic> body) async {
    final resp = await _dio.post('/inversiones', data: body);
    return InvestmentModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<InvestmentModel> updateInvestment(
      int id, Map<String, dynamic> body) async {
    final resp = await _dio.patch('/inversiones/$id', data: body);
    return InvestmentModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteInvestment(int id) => _dio.delete('/inversiones/$id');
}
