import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';

/// Texto de monto que anima entre valores con un contador (tween).
/// Da la sensación de "calidad" al cambiar de Vista Yo ↔ Pareja o al refrescar.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.compact = false,
    this.duration = const Duration(milliseconds: 600),
  });

  final double value;
  final TextStyle style;
  final bool compact;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        final text = compact
            ? CurrencyFormatter.compact(animated)
            : CurrencyFormatter.format(animated);
        return Text(text, style: style);
      },
    );
  }
}
