import 'package:flutter/material.dart';

/// Velo color palette — Minimalist Light Neobank theme.
class AppColors {
  AppColors._();

  // ─── Backgrounds ──────────────────────────────────────
  static const Color background = Color(0xFFF4F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF9FAFB);

  // ─── Neobank Borders & Fills ──────────────────────────
  static Color glassBackground = Colors.white;
  static Color glassBorder = const Color(0xFFEAEBED);
  static Color glassHighlight = const Color(0xFFF3F4F6);

  // ─── Accent ────────────────────────────────────────────
  static const Color accentPrimary = Color(0xFF111111); // solid black
  static const Color accentSecondary = Color(0xFF8CE600); // neon/lime green
  static const Color orangeAccent = Color(0xFFFF5A26); // orange accent from mockup
  static const Color accentGradientStart = Color(0xFF111111);
  static const Color accentGradientEnd = Color(0xFF222222);

  // ─── Semantic ──────────────────────────────────────────
  static const Color success = Color(0xFF8CE600); // neon green
  static const Color warning = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFFA3E3E); // warning red
  static const Color info = Color(0xFF2F80ED);

  // ─── Text ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111111);
  static Color textSecondary = const Color(0xFF6B7280);
  static Color textTertiary = const Color(0xFF9CA3AF);
  static Color textHint = const Color(0xFFD1D5DB);

  // ─── Category Backgrounds (Soft grey in light mode) ───
  static const Color categoryTransport = Color(0xFFEFF1F4);
  static const Color categoryFood = Color(0xFFEFF1F4);
  static const Color categoryEntertainment = Color(0xFFEFF1F4);
  static const Color categoryShopping = Color(0xFFEFF1F4);
  static const Color categoryBills = Color(0xFFEFF1F4);
  static const Color categoryHealth = Color(0xFFEFF1F4);
  static const Color categoryEducation = Color(0xFFEFF1F4);
  static const Color categoryMisc = Color(0xFFEFF1F4);

  // ─── Gradients ────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentGradientStart, accentGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF8CE600), Color(0xFFA3F200)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFA3E3E), Color(0xFFFF1744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient budgetGradient(double percentage) {
    if (percentage <= 0.5) {
      return const LinearGradient(
        colors: [Color(0xFF8CE600), Color(0xFFA3F200)],
      );
    } else if (percentage <= 0.75) {
      return const LinearGradient(
        colors: [Color(0xFFFFCA28), Color(0xFFFFB74D)],
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFFFA3E3E), Color(0xFFFF1744)],
      );
    }
  }
}
