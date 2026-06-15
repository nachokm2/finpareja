import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:flutter_app/features/couple/domain/entities/couple_balance.dart';
import 'package:flutter_app/features/couple/domain/entities/couple_info.dart';
import 'package:flutter_app/features/couple/domain/entities/couple_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _coupleDsProvider = FutureProvider<CoupleRemoteDataSource>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return CoupleRemoteDataSource(dio);
});

/// Estado combinado de la vista pareja:
/// - [info] null → el usuario no pertenece a ninguna pareja (mostrar onboarding).
/// - [info] + [summary] → mostrar dashboard de pareja.
class CoupleState {
  const CoupleState({this.info, this.summary, this.balance});
  final CoupleInfo? info;
  final CoupleSummary? summary;
  final CoupleBalance? balance;

  bool get hasCouple => info != null;
}

final coupleProvider =
    AsyncNotifierProvider<CoupleNotifier, CoupleState>(CoupleNotifier.new);

/// ID de la pareja del usuario actual, o null si no tiene.
/// Lo usa AddTransactionPage para ofrecer (o no) el gasto compartido.
final currentCoupleIdProvider = FutureProvider<int?>((ref) async {
  final ds = await ref.watch(_coupleDsProvider.future);
  final info = await ds.getMyCouple();
  return info?.id;
});

class CoupleNotifier extends AsyncNotifier<CoupleState> {
  @override
  Future<CoupleState> build() => _fetch();

  Future<CoupleState> _fetch() async {
    final ds = await ref.read(_coupleDsProvider.future);
    final info = await ds.getMyCouple();
    if (info == null) return const CoupleState();
    final summary = await ds.getSummary();
    final balance = await ds.getBalance();
    return CoupleState(info: info, summary: summary, balance: balance);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> createCouple(String? nombre) async {
    final ds = await ref.read(_coupleDsProvider.future);
    try {
      await ds.createCouple(nombre);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Crea una invitación y devuelve el token (para compartir con la pareja).
  Future<String?> invite(String email) async {
    final ds = await ref.read(_coupleDsProvider.future);
    try {
      return await ds.invite(email);
    } catch (_) {
      return null;
    }
  }

  Future<bool> accept(String token) async {
    final ds = await ref.read(_coupleDsProvider.future);
    try {
      await ds.accept(token);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Registra un pago a la pareja para saldar deuda y refresca el balance.
  Future<bool> settle(double monto) async {
    final ds = await ref.read(_coupleDsProvider.future);
    try {
      await ds.settle(monto);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}
