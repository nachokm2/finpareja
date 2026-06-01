import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/color_parser.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/features/reports/domain/entities/category_breakdown.dart';

/// Donut chart de gastos por categoría con leyenda.
/// El centro muestra el total del mes.
class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({super.key, required this.breakdown});

  final CategoryBreakdown breakdown;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  // Paleta de respaldo cuando la categoría no trae color desde el backend.
  static const _palette = [
    Color(0xFF4C4DDC),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
  ];

  Color _colorFor(CategorySlice slice, int index) {
    if (slice.color != null && slice.color!.isNotEmpty) {
      return ColorParser.fromHex(slice.color);
    }
    return _palette[index % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final slices = widget.breakdown.slices;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 64,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response?.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response!.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: [
                    for (var i = 0; i < slices.length; i++)
                      _section(slices[i], i, i == _touchedIndex),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    CurrencyFormatter.compact(widget.breakdown.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Leyenda
        ...List.generate(slices.length, (i) {
          final slice = slices[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _colorFor(slice, i),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(slice.icono ?? '', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    slice.nombre,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${slice.porcentaje.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Text(
                  CurrencyFormatter.format(slice.total),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  PieChartSectionData _section(
    CategorySlice slice,
    int index,
    bool isTouched,
  ) {
    return PieChartSectionData(
      value: slice.total,
      color: _colorFor(slice, index),
      radius: isTouched ? 28 : 22,
      showTitle: isTouched,
      title: '${slice.porcentaje.toStringAsFixed(0)}%',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}
