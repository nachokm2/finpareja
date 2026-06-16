import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manejador de mensajes en segundo plano / app cerrada.
/// Debe ser una función top-level (lo exige firebase_messaging).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // No hace falta lógica: FCM muestra la notificación del sistema solo.
}

/// Gestiona el token FCM del dispositivo y lo sincroniza con el backend.
class PushService {
  bool _registered = false;

  /// Pide permiso de notificaciones, obtiene el token y lo registra en el
  /// backend. Best-effort: si algo falla, no rompe la app. Se ejecuta una vez
  /// por sesión (al autenticarse).
  Future<void> registerToken(Dio dio) async {
    if (_registered) return;
    _registered = true;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) await _send(dio, token);
      // Si Firebase rota el token, lo re-registramos.
      messaging.onTokenRefresh.listen((t) => _send(dio, t));
    } catch (e) {
      debugPrint('PushService.registerToken: $e');
      _registered = false; // permite reintentar en el próximo login
    }
  }

  Future<void> _send(Dio dio, String token) async {
    try {
      await dio.post('/dispositivos/registrar',
          data: {'token': token, 'plataforma': 'android'});
    } catch (e) {
      debugPrint('PushService._send: $e');
    }
  }

  /// Quita el token del backend al cerrar sesión (deja de recibir push).
  Future<void> unregister(Dio dio) async {
    _registered = false;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await dio.post('/dispositivos/eliminar', data: {'token': token});
      }
    } catch (e) {
      debugPrint('PushService.unregister: $e');
    }
  }
}

final pushServiceProvider = Provider<PushService>((_) => PushService());
