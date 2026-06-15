import 'package:dio/dio.dart';
import 'package:flutter_app/features/savings/data/models/saving_goal_model.dart';

class SavingGoalRemoteDataSource {
  const SavingGoalRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<SavingGoalModel>> getGoals() async {
    final resp = await _dio.get('/metas');
    return (resp.data as List).map((e) => SavingGoalModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SavingGoalModel> createGoal(Map<String, dynamic> body) async {
    final resp = await _dio.post('/metas', data: body);
    return SavingGoalModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<SavingGoalModel> addContribution(int goalId, Map<String, dynamic> body) async {
    final resp = await _dio.post('/metas/$goalId/aportes', data: body);
    return SavingGoalModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<SavingGoalModel> updateGoal(int id, Map<String, dynamic> body) async {
    final resp = await _dio.patch('/metas/$id', data: body);
    return SavingGoalModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteGoal(int id) async => _dio.delete('/metas/$id');
}
