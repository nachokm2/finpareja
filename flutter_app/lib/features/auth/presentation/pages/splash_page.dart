import 'package:flutter/material.dart';

import 'package:flutter_app/core/theme/app_theme.dart';

/// Pantalla de inicio que se muestra mientras el [AuthNotifier]
/// verifica el estado de la sesión (token local + perfil remoto).
/// GoRouter redirige automáticamente desde aquí una vez que
/// el estado de auth es conocido.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FinPareja',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Finanzas en pareja',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 56),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
