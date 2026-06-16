import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/core/widgets/empty_state.dart';
import 'package:flutter_app/core/widgets/error_retry.dart';
import 'package:flutter_app/features/recurring/domain/entities/recurring_entity.dart';
import 'package:flutter_app/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:flutter_app/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recAsync = ref.watch(recurringProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recurrentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            iconSize: 30,
            tooltip: 'Nueva recurrente',
            onPressed: () => _showCreate(context),
          ),
        ],
      ),
      body: recAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.read(recurringProvider.notifier).refresh(),
        ),
        data: (recs) {
          if (recs.isEmpty) {
            return const EmptyState(
              emoji: '🔁',
              message:
                  'Sin transacciones recurrentes.\nAutomatiza tu arriendo, sueldo o suscripciones',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(recurringProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recs.length,
              itemBuilder: (_, i) => _RecurringCard(rec: recs[i]),
            ),
          );
        },
      ),
    );
  }

  void _showCreate(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) =>
            _CreateRecurringSheet(scrollController: scrollController),
      ),
    );
  }
}

class _RecurringCard extends ConsumerWidget {
  const _RecurringCard({required this.rec});
  final RecurringEntity rec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = rec.esGasto ? const Color(0xFFEF4444) : AppColors.success;
    final fecha =
        '${rec.proximaFecha.day.toString().padLeft(2, '0')}/${rec.proximaFecha.month.toString().padLeft(2, '0')}/${rec.proximaFecha.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.descripcion?.isNotEmpty == true
                      ? rec.descripcion!
                      : (rec.esGasto ? 'Gasto recurrente' : 'Ingreso recurrente'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rec.frecuenciaLabel} · próxima: $fecha',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(rec.monto),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: rec.activo,
                onChanged: (_) =>
                    ref.read(recurringProvider.notifier).toggleActive(rec),
              ),
              GestureDetector(
                onTap: () => _confirmDelete(context, ref),
                child: const Icon(Icons.delete_outline,
                    color: Colors.grey, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar recurrente'),
        content: const Text(
            'Dejará de generar transacciones. Las ya creadas no se borran.'),
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
      await ref.read(recurringProvider.notifier).delete(rec.id);
    }
  }
}

class _CreateRecurringSheet extends ConsumerStatefulWidget {
  const _CreateRecurringSheet({required this.scrollController});
  final ScrollController scrollController;

  @override
  ConsumerState<_CreateRecurringSheet> createState() =>
      _CreateRecurringSheetState();
}

class _CreateRecurringSheetState extends ConsumerState<_CreateRecurringSheet> {
  final _montoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _tipo = 'gasto';
  String _frecuencia = 'mensual';
  DateTime _proximaFecha = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _proximaFecha,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _proximaFecha = picked);
  }

  Future<void> _save() async {
    final monto = double.tryParse(_montoCtrl.text);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await ref.read(recurringProvider.notifier).create(
          tipo: _tipo,
          monto: monto,
          frecuencia: _frecuencia,
          proximaFecha: _proximaFecha,
          descripcion: _descCtrl.text.isEmpty ? null : _descCtrl.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      // Materializa de inmediato si la fecha ya venció y refresca movimientos.
      await ref.read(recurringDsProvider.future).then((ds) => ds.process());
      ref.invalidate(transactionsProvider);
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear la recurrente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fecha =
        '${_proximaFecha.day.toString().padLeft(2, '0')}/${_proximaFecha.month.toString().padLeft(2, '0')}/${_proximaFecha.year}';

    return SingleChildScrollView(
      controller: widget.scrollController,
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
          const Text('Nueva recurrente',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          // Tipo
          Row(
            children: [
              _ChoiceChip(
                label: 'Gasto',
                selected: _tipo == 'gasto',
                onTap: () => setState(() => _tipo = 'gasto'),
              ),
              const SizedBox(width: 8),
              _ChoiceChip(
                label: 'Ingreso',
                selected: _tipo == 'ingreso',
                onTap: () => setState(() => _tipo = 'ingreso'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _montoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción (ej: Arriendo, Sueldo)',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Frecuencia', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              _ChoiceChip(
                label: 'Mensual',
                selected: _frecuencia == 'mensual',
                onTap: () => setState(() => _frecuencia = 'mensual'),
              ),
              const SizedBox(width: 8),
              _ChoiceChip(
                label: 'Semanal',
                selected: _frecuencia == 'semanal',
                onTap: () => setState(() => _frecuencia = 'semanal'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event, color: AppColors.primary),
            title: const Text('Próxima fecha'),
            subtitle: Text(fecha),
            trailing: TextButton(onPressed: _pickDate, child: const Text('Cambiar')),
          ),
          const SizedBox(height: 12),
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
                  : const Text('Crear recurrente'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
