import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/features/cards/data/datasources/card_remote_datasource.dart';
import 'package:flutter_app/features/cards/domain/entities/card_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cardDsProvider = FutureProvider<CardRemoteDataSource>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return CardRemoteDataSource(dio);
});

/// Lista de tarjetas con su resumen de deuda.
final cardsProvider =
    AsyncNotifierProvider<CardsNotifier, List<CreditCardEntity>>(
  CardsNotifier.new,
);

/// Compras de una tarjeta (por id).
final cardPurchasesProvider =
    FutureProvider.family<List<CardPurchaseEntity>, int>((ref, cardId) async {
  final ds = await ref.watch(cardDsProvider.future);
  return ds.listPurchases(cardId);
});

/// Pagos de una tarjeta (por id).
final cardPaymentsProvider =
    FutureProvider.family<List<CardPaymentEntity>, int>((ref, cardId) async {
  final ds = await ref.watch(cardDsProvider.future);
  return ds.listPayments(cardId);
});

class CardsNotifier extends AsyncNotifier<List<CreditCardEntity>> {
  @override
  Future<List<CreditCardEntity>> build() async {
    final ds = await ref.read(cardDsProvider.future);
    return ds.listCards();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final ds = await ref.read(cardDsProvider.future);
      return ds.listCards();
    });
  }

  Future<bool> createCard({
    required String nombre,
    String? emisor,
    String? ultimosDigitos,
    double? cupo,
    String? color,
  }) async {
    try {
      final ds = await ref.read(cardDsProvider.future);
      await ds.createCard(
        nombre: nombre, emisor: emisor, ultimosDigitos: ultimosDigitos,
        cupo: cupo, color: color,
      );
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteCard(int id) async {
    final ds = await ref.read(cardDsProvider.future);
    await ds.deleteCard(id);
    await refresh();
  }

  Future<bool> addPurchase({
    required int cardId,
    required double monto,
    required DateTime fecha,
    String? descripcion,
    int cuotas = 1,
    double? valorCuota,
    double? interes,
    int? categoriaId,
  }) async {
    try {
      final ds = await ref.read(cardDsProvider.future);
      await ds.addPurchase(
        cardId: cardId, monto: monto, fecha: fecha, descripcion: descripcion,
        cuotas: cuotas, valorCuota: valorCuota, interes: interes,
        categoriaId: categoriaId,
      );
      ref.invalidate(cardPurchasesProvider(cardId));
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deletePurchase(int cardId, int purchaseId) async {
    final ds = await ref.read(cardDsProvider.future);
    await ds.deletePurchase(cardId, purchaseId);
    ref.invalidate(cardPurchasesProvider(cardId));
    await refresh();
  }

  Future<bool> addPayment({
    required int cardId,
    required double monto,
    required DateTime fecha,
    String? nota,
  }) async {
    try {
      final ds = await ref.read(cardDsProvider.future);
      await ds.addPayment(cardId: cardId, monto: monto, fecha: fecha, nota: nota);
      ref.invalidate(cardPaymentsProvider(cardId));
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}
