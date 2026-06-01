import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/core/utils/date_formatter.dart';
import 'package:flutter_app/core/widgets/empty_state.dart';
import 'package:flutter_app/core/widgets/error_retry.dart';
import 'package:flutter_app/features/debts/domain/entities/debt_entity.dart';
import 'package:flutter_app/features/debts/presentation/providers/debts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DebtsPage extends ConsumerWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Deudas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva deuda', style: TextStyle(color: Colors.white)),
      ),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.read(debtsProvider.notifier).refresh(),
        ),
        data: (debts) {
          if (debts.isEmpty) {
            return const EmptyState(
              emoji: '💳',
              message: 'Sin deudas registradas.\n¡Buena señal! O agrega una para llevar su control',
            );
          }
          final pendientes =
              debts.where((d) => !d.estaPagada).fold<double>(0, (s, d) => s + d.montoPendiente);
          return RefreshIndicator(
            onRefresh: () => ref.read(debtsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TotalCard(totalPendiente: pendientes),
                const SizedBox(height: 16),
                ...debts.map((d) => _DebtCard(
                      debt: d,
                      onPay: (monto) =>
                          ref.read(debtsProvider.notifier).addPayment(d.id, monto),
                      onDelete: () =>
                          ref.read(debtsProvider.notifier).delete(d.id),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref) {
    final acreedorCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nueva deuda',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: acreedorCtrl,
              decoration: const InputDecoration(
                  labelText: 'Acreedor', hintText: 'Banco, persona...'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Monto total', prefixText: '\$ '),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final acreedor = acreedorCtrl.text.trim();
                  final monto = double.tryParse(montoCtrl.text);
                  if (acreedor.isEmpty || monto == null || monto <= 0) return;
                  Navigator.pop(ctx);
                  await ref.read(debtsProvider.notifier).create(
                        acreedor: acreedor,
                        montoOriginal: monto,
                      );
                },
                child: const Text('Crear deuda'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalPendiente});
  final double totalPendiente;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.expense, Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total adeudado',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(totalPendiente),
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.debt,
    required this.onPay,
    required this.onDelete,
  });

  final DebtEntity debt;
  final Future<bool> Function(double monto) onPay;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final color = debt.estaPagada ? AppColors.success : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.acreedor,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    if (debt.fechaVencimiento != null)
                      Text(
                        'Vence ${DateFormatter.medium(debt.fechaVencimiento!)}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (debt.estaPagada)
                const Chip(
                  label: Text('Pagada', style: TextStyle(fontSize: 11)),
                  backgroundColor: Color(0x1A10B981),
                  labelStyle: TextStyle(color: AppColors.success),
                  visualDensity: VisualDensity.compact,
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.grey),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: debt.progreso,
              minHeight: 8,
              backgroundColor: color.withAlpha(25),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pagado: ${CurrencyFormatter.format(debt.montoPagado)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Pendiente: ${CurrencyFormatter.format(debt.montoPendiente)}',
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (!debt.estaPagada) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showPay(context),
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: const Text('Registrar pago'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(38)),
            ),
          ],
        ],
      ),
    );
  }

  void _showPay(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pago a "${debt.acreedor}"',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Pendiente: ${CurrencyFormatter.format(debt.montoPendiente)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final monto = double.tryParse(ctrl.text);
                  if (monto == null || monto <= 0) return;
                  Navigator.pop(ctx);
                  await onPay(monto);
                },
                child: const Text('Registrar pago'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
