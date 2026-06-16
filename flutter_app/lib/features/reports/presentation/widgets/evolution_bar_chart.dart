import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/core/utils/date_formatter.dart';
import 'package:flutter_app/features/reports/domain/entities/evolution_point.dart';

/// Gráfico de barras agrupadas: ingresos (verde) vs gastos (rojo) por mes.
class EvolutionBarChart extends StatelessWidget {
  const EvolutionBarChart({super.key, required this.points});

  final List<EvolutionPoint> points;

  static const _incomeColor = AppColors.success;
  static const _expenseColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(0, (max, p) {
      final localMax = p.ingresos > p.gastos ? p.ingresos : p.gastos;
      return localMax > max ? localMax : max;
    });
    // Margen superior del 20% para que la barra más alta no toque el techo.
    final maxY = maxValue == 0 ? 100.0 : maxValue * 1.2;

    // Piso visual: una barra con valor > 0 nunca se dibuja más corta que esto,
    // así los montos pequeños siguen siendo visibles. El monto REAL se conserva
    // y es el que se muestra en el tooltip (ver getTooltipItem).
    final minVisible = maxValue == 0 ? 0.0 : maxY * 0.05;
    double rodY(double v) => v <= 0 ? 0 : (v < minVisible ? minVisible : v);

    return Column(
      children: [
        // Leyenda
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: _incomeColor, label: 'Ingresos'),
            SizedBox(width: 20),
            _LegendDot(color: _expenseColor, label: 'Gastos'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    // Mostramos el monto REAL (no el ajustado por el piso visual).
                    final p = points[group.x];
                    final real = rodIndex == 0 ? p.ingresos : p.gastos;
                    final label = rodIndex == 0 ? 'Ingresos' : 'Gastos';
                    return BarTooltipItem(
                      '$label\n${CurrencyFormatter.format(real)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormatter.monthName(points[i].mes)
                              .substring(0, 3),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: rodY(points[i].ingresos),
                        color: _incomeColor,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: _incomeColor.withAlpha(20),
                        ),
                      ),
                      BarChartRodData(
                        toY: rodY(points[i].gastos),
                        color: _expenseColor,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: _expenseColor.withAlpha(20),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
