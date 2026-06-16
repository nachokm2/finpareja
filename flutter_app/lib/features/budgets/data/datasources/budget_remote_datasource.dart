import 'package:dio/dio.dart';
import 'package:flutter_app/features/budgets/data/models/budget_model.dart';

class BudgetRemoteDataSource {
  const BudgetRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<BudgetModel>> getBudgets({int? mes, int? anio}) async {
    final resp = await _dio.get(
      '/presupuestos',
      queryParameters: {if (mes != null) 'mes': mes, if (anio != null) 'anio': anio},
    );
    return (resp.data as List).map((e) => BudgetModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BudgetModel> createBudget(Map<String, dynamic> body) async {
    final resp = await _dio.post('/presupuestos', data: body);
    return BudgetModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<BudgetModel> updateBudget(int id, Map<String, dynamic> body) async {
    final resp = await _dio.patch('/presupuestos/$id', data: body);
    return BudgetModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteBudget(int id) async => _dio.delete('/presupuestos/$id');
}
