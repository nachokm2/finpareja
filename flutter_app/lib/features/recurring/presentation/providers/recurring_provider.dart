import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/recurring/data/datasources/recurring_remote_datasource.dart';
import 'package:flutter_app/features/recurring/domain/entities/recurring_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringDsProvider = FutureProvider<RecurringRemoteDataSource>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return RecurringRemoteDataSource(dio);
});

final recurringProvider =
    AsyncNotifierProvider<RecurringNotifier, List<RecurringEntity>>(
  RecurringNotifier.new,
);

class RecurringNotifier extends AsyncNotifier<List<RecurringEntity>> {
  @override
  Future<List<RecurringEntity>> build() async {
    final ds = await ref.read(recurringDsProvider.future);
    return ds.list();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final ds = await ref.read(recurringDsProvider.future);
      return ds.list();
    });
  }

  Future<bool> create({
    required String tipo,
    required double monto,
    required String frecuencia,
    required DateTime proximaFecha,
    String? descripcion,
    int? categoriaId,
  }) async {
    try {
      final ds = await ref.read(recurringDsProvider.future);
      await ds.create(
        tipo: tipo,
        monto: monto,
        frecuencia: frecuencia,
        proximaFecha: proximaFecha,
        descripcion: descripcion,
        categoriaId: categoriaId,
      );
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleActive(RecurringEntity rec) async {
    final ds = await ref.read(recurringDsProvider.future);
    await ds.setActive(rec.id, !rec.activo);
    await refresh();
  }

  Future<void> delete(int id) async {
    final ds = await ref.read(recurringDsProvider.future);
    await ds.delete(id);
    await refresh();
  }
}
