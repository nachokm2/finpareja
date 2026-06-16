import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/core/push/push_service.dart';
import 'package:flutter_app/core/router/app_router.dart';
import 'package:flutter_app/core/security/biometric_gate.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los datos de locale para formateo de fechas/moneda en es_CL.
  await initializeDateFormatting('es_CL');
  // Firebase (push). Best-effort: si falla la init, la app sigue funcionando.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init falló: $e');
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Registra/elimina el token de push según el estado de autenticación.
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      final wasAuth = prev?.valueOrNull?.isAuthenticated ?? false;
      final isAuth = next.valueOrNull?.isAuthenticated ?? false;
      if (isAuth && !wasAuth) {
        ref.read(dioProvider.future).then(
            (dio) => ref.read(pushServiceProvider).registerToken(dio));
      } else if (!isAuth && wasAuth) {
        ref.read(dioProvider.future).then(
            (dio) => ref.read(pushServiceProvider).unregister(dio));
      }
    });

    return MaterialApp.router(
      title: 'FinPareja',
      theme: AppTheme.light(),
      routerConfig: router,
      // Capa de bloqueo biométrico (opt-in) por encima de toda la app.
      builder: (context, child) =>
          BiometricGate(child: child ?? const SizedBox.shrink()),
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'CL'),
      supportedLocales: const [Locale('es', 'CL'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
