import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:flutter_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:flutter_app/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_app/features/categories/domain/usecases/get_categories_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _categoryRepoProvider = FutureProvider((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return CategoryRepositoryImpl(CategoryRemoteDataSource(dio));
});

final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repo = await ref.watch(_categoryRepoProvider.future);
  final result = await GetCategoriesUseCase(repo).call();
  return result.fold((f) => throw Exception(f.message), (cats) => cats);
});

/// Categorias filtradas por tipo
final gastoCategoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final all = await ref.watch(categoriesProvider.future);
  return all.where((c) => c.tipo == 'gasto').toList();
});

final ingresoCategoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final all = await ref.watch(categoriesProvider.future);
  return all.where((c) => c.tipo == 'ingreso').toList();
});
