import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);
  final CategoryRepository _repository;
  Future<Either<Failure, List<CategoryEntity>>> call() => _repository.getCategories();
}
