import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/features/cards/domain/entities/card_entities.dart';
import 'package:flutter_app/features/cards/presentation/providers/cards_provider.dart';
import 'package:flutter_app/features/cards/presentation/widgets/wallet_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardDetailPage extends ConsumerWidget {
  const CardDetailPage({super.key, required this.cardId});

  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsProvider);
    final card = cardsAsync.maybeWhen(
      data: (cards) {
        final match = cards.where((c) => c.id == cardId);
        return match.isEmpty ? null : match.first;
      },
      orElse: () => null,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Detalle de tarjeta'),
          actions: [
            if (card != null)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') _confirmDelete(context, ref);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Eliminar tarjeta')),
                ],
              ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Compras'), Tab(text: 'Pagos')],
          ),
        ),
        floatingActionButton: card == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showActions(context, ref),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
        body: card == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: SizedBox(height: 200, child: WalletCard(card: card)),
                  ),
                  _SummaryRow(card: card),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _PurchasesTab(cardId: cardId),
                        _PaymentsTab(cardId: cardId),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: const Text(
            'Se eliminará la tarjeta con todas sus compras y pagos. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(cardsProvider.notifier).deleteCard(cardId);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.primary),
              title: const Text('Agregar compra'),
              onTap: () {
                Navigator.pop(context);
                _showAddPurchase(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined,
                  color: AppColors.success),
              title: const Text('Registrar pago'),
              onTap: () {
                Navigator.pop(context);
                _showAddPayment(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPurchase(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddPurchaseSheet(cardId: cardId),
    );
  }

  void _showAddPayment(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddPaymentSheet(cardId: cardId),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.card});
  final CreditCardEntity card;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, double value, Color color) => Expanded(
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(value),
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Row(
        children: [
          item('Deuda', card.saldoPendiente, const Color(0xFFEF4444)),
          item('Compras', card.totalCompras, Colors.black87),
          item('Pagado', card.totalPagado, AppColors.success),
        ],
      ),
    );
  }
}

class _PurchasesTab extends ConsumerWidget {
  const _PurchasesTab({required this.cardId});
  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cardPurchasesProvider(cardId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (purchases) {
        if (purchases.isEmpty) {
          return const Center(
            child: Text('Sin compras registradas',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: purchases.length,
          itemBuilder: (_, i) {
            final p = purchases[i];
            return Dismissible(
              key: ValueKey(p.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: const Color(0xFFEF4444),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) =>
                  ref.read(cardsProvider.notifier).deletePurchase(cardId, p.id),
              child: Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    p.descripcion?.isNotEmpty == true ? p.descripcion! : 'Compra',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    p.esCuotas
                        ? '${p.cuotas} cuotas de ${CurrencyFormatter.format(p.valorCuota ?? 0)}'
                            '${(p.interes ?? 0) > 0 ? ' · interés ${CurrencyFormatter.format(p.interes!)}' : ''}'
                        : 'Al contado',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    CurrencyFormatter.format(p.deuda),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.cardId});
  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cardPaymentsProvider(cardId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (payments) {
        if (payments.isEmpty) {
          return const Center(
            child: Text('Sin pagos registrados',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (_, i) {
            final p = payments[i];
            return Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.check_circle,
                    color: AppColors.success),
                title: Text(CurrencyFormatter.format(p.monto),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${p.fecha.day}/${p.fecha.month}/${p.fecha.year}'
                  '${p.nota?.isNotEmpty == true ? ' · ${p.nota}' : ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Formulario: agregar compra ───────────────────────────────────────────────
class _AddPurchaseSheet extends ConsumerStatefulWidget {
  const _AddPurchaseSheet({required this.cardId});
  final int cardId;

  @override
  ConsumerState<_AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends ConsumerState<_AddPurchaseSheet> {
  final _descCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _cuotasCtrl = TextEditingController(text: '3');
  final _valorCuotaCtrl = TextEditingController();
  bool _enCuotas = false;
  DateTime _fecha = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _montoCtrl.dispose();
    _cuotasCtrl.dispose();
    _valorCuotaCtrl.dispose();
    super.dispose();
  }

  double get _monto => double.tryParse(_montoCtrl.text) ?? 0;
  int get _cuotas => int.tryParse(_cuotasCtrl.text) ?? 1;
  double get _valorCuota => double.tryParse(_valorCuotaCtrl.text) ?? 0;
  double get _totalCuotas => _valorCuota * _cuotas;
  double get _interes =>
      (_enCuotas && _totalCuotas > _monto) ? _totalCuotas - _monto : 0;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _save() async {
    if (_monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el monto de la compra')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await ref.read(cardsProvider.notifier).addPurchase(
          cardId: widget.cardId,
          monto: _monto,
          fecha: _fecha,
          descripcion: _descCtrl.text.trim(),
          cuotas: _enCuotas ? _cuotas : 1,
          valorCuota: _enCuotas && _valorCuota > 0 ? _valorCuota : null,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo agregar la compra')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fecha = '${_fecha.day}/${_fecha.month}/${_fecha.year}';
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            16,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agregar compra',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  labelText: 'Monto de la compra', prefixText: '\$ '),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event, color: AppColors.primary),
              title: const Text('Fecha'),
              subtitle: Text(fecha),
              trailing:
                  TextButton(onPressed: _pickDate, child: const Text('Cambiar')),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _enCuotas,
              onChanged: (v) => setState(() => _enCuotas = v),
              title: const Text('En cuotas'),
              subtitle: const Text('Desactivado = al contado'),
            ),
            if (_enCuotas) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cuotasCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration:
                          const InputDecoration(labelText: 'N° de cuotas'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _valorCuotaCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          labelText: 'Valor cuota', prefixText: '\$ '),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_totalCuotas > 0)
                Text(
                  'Total a pagar: ${CurrencyFormatter.format(_totalCuotas)}'
                  '${_interes > 0 ? '  ·  interés ${CurrencyFormatter.format(_interes)}' : ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Agregar compra'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Formulario: registrar pago ───────────────────────────────────────────────
class _AddPaymentSheet extends ConsumerStatefulWidget {
  const _AddPaymentSheet({required this.cardId});
  final int cardId;

  @override
  ConsumerState<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<_AddPaymentSheet> {
  final _montoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  final DateTime _fecha = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el monto del pago')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await ref.read(cardsProvider.notifier).addPayment(
          cardId: widget.cardId,
          monto: monto,
          fecha: _fecha,
          nota: _notaCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar el pago')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            16,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registrar pago',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _montoCtrl,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Monto del pago', prefixText: '\$ '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notaCtrl,
            decoration: const InputDecoration(labelText: 'Nota (opcional)'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Registrar pago'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
