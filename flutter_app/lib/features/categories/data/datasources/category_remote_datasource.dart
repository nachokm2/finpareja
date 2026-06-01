import 'package:dio/dio.dart';
import 'package:flutter_app/features/categories/data/models/category_model.dart';

class CategoryRemoteDataSource {
  const CategoryRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<CategoryModel>> getCategories() async {
    final resp = await _dio.get('/categorias');
    final list = resp.data as List<dynamic>;
    return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
