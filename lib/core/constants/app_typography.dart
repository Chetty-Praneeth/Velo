import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography presets using Google Fonts Inter.
class AppTypography {
  AppTypography._();

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ─── Display ──────────────────────────────────────────
  /// 36px Bold — Hero balance amounts
  static TextStyle displayLarge = _inter(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// 32px Bold — Primary financial figures
  static TextStyle display = _inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// 28px SemiBold — Secondary financial figures
  static TextStyle displaySmall = _inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // ─── Headline ─────────────────────────────────────────
  /// 24px SemiBold — Section headers
  static TextStyle headline = _inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// 20px SemiBold — Card headers
  static TextStyle headlineSmall = _inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ─── Title ────────────────────────────────────────────
  /// 18px Medium — Card titles
  static TextStyle title = _inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// 16px Medium — Subtitles
  static TextStyle titleSmall = _inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // ─── Body ─────────────────────────────────────────────
  /// 14px Regular — Standard body text
  static TextStyle body = _inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  /// 14px Medium — Emphasized body
  static TextStyle bodyMedium = _inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// 13px Regular — Compact body
  static TextStyle bodySmall = _inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ─── Caption ──────────────────────────────────────────
  /// 12px Regular — Timestamps, labels
  static TextStyle caption = _inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  /// 11px Medium — Tags, badges
  static TextStyle captionSmall = _inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    height: 1.3,
    letterSpacing: 0.5,
  );

  // ─── Button ───────────────────────────────────────────
  /// 16px SemiBold — Primary buttons
  static TextStyle button = _inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.3,
  );

  /// 14px Medium — Secondary buttons
  static TextStyle buttonSmall = _inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.0,
  );

  // ─── Numeric ──────────────────────────────────────────
  /// 48px Bold — Large financial numbers (dashboard hero)
  static TextStyle numericHero = _inter(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1.0,
  );

  /// 24px SemiBold — Medium numbers
  static TextStyle numericLarge = _inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// 18px Medium — Small numbers
  static TextStyle numericMedium = _inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}
