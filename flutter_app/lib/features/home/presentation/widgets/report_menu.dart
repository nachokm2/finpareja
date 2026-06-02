import 'package:flutter/material.dart';

import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/features/home/domain/entities/user_role.dart';

class ReportDefinition {
  const ReportDefinition({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.roles,
    required this.accentColor,
    this.reportUrl,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<UserRole> roles;
  final Color accentColor;

  /// null = reporte pendiente de configurar en el backend.
  final String? reportUrl;
}

const _kReports = <ReportDefinition>[
  ReportDefinition(
    title: 'Campañas digitales',
    subtitle: 'Inversión y leads activos',
    icon: Icons.campaign,
    roles: [UserRole.marketing],
    accentColor: Color(0xFF4C4DDC),
  ),
  ReportDefinition(
    title: 'Embudo de inscripción',
    subtitle: 'Marketing y coordinación',
    icon: Icons.trending_up,
    roles: [UserRole.marketing, UserRole.coordinador],
    accentColor: Color(0xFFC8C8F4),
  ),
  ReportDefinition(
    title: 'Seguimiento de asesores',
    subtitle: 'Rendimiento semanal por campus',
    icon: Icons.assignment_ind,
    roles: [UserRole.coordinador],
    accentColor: Color(0xFF4C4DDC),
  ),
  ReportDefinition(
    title: 'Agenda de campo',
    subtitle: 'Visitas, ferias y convenios',
    icon: Icons.map,
    roles: [UserRole.coordinador],
    accentColor: Color(0xFFC8C8F4),
  ),
  ReportDefinition(
    title: 'Resumen directivo',
    subtitle: 'Indicadores estratégicos',
    icon: Icons.insights,
    roles: [UserRole.director],
    accentColor: Color(0xFF4C4DDC),
  ),
  ReportDefinition(
    title: 'Análisis de campañas',
    subtitle: 'Efectividad publicitaria',
    icon: Icons.receipt_long,
    roles: [UserRole.director],
    accentColor: Color(0xFFC8C8F4),
  ),
];

List<ReportDefinition> reportsForRole(UserRole role) =>
    _kReports.where((r) => r.roles.contains(role)).toList();

class ReportMenu extends StatelessWidget {
  const ReportMenu({super.key, required this.role});

  final UserRole role;

  void _onTap(BuildContext context, ReportDefinition report) {
    // Los reportes embebidos (Looker Studio) se retiraron al migrar a FinPareja.
    // El módulo de reportes financieros vive en /reportes (fl_chart).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte en configuración')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = reportsForRole(role);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(role.icon, color: role.accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Reportes para ${role.label}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reports.isEmpty)
            Text(
              'No hay reportes asignados para este rol.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54),
            )
          else
            Column(
              children: reports
                  .map(
                    (report) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReportCard(
                        report: report,
                        onTap: () => _onTap(context, report),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});

  final ReportDefinition report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: report.accentColor.withAlpha(15),
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: report.accentColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(report.icon, color: report.accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(
                report.reportUrl != null
                    ? Icons.arrow_forward_ios
                    : Icons.lock_outline,
                size: 16,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
