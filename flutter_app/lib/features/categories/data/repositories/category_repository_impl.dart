import 'package:dio/dio.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:flutter_app/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._remote);
  final CategoryRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      final categories = await _remote.getCategories();
      return Right(categories);
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Error de red'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
