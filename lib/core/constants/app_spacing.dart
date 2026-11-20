import 'package:flutter/material.dart';

/// Consistent spacing scale for the app.
class AppSpacing {
  AppSpacing._();

  // ─── Spacing Scale ────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double massive = 48.0;

  // ─── Border Radius ────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusRound = 100.0;

  // ─── Padding Presets ──────────────────────────────────
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );

  static const EdgeInsets paddingCard = EdgeInsets.all(16.0);

  static const EdgeInsets paddingCardCompact = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );

  // ─── Icon Sizes ───────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double iconHuge = 48.0;

  // ─── Glass Properties ─────────────────────────────────
  static const double glassBlur = 20.0;
  static const double glassBorderWidth = 1.0;
}
