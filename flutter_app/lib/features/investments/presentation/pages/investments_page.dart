import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/core/widgets/empty_state.dart';
import 'package:flutter_app/core/widgets/error_retry.dart';
import 'package:flutter_app/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter_app/features/investments/presentation/providers/investments_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvestmentsPage extends ConsumerWidget {
  const InvestmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invAsync = ref.watch(investmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Inversiones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva', style: TextStyle(color: Colors.white)),
      ),
      body: invAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.read(investmentsProvider.notifier).refresh(),
        ),
        data: (investments) {
          if (investments.isEmpty) {
            return const EmptyState(
              emoji: '📈',
              message: 'Sin inversiones registradas.\nAgrega acciones, fondos o cripto para seguir su valor',
            );
          }
          final valorTotal = investments.fold<double>(
              0, (s, i) => s + (i.valorActual ?? 0));
          final gananciaTotal = investments.fold<double>(
              0, (s, i) => s + (i.gananciaPerdida ?? 0));
          return RefreshIndicator(
            onRefresh: () => ref.read(investmentsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PortfolioCard(
                    valorTotal: valorTotal, gananciaTotal: gananciaTotal),
                const SizedBox(height: 16),
                ...investments.map((i) => _InvestmentCard(
                      investment: i,
                      onDelete: () =>
                          ref.read(investmentsProvider.notifier).delete(i.id),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref) {
    final nombreCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController();
    final compraCtrl = TextEditingController();
    final actualCtrl = TextEditingController();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nueva inversión',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre', hintText: 'Ej: Fondo Mutuo BCI'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cantidadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: compraCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Precio compra', prefixText: '\$ '),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: actualCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Precio actual', prefixText: '\$ '),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final nombre = nombreCtrl.text.trim();
                    if (nombre.isEmpty) return;
                    Navigator.pop(ctx);
                    await ref.read(investmentsProvider.notifier).create(
                          nombre: nombre,
                          cantidad: double.tryParse(cantidadCtrl.text),
                          precioCompra: double.tryParse(compraCtrl.text),
                          precioActual: double.tryParse(actualCtrl.text),
                        );
                  },
                  child: const Text('Guardar inversión'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.valorTotal, required this.gananciaTotal});
  final double valorTotal;
  final double gananciaTotal;

  @override
  Widget build(BuildContext context) {
    final positivo = gananciaTotal >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(210)],
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
          const Text('Valor del portafolio',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(valorTotal),
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(positivo ? Icons.trending_up : Icons.trending_down,
                  color: positivo
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFFD2D2),
                  size: 18),
              const SizedBox(width: 4),
              Text(
                '${positivo ? '+' : ''}${CurrencyFormatter.format(gananciaTotal)}',
                style: TextStyle(
                  color: positivo
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFFD2D2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  const _InvestmentCard({required this.investment, required this.onDelete});
  final InvestmentEntity investment;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final ganancia = investment.gananciaPerdida;
    final color =
        investment.tieneGanancia ? AppColors.success : AppColors.expense;
    final rentabilidad = investment.rentabilidad;

    return Dismissible(
      key: Key('inv_${investment.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(investment.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  if (investment.tipo != null)
                    Text(investment.tipo!,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    'Valor: ${CurrencyFormatter.format(investment.valorActual ?? 0)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ganancia != null)
                  Text(
                    '${investment.tieneGanancia ? '+' : ''}${CurrencyFormatter.compact(ganancia)}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                if (rentabilidad != null)
                  Text(
                    '${rentabilidad >= 0 ? '+' : ''}${rentabilidad.toStringAsFixed(1)}%',
                    style: TextStyle(color: color, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
