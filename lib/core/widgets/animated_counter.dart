import 'package:flutter/material.dart';
import '../constants/app_typography.dart';
import '../utils/currency_formatter.dart';

/// Smoothly animated number counter for balance displays.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix = '₹',
    this.duration = const Duration(milliseconds: 600),
    this.isCurrency = true,
  });

  final double value;
  final TextStyle? style;
  final String prefix;
  final Duration duration;
  final bool isCurrency;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final text = isCurrency
            ? CurrencyFormatter.format(animatedValue)
            : animatedValue.toStringAsFixed(0);
        return Text(
          text,
          style: style ?? AppTypography.numericHero,
        );
      },
    );
  }
}
