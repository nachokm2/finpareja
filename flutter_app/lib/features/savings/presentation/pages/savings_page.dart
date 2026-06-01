import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/core/widgets/empty_state.dart';
import 'package:flutter_app/core/widgets/error_retry.dart';
import 'package:flutter_app/features/savings/domain/entities/saving_goal_entity.dart';
import 'package:flutter_app/features/savings/presentation/providers/saving_goals_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SavingsPage extends ConsumerWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingGoalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Metas de ahorro')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.read(savingGoalsProvider.notifier).refresh(),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return const EmptyState(
              emoji: '🎯',
              message: 'Sin metas de ahorro.\nCrea tu primera meta para empezar a ahorrar',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(savingGoalsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (_, i) => _GoalCard(goal: goals[i], ref: ref),
            ),
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.ref});
  final SavingGoalEntity goal;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progresoPorcentaje / 100).clamp(0.0, 1.0);
    final color = goal.estaCompletada ? AppColors.success : AppColors.primary;

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
              Text(goal.icono ?? '🎯', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (goal.estaCompletada)
                      const Text('✅ Completada', style: TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                '${goal.progresoPorcentaje.toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct, minHeight: 8,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(goal.montoActual),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              Text(
                'Meta: ${CurrencyFormatter.format(goal.montoObjetivo)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          if (!goal.estaCompletada) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showAddContribution(context, goal),
              icon: const Icon(Icons.add, size: 16),
              label: Text('Aportar ${CurrencyFormatter.format(goal.montoFaltante)} faltantes'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddContribution(BuildContext context, SavingGoalEntity goal) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Agregar aporte a "${goal.nombre}"', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto (CLP)', prefixText: '\$'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text);
                if (amount == null || amount <= 0) return;
                Navigator.pop(ctx);
                await ref.read(savingGoalsProvider.notifier).addContribution(goal.id, amount);
              },
              child: const Text('Guardar aporte'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
