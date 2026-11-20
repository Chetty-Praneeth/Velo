import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// An animated gradient progress bar that changes color based on spend percentage.
class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    super.key,
    required this.progress,
    this.height = 10,
    this.showLabel = false,
    this.labelText,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  /// Progress value (0.0 to 1.0).
  final double progress;
  final double height;
  final bool showLabel;
  final String? labelText;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final gradient = AppColors.budgetGradient(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labelText ?? 'Budget Used',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _progressColor(progress),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Stack(
          children: [
            // Background track
            Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            // Animated fill
            AnimatedFractionallySizedBox(
              duration: animationDuration,
              curve: Curves.easeOutCubic,
              widthFactor: clampedProgress,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: _progressColor(progress).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _progressColor(double percentage) {
    if (percentage <= 0.5) return AppColors.success;
    if (percentage <= 0.75) return AppColors.warning;
    return AppColors.danger;
  }
}

/// Animated width wrapper.
class AnimatedFractionallySizedBox extends StatelessWidget {
  const AnimatedFractionallySizedBox({
    super.key,
    required this.duration,
    required this.widthFactor,
    required this.child,
    this.curve = Curves.easeOut,
  });

  final Duration duration;
  final double widthFactor;
  final Widget child;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widthFactor),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return FractionallySizedBox(
          widthFactor: value,
          alignment: Alignment.centerLeft,
          child: child,
        );
      },
      child: child,
    );
  }
}
