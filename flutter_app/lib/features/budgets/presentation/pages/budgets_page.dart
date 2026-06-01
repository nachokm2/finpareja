import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/core/widgets/empty_state.dart';
import 'package:flutter_app/core/widgets/error_retry.dart';
import 'package:flutter_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_app/features/budgets/presentation/providers/budgets_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Presupuestos')),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.read(budgetsProvider.notifier).refresh(),
        ),
        data: (budgets) {
          if (budgets.isEmpty) {
            return const EmptyState(
              emoji: '📊',
              message: 'Sin presupuestos este mes',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(budgetsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: budgets.length,
              itemBuilder: (_, i) => _BudgetCard(budget: budgets[i]),
            ),
          );
        },
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget});
  final BudgetEntity budget;

  @override
  Widget build(BuildContext context) {
    final pct = (budget.porcentajeUsado / 100).clamp(0.0, 1.0);
    final color = AppColors.forBudgetUsage(
      porcentaje: budget.porcentajeUsado,
      excedido: budget.excedido,
    );

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                budget.categoriaId != null ? 'Categoría #${budget.categoriaId}' : 'General',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${budget.porcentajeUsado.toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gastado: ${CurrencyFormatter.format(budget.montoGastado)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Límite: ${CurrencyFormatter.format(budget.montoLimite)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
