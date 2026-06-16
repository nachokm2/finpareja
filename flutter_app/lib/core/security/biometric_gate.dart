import 'package:flutter/material.dart';
import 'package:flutter_app/core/security/biometric_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _GateStatus { checking, locked, unlocked }

/// Envuelve la app y exige autenticación biométrica cuando el bloqueo está
/// activado. Se re-bloquea al volver del segundo plano. Si el bloqueo está
/// desactivado (por defecto), es transparente.
class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate>
    with WidgetsBindingObserver {
  _GateStatus _status = _GateStatus.checking;
  bool _enabled = false;
  bool _authInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _init() async {
    final service = ref.read(biometricServiceProvider);
    _enabled = await service.isEnabled();
    if (!mounted) return;
    if (!_enabled) {
      setState(() => _status = _GateStatus.unlocked);
    } else {
      setState(() => _status = _GateStatus.locked);
      await _unlock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;
    // Re-bloquea solo al pasar a segundo plano real (no mientras se muestra el
    // diálogo del sistema, que no llega a 'paused').
    if (state == AppLifecycleState.paused && !_authInProgress) {
      setState(() => _status = _GateStatus.locked);
    } else if (state == AppLifecycleState.resumed &&
        _status == _GateStatus.locked &&
        !_authInProgress) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_authInProgress) return;
    _authInProgress = true;
    final ok = await ref
        .read(biometricServiceProvider)
        .authenticate('Desbloquea FinPareja para continuar');
    _authInProgress = false;
    if (!mounted) return;
    if (ok) setState(() => _status = _GateStatus.unlocked);
  }

  @override
  Widget build(BuildContext context) {
    if (_status == _GateStatus.unlocked) return widget.child;

    return Material(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'FinPareja está bloqueada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifica tu identidad para continuar',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_status == _GateStatus.checking)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _authInProgress ? null : _unlock,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Desbloquear'),
              ),
          ],
        ),
      ),
    );
  }
}
