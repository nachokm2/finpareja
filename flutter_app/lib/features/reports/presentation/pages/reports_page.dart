import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/features/reports/domain/entities/net_worth.dart';
import 'package:flutter_app/features/reports/presentation/providers/reports_provider.dart';
import 'package:flutter_app/features/reports/presentation/widgets/category_pie_chart.dart';
import 'package:flutter_app/features/reports/presentation/widgets/evolution_bar_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider);
    final evolutionAsync = ref.watch(evolutionProvider);
    final netWorthAsync = ref.watch(netWorthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reportes')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryBreakdownProvider);
          ref.invalidate(evolutionProvider);
          ref.invalidate(netWorthProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Patrimonio neto ──────────────────────────────────────
            netWorthAsync.when(
              loading: () => const _CardSkeleton(height: 90),
              error: (_, __) =>
                  const _CardError(message: 'No se pudo cargar el patrimonio'),
              data: (nw) => _NetWorthCard(netWorth: nw),
            ),
            const SizedBox(height: 16),

            // ── Gastos por categoría (donut) ─────────────────────────
            _ReportCard(
              title: 'Gastos por categoría',
              subtitle: 'Mes actual',
              child: breakdownAsync.when(
                loading: () => const _ChartLoading(),
                error: (e, _) => _ChartError(error: e),
                data: (breakdown) => breakdown.isEmpty
                    ? const _EmptyChart(
                        emoji: '🍩',
                        message: 'Sin gastos registrados este mes',
                      )
                    : CategoryPieChart(breakdown: breakdown),
              ),
            ),
            const SizedBox(height: 16),

            // ── Evolución ingresos vs gastos (barras) ────────────────
            _ReportCard(
              title: 'Ingresos vs Gastos',
              subtitle: 'Últimos 6 meses',
              child: evolutionAsync.when(
                loading: () => const _ChartLoading(),
                error: (e, _) => _ChartError(error: e),
                data: (points) => points.isEmpty
                    ? const _EmptyChart(
                        emoji: '📊',
                        message: 'Aún no hay historial suficiente',
                      )
                    : EvolutionBarChart(points: points),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Patrimonio neto ───────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.netWorth});
  final NetWorth netWorth;

  @override
  Widget build(BuildContext context) {
    final isPositive = netWorth.patrimonioNeto >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(210)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patrimonio neto acumulado',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(netWorth.patrimonioNeto),
            style: TextStyle(
              color: isPositive ? Colors.white : const Color(0xFFFFD2D2),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresos: ${CurrencyFormatter.compact(netWorth.ingresosAcumulados)}  ·  '
            'Gastos: ${CurrencyFormatter.compact(netWorth.gastosAcumulados)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Contenedor genérico de reporte ──────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          Text(subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Estados auxiliares ──────────────────────────────────────────────────────

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ChartError extends StatelessWidget {
  const _ChartError({required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 120,
        child: Center(
          child: Text('No se pudo cargar: $error',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center),
        ),
      );
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.emoji, required this.message});
  final String emoji;
  final String message;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 140,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(message,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(60),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
        ),
      );
}

class _CardError extends StatelessWidget {
  const _CardError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: Text(message)),
      );
}
