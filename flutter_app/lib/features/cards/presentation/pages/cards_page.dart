import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/widgets/empty_state.dart';
import 'package:flutter_app/core/widgets/error_retry.dart';
import 'package:flutter_app/features/cards/presentation/pages/card_detail_page.dart';
import 'package:flutter_app/features/cards/presentation/providers/cards_provider.dart';
import 'package:flutter_app/features/cards/presentation/widgets/wallet_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardsPage extends ConsumerStatefulWidget {
  const CardsPage({super.key});

  @override
  ConsumerState<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends ConsumerState<CardsPage> {
  final _controller = PageController(viewportFraction: 0.86);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis tarjetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            iconSize: 30,
            tooltip: 'Agregar tarjeta',
            onPressed: () => _showCreate(context),
          ),
        ],
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.read(cardsProvider.notifier).refresh(),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return const EmptyState(
              emoji: '💳',
              message:
                  'Sin tarjetas registradas.\nAgrega una para controlar tus compras y deuda',
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              SizedBox(
                height: 210,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: cards.length,
                  itemBuilder: (_, i) {
                    final scale = (1 - ((_page - i).abs() * 0.12)).clamp(0.9, 1.0);
                    return Transform.scale(
                      scale: scale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CardDetailPage(cardId: cards[i].id),
                            ),
                          ),
                          child: WalletCard(card: cards[i]),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Indicadores
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < cards.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: (_page.round() == i) ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: (_page.round() == i)
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Toca una tarjeta para ver el detalle, agregar compras y registrar pagos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreate(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CreateCardSheet(),
    );
  }
}

class _CreateCardSheet extends ConsumerStatefulWidget {
  const _CreateCardSheet();

  @override
  ConsumerState<_CreateCardSheet> createState() => _CreateCardSheetState();
}

class _CreateCardSheetState extends ConsumerState<_CreateCardSheet> {
  final _nombreCtrl = TextEditingController();
  final _emisorCtrl = TextEditingController();
  final _digitosCtrl = TextEditingController();
  final _cupoCtrl = TextEditingController();
  String _color = '#4C4DDC';
  bool _saving = false;

  static const _colores = [
    '#4C4DDC', '#1E1E2C', '#0F9D58', '#D32F2F', '#F59E0B', '#6C5CE7', '#0984E3',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emisorCtrl.dispose();
    _digitosCtrl.dispose();
    _cupoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre a la tarjeta')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await ref.read(cardsProvider.notifier).createCard(
          nombre: nombre,
          emisor: _emisorCtrl.text.trim(),
          ultimosDigitos: _digitosCtrl.text.trim(),
          cupo: double.tryParse(_cupoCtrl.text),
          color: _color,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear la tarjeta')),
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
          const Text('Nueva tarjeta',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _nombreCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Nombre', hintText: 'Ej: Visa Falabella'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emisorCtrl,
            decoration: const InputDecoration(
                labelText: 'Banco / emisor (opcional)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _digitosCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                      labelText: 'Últimos 4 dígitos', counterText: ''),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cupoCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Cupo', prefixText: '\$ '),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Color', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _colores.map((c) {
              final selected = _color == c;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(int.parse('FF${c.substring(1)}', radix: 16)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.black87 : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
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
                  : const Text('Crear tarjeta'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
