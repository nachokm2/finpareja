import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/core/widgets/empty_state.dart';
import 'package:flutter_app/core/widgets/error_retry.dart';
import 'package:flutter_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_app/features/budgets/presentation/providers/budgets_provider.dart';
import 'package:flutter_app/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_app/features/categories/presentation/providers/categories_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            iconSize: 30,
            tooltip: 'Nuevo presupuesto',
            onPressed: () => _showCreate(context, ref),
          ),
        ],
      ),
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
              message: 'Sin presupuestos este mes.\nCrea uno para controlar tus gastos por categoría',
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

  void _showCreate(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CreateBudgetSheet(),
    );
  }
}

/// Bottom sheet para crear un presupuesto: elige categoría de gasto + monto.
class _CreateBudgetSheet extends ConsumerStatefulWidget {
  const _CreateBudgetSheet();

  @override
  ConsumerState<_CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends ConsumerState<_CreateBudgetSheet> {
  final _montoCtrl = TextEditingController();
  CategoryEntity? _selected;
  bool _saving = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final monto = double.tryParse(_montoCtrl.text);
    if (monto == null || monto <= 0) return;
    setState(() => _saving = true);
    final ok = await ref.read(budgetsProvider.notifier).create(
          montoLimite: monto,
          categoriaId: _selected?.id,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el presupuesto')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(gastoCategoriesProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nuevo presupuesto',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          const Text('Categoría', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('No se pudieron cargar las categorías'),
            data: (categories) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Opción "General" (sin categoría) + cada categoría de gasto.
                _CategoryChip(
                  label: 'General',
                  emoji: '📋',
                  selected: _selected == null,
                  onTap: () => setState(() => _selected = null),
                ),
                ...categories.map((c) => _CategoryChip(
                      label: c.nombre,
                      emoji: c.icono ?? '📦',
                      selected: _selected?.id == c.id,
                      onTap: () => setState(() => _selected = c),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _montoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto límite mensual',
              prefixText: '\$ ',
            ),
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
                  : const Text('Crear presupuesto'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          '$emoji $label',
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.budget});
  final BudgetEntity budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = (budget.porcentajeUsado / 100).clamp(0.0, 1.0);
    final color = AppColors.forBudgetUsage(
      porcentaje: budget.porcentajeUsado,
      excedido: budget.excedido,
    );

    // Resuelve el nombre de la categoría desde el cache de categorías.
    final categoriesAsync = ref.watch(categoriesProvider);
    final nombreCategoria = budget.categoriaId == null
        ? 'General'
        : categoriesAsync.maybeWhen(
            data: (cats) {
              final match = cats.where((c) => c.id == budget.categoriaId);
              return match.isNotEmpty ? match.first.nombre : 'Categoría';
            },
            orElse: () => 'Categoría',
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
                nombreCategoria,
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
