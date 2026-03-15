import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class ReverTheme {
  // ── Brand colours – light theme ──────────────────────────────────────────
  static const Color primary       = Color(0xFF0D0D0D);
  static const Color accent        = Color(0xFF1790FF);   // REVER blue
  static const Color accentLight   = Color(0xFFE8F4FF);   // light blue tint
  static const Color surface       = Color(0xFFF5F7FA);   // main background
  static const Color cardBg        = Color(0xFFFFFFFF);   // cards / nav / input
  static const Color cardBgRaised  = Color(0xFFF0F2F6);   // slightly raised surface
  static const Color bubbleUser    = Color(0xFF1790FF);
  static const Color bubbleBot     = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF0D0D0D);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color divider       = Color(0xFFE8E8EF);
  static const Color success       = Color(0xFF30D158);
  static const Color warning       = Color(0xFFFF9F0A);
  static const Color error         = Color(0xFFFF3B30);

  // ── Typography – Inter ───────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.8,
      );

  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get bodyRegular => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.4,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        letterSpacing: 0.1,
      );

  // ── Radius ───────────────────────────────────────────────────────────────
  static const double radiusSmall  = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge  = 20.0;
  static const double radiusFull   = 99.0;

  // ── Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.18),
          blurRadius: 20,
          spreadRadius: -4,
        ),
      ];
}
