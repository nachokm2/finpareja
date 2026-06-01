import 'dart:convert';

import 'package:flutter_app/features/auth/domain/entities/user.dart';
import 'package:flutter_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_app/features/home/presentation/providers/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Estado ───────────────────────────────────────────────────────────────────

enum AuthStatus { authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.authenticated(User user)
      : status = AuthStatus.authenticated,
        user = user,
        errorMessage = null;

  const AuthState.unauthenticated({String? message})
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = message;

  final AuthStatus status;
  final User? user;

  /// Mensaje de error del último intento de login/register.
  /// Se limpia en el siguiente intento.
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// ─── Notifier ────────────────────────────────────────────────────────────────

/// Fuente única de verdad del estado de autenticación.
///
/// Al construirse (cold start) verifica el token almacenado localmente:
///   1. Si no hay token → unauthenticated.
///   2. Si el token está expirado (verificación local sin red) → borra y unauthenticated.
///   3. Si el token es válido → obtiene el perfil del servidor para confirmar.
///
/// El GoRouter escucha los cambios vía refreshListenable y redirige
/// automáticamente — las páginas nunca necesitan llamar context.go() para auth.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() => _checkInitialAuth();

  // ── Verificación al arrancar ────────────────────────────────────────────

  Future<AuthState> _checkInitialAuth() async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final token = await repo.getAccessToken();

      if (token == null) return const AuthState.unauthenticated();

      if (_isTokenExpired(token)) {
        await repo.clearTokens();
        return const AuthState.unauthenticated();
      }

      // Confirmar con el servidor que el token sigue siendo válido
      final useCase = await ref.read(getProfileUseCaseProvider.future);
      final result = await useCase.call();

      return result.fold(
        (failure) async {
          await repo.clearTokens();
          return const AuthState.unauthenticated();
        },
        (user) => AuthState.authenticated(user),
      );
    } catch (_) {
      return const AuthState.unauthenticated();
    }
  }

  // ── Acciones públicas ────────────────────────────────────────────────────

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final loginUseCase = await ref.read(loginUseCaseProvider.future);
      final loginResult = await loginUseCase.call(email, password);

      String? loginError;
      loginResult.fold((f) => loginError = f.message, (_) {});

      if (loginError != null) {
        state = AsyncValue.data(AuthState.unauthenticated(message: loginError));
        return;
      }

      // Login exitoso → cargar perfil del servidor
      final profileUseCase = await ref.read(getProfileUseCaseProvider.future);
      final profileResult = await profileUseCase.call();

      state = AsyncValue.data(
        profileResult.fold(
          (f) => AuthState.unauthenticated(message: f.message),
          (user) => AuthState.authenticated(user),
        ),
      );
    } catch (_) {
      state = const AsyncValue.data(
        AuthState.unauthenticated(message: 'Error inesperado. Intenta de nuevo.'),
      );
    }
  }

  Future<void> signOut() async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.logout();
    } finally {
      // Invalidar la cache del perfil antes de actualizar auth state
      ref.invalidate(profileProvider);
      state = const AsyncValue.data(AuthState.unauthenticated());
    }
  }

  // ── JWT decoder local ────────────────────────────────────────────────────

  /// Verifica la expiración del JWT sin llamar al servidor.
  /// Incluye un buffer de 30 segundos para evitar race conditions.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Base64Url → Base64 estándar
      var raw = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (raw.length % 4 != 0) {
        raw += '=';
      }

      final decoded = base64Decode(raw);
      final payload = json.decode(utf8.decode(decoded)) as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return true;

      final expiryUtc = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      final nowUtc = DateTime.now().toUtc();
      return nowUtc.isAfter(expiryUtc.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true; // Si no se puede decodificar, asumir expirado
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
