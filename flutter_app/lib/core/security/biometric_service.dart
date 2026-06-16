import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Bloqueo biométrico opcional de la app.
///
/// El estado (activado/desactivado) se guarda en almacenamiento seguro y está
/// DESACTIVADO por defecto. La autenticación permite huella/rostro o, como
/// respaldo, el PIN/patrón del dispositivo, para no dejar al usuario fuera.
class BiometricService {
  BiometricService(this._storage, this._auth);

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  static const _key = 'biometric_lock_enabled';

  /// Cuando es true, el bloqueo biométrico ignora el próximo paso a segundo
  /// plano. Se usa al abrir cámara/galería/compartir desde la propia app, para
  /// que al volver NO pida la huella (esa salida no es "salir de la app").
  bool ignoreNextPause = false;

  /// Ejecuta [action] (que abre una actividad externa: cámara, galería, share)
  /// sin que el candado se active al volver.
  Future<T> duringExternalActivity<T>(Future<T> Function() action) async {
    ignoreNextPause = true;
    try {
      return await action();
    } finally {
      ignoreNextPause = false;
    }
  }

  Future<bool> isEnabled() async => (await _storage.read(key: _key)) == 'true';

  Future<void> setEnabled(bool value) =>
      _storage.write(key: _key, value: value ? 'true' : 'false');

  /// Indica si el dispositivo puede autenticar (biometría o credencial del sistema).
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Lanza el diálogo del sistema. Devuelve true solo si la identidad se verificó.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(const FlutterSecureStorage(), LocalAuthentication()),
);
