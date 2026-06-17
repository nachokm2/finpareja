import 'package:flutter/material.dart';
import 'package:flutter_app/core/config/env_config.dart';
import 'package:flutter_app/core/navigation/main_shell.dart';
import 'package:flutter_app/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:flutter_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter_app/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_app/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_app/features/auth/presentation/pages/splash_page.dart';
import 'package:flutter_app/features/budgets/presentation/pages/budgets_page.dart';
import 'package:flutter_app/features/cards/presentation/pages/cards_page.dart';
import 'package:flutter_app/features/couple/presentation/pages/couple_page.dart';
import 'package:flutter_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter_app/features/debts/presentation/pages/debts_page.dart';
import 'package:flutter_app/features/home/presentation/pages/home_page.dart';
import 'package:flutter_app/features/investments/presentation/pages/investments_page.dart';
import 'package:flutter_app/features/legal/presentation/pages/privacy_policy_page.dart';
import 'package:flutter_app/features/recurring/presentation/pages/recurring_page.dart';
import 'package:flutter_app/features/reports/presentation/pages/reports_page.dart';
import 'package:flutter_app/features/savings/presentation/pages/savings_page.dart';
import 'package:flutter_app/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:flutter_app/features/transactions/presentation/pages/transactions_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Rutas centralizadas. Usar estas constantes en lugar de strings literales.
abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/recuperar-password';

  // Pestañas del shell principal
  static const dashboard = '/dashboard';
  static const transactions = '/transacciones';
  static const budgets = '/presupuestos';
  static const savings = '/metas';

  // Rutas que se abren sobre el shell
  static const addTransaction = '/transacciones/nueva';
  static const profile = '/perfil';
  static const reports = '/reportes';
  static const debts = '/deudas';
  static const investments = '/inversiones';
  static const couple = '/pareja';
  static const privacy = '/privacidad';
  static const recurring = '/recurrentes';
  static const cards = '/tarjetas';
}

/// Puente entre Riverpod y GoRouter.
///
/// GoRouter necesita un [Listenable] para saber cuándo re-evaluar
/// sus redirects. Este [ChangeNotifier] escucha [authNotifierProvider]
/// y notifica a GoRouter cada vez que el estado de auth cambia.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = _AuthChangeNotifier(ref);
  ref.onDispose(authChangeNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: EnvConfig.isDevelopment,
    refreshListenable: authChangeNotifier,
    routes: [
      // ── Rutas sin shell (auth) ──────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),

      // ── Rutas full-screen sobre el shell ────────────────────────────
      GoRoute(
        path: AppRoutes.addTransaction,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AddTransactionPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ReportsPage(),
      ),
      GoRoute(
        path: AppRoutes.debts,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const DebtsPage(),
      ),
      GoRoute(
        path: AppRoutes.investments,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const InvestmentsPage(),
      ),
      GoRoute(
        path: AppRoutes.couple,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CouplePage(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.recurring,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const RecurringPage(),
      ),
      GoRoute(
        path: AppRoutes.cards,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CardsPage(),
      ),

      // ── Shell con bottom navigation (4 ramas) ───────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (_, __) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (_, __) => const TransactionsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budgets,
                builder: (_, __) => const BudgetsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.savings,
                builder: (_, __) => const SavingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],

    /// Lógica de redirección basada en estado de auth.
    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      return authAsync.when(
        loading: () =>
            location == AppRoutes.splash ? null : AppRoutes.splash,
        error: (_, __) =>
            location == AppRoutes.login ? null : AppRoutes.login,
        data: (authState) {
          final isOnAuthRoute = location == AppRoutes.login ||
              location == AppRoutes.register ||
              location == AppRoutes.forgotPassword;
          final isOnSplash = location == AppRoutes.splash;

          if (authState.isAuthenticated) {
            // Autenticado en splash/login/register → ir al dashboard
            return (isOnAuthRoute || isOnSplash)
                ? AppRoutes.dashboard
                : null;
          } else {
            // No autenticado fuera de auth → ir a login
            return isOnAuthRoute ? null : AppRoutes.login;
          }
        },
      );
    },
  );
});
