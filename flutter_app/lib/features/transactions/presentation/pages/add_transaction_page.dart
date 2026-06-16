import 'package:flutter/material.dart';
import 'package:flutter_app/core/ocr/receipt_scanner.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_app/features/categories/presentation/providers/categories_provider.dart';
import 'package:flutter_app/features/couple/presentation/providers/couple_provider.dart';
import 'package:flutter_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_app/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  /// Si [transaction] viene dado, la pantalla opera en modo edición
  /// (precarga los campos y hace PATCH); si es null, crea una nueva.
  const AddTransactionPage({super.key, this.transaction});

  final TransactionEntity? transaction;

  @override
  ConsumerState<AddTransactionPage> createState() =>
      _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  late String _tipo;
  late String _monto;
  String? _descripcion;
  CategoryEntity? _selectedCategory;
  late DateTime _fecha;
  bool _saving = false;
  bool _scanning = false; // leyendo una boleta con la cámara (OCR)
  bool _compartir = false; // dividir el gasto con la pareja
  int _porcentajeUsuario = 50; // mi parte del gasto compartido (10..90)
  late final TextEditingController _descCtrl;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    if (tx != null) {
      _tipo = tx.tipo;
      // El monto se muestra sin decimales (CLP); toInt para el teclado.
      _monto = tx.monto.toInt().toString();
      _descripcion = tx.descripcion;
      _fecha = tx.fecha;
      _compartir = tx.esCompartido;
    } else {
      _tipo = 'gasto';
      _monto = '0';
      _fecha = DateTime.now();
    }
    _descCtrl = TextEditingController(text: _descripcion ?? '');
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  /// Escanea una boleta con la cámara (OCR on-device) y prellena los campos.
  /// El usuario siempre revisa el monto detectado antes de guardar.
  Future<void> _scanReceipt() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _scanning = true);
    try {
      final data = await ReceiptScanner().scanFromCamera();
      if (!mounted) return;
      setState(() => _scanning = false);
      if (data == null) return; // el usuario canceló la cámara
      if (data.rawText.trim().isEmpty) {
        messenger.showSnackBar(const SnackBar(
          content: Text(
              'No se reconoció texto. Prueba con más luz y la boleta plana.'),
        ));
        return;
      }
      await _showReceiptReview(data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _scanning = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo leer la boleta')),
      );
    }
  }

  /// Hoja de revisión tras escanear: muestra los montos detectados para que el
  /// usuario elija/corrija el total, y un acceso al texto crudo (diagnóstico).
  Future<void> _showReceiptReview(ReceiptData data) async {
    final montoCtrl = TextEditingController(
      text: data.monto != null
          ? data.monto!.toInt().toString()
          : (data.candidates.isNotEmpty
              ? data.candidates.first.toInt().toString()
              : ''),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).viewPadding.bottom +
              16,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Revisa el gasto de la boleta',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 6),
              Text(
                data.candidates.isEmpty
                    ? 'No detectamos montos. Escríbelo abajo o míralo en "Ver texto leído".'
                    : 'Toca el total correcto o escríbelo.',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Monto total', prefixText: '\$ '),
              ),
              if (data.candidates.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.candidates.take(8).map((c) {
                    return ActionChip(
                      label: Text(CurrencyFormatter.format(c)),
                      onPressed: () =>
                          setSheet(() => montoCtrl.text = c.toInt().toString()),
                    );
                  }).toList(),
                ),
              ],
              if (data.fecha != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Fecha detectada: ${data.fecha!.day}/${data.fecha!.month}/${data.fecha!.year}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final monto = double.tryParse(montoCtrl.text);
                    Navigator.pop(ctx);
                    setState(() {
                      _tipo = 'gasto';
                      if (monto != null && monto > 0) {
                        _monto = monto.toInt().toString();
                      }
                      if (data.fecha != null) _fecha = data.fecha!;
                      if (data.comercio != null &&
                          _descCtrl.text.trim().isEmpty) {
                        _descCtrl.text = data.comercio!;
                        _descripcion = data.comercio;
                      }
                    });
                  },
                  child: const Text('Usar estos datos'),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Texto leído'),
                      content: SingleChildScrollView(
                        child: SelectableText(
                          data.rawText.isEmpty ? '(vacío)' : data.rawText,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Ver texto leído'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_monto == '0') {
        _monto = digit;
      } else {
        _monto = _monto + digit;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_monto.length <= 1) {
        _monto = '0';
      } else {
        _monto = _monto.substring(0, _monto.length - 1);
      }
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_monto) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto valido')),
      );
      return;
    }
    setState(() => _saving = true);
    final notifier = ref.read(transactionsProvider.notifier);
    // Solo gastos compartidos: divide 50/50 con la pareja.
    final compartir = _compartir && _tipo == 'gasto';
    final parejaId =
        compartir ? ref.read(currentCoupleIdProvider).valueOrNull : null;
    final ok = _isEditing
        ? await notifier.edit(
            id: widget.transaction!.id,
            tipo: _tipo,
            monto: amount,
            fecha: _fecha,
            descripcion: _descripcion,
            categoriaId: _selectedCategory?.id,
          )
        : await notifier.create(
            tipo: _tipo,
            monto: amount,
            fecha: _fecha,
            descripcion: _descripcion,
            categoriaId: _selectedCategory?.id,
            esCompartido: compartir && parejaId != null,
            porcentajeUsuario: compartir ? _porcentajeUsuario.toDouble() : 100,
            parejaId: compartir ? parejaId : null,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGasto = _tipo == 'gasto';
    final amount = double.tryParse(_monto) ?? 0;
    final categoriesAsync = isGasto
        ? ref.watch(gastoCategoriesProvider)
        : ref.watch(ingresoCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar transacción' : 'Nueva transacción'),
        actions: [
          if (!_isEditing)
            _scanning
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.document_scanner_outlined),
                    tooltip: 'Escanear boleta',
                    onPressed: _scanReceipt,
                  ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Guardar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Tipo toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: AppColors.cardShadow, blurRadius: 8),
                ],
              ),
              child: Row(
                children: ['gasto', 'ingreso'].map((tipo) {
                  final selected = _tipo == tipo;
                  final color = tipo == 'gasto'
                      ? const Color(0xFFEF4444)
                      : AppColors.success;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _tipo = tipo;
                        _selectedCategory = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? color : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tipo == 'gasto' ? 'Gasto' : 'Ingreso',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Monto
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              CurrencyFormatter.format(amount),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isGasto
                        ? const Color(0xFFEF4444)
                        : AppColors.success,
                  ),
            ),
          ),

          // Categorias
          SizedBox(
            height: 80,
            child: categoriesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (categories) {
                // Al editar, preselecciona la categoría original una sola vez,
                // cuando la lista ya cargó (post-frame para no romper el build).
                if (_isEditing &&
                    _selectedCategory == null &&
                    widget.transaction!.categoriaId != null) {
                  final match = categories
                      .where((c) => c.id == widget.transaction!.categoriaId);
                  if (match.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _selectedCategory = match.first);
                      }
                    });
                  }
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final selected = _selectedCategory?.id == cat.id;
                  return GestureDetector(
                    onTap: () => setState(
                      () => _selectedCategory = selected ? null : cat,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat.icono ?? '📦',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat.nombre,
                            style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Descripcion
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                hintText: 'Descripcion (opcional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => _descripcion = v.isEmpty ? null : v,
            ),
          ),

          // Dividir con pareja: solo en gastos y si el usuario tiene pareja.
          if (_tipo == 'gasto' && !_isEditing)
            ref.watch(currentCoupleIdProvider).maybeWhen(
                  data: (parejaId) => parejaId == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  value: _compartir,
                                  onChanged: (v) =>
                                      setState(() => _compartir = v),
                                  title: const Text('Dividir con mi pareja'),
                                  subtitle: Text(_compartir
                                      ? 'Tú $_porcentajeUsuario% · tu pareja debe ${100 - _porcentajeUsuario}%'
                                      : 'Divide el gasto y registra la deuda'),
                                  secondary:
                                      const Icon(Icons.people_alt_outlined),
                                ),
                                if (_compartir)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Tú $_porcentajeUsuario%',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            Text(
                                                'Pareja ${100 - _porcentajeUsuario}%',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: Color(0xFFEF4444))),
                                          ],
                                        ),
                                        Slider(
                                          value: _porcentajeUsuario.toDouble(),
                                          min: 10,
                                          max: 90,
                                          divisions: 8,
                                          label: '$_porcentajeUsuario%',
                                          onChanged: (v) => setState(() =>
                                              _porcentajeUsuario = v.round()),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),

          const Spacer(),

          // Teclado numerico.
          // El padding inferior suma el alto de la barra de navegación del
          // sistema (viewPadding.bottom) para que las teclas no queden debajo.
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Column(
              children: [
                _buildKeyRow(['1', '2', '3']),
                _buildKeyRow(['4', '5', '6']),
                _buildKeyRow(['7', '8', '9']),
                _buildKeyRow(['000', '0', '⌫']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: GestureDetector(
            onTap: () => key == '⌫' ? _backspace() : _appendDigit(key),
            child: Container(
              height: 60,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  key,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
