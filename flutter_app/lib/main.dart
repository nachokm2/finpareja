import 'package:flutter/material.dart';
import 'package:flutter_app/core/router/app_router.dart';
import 'package:flutter_app/core/security/biometric_gate.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los datos de locale para formateo de fechas/moneda en es_CL.
  await initializeDateFormatting('es_CL');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FinPareja',
      theme: AppTheme.light(),
      routerConfig: router,
      // Capa de bloqueo biométrico (opt-in) por encima de toda la app.
      builder: (context, child) => BiometricGate(child: child ?? const SizedBox.shrink()),
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
