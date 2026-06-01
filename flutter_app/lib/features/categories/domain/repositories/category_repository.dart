import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/categories/domain/entities/category_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
}
