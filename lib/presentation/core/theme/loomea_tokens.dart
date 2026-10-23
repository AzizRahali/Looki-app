import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

/// Looki 2027 design tokens — cream + navy + sky palette.
abstract final class LoomeaTokens {
  static const double screenPaddingH = 24;
  static const double gapSm = 8;
  static const double gapMd = 16;
  static const double gapLg = 24;
  static const double gapXl = 32;

  // ── Radius ────────────────────────────────────────────────────────────────
  static const double radiusInput = 14;   // T.rInput
  static const double radiusCard = 20;    // T.rCard
  static const double radiusHero = 24;    // T.rHero
  static const double radiusPill = 9999;  // T.rPill

  // ── Sizing ────────────────────────────────────────────────────────────────
  static const double inputHeight = 52;
  static const double buttonHeight = 50;

  // ── Typography scale ──────────────────────────────────────────────────────
  static const double titleScreen = 24;
  static const double headlineHero = 28;
  static const double body = 15;
  static const double caption = 13;
  static const double overline = 10;  // eyebrow — JetBrains Mono, uppercase, 0.14em tracking

  // ── Eyebrow text style (JetBrains Mono) ──────────────────────────────────
  static TextStyle get eyebrow => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.14 * 10,
        color: AppColors.textSecondary,
      );

  static TextStyle eyebrowWith({Color? color, double? fontSize}) =>
      eyebrow.copyWith(color: color, fontSize: fontSize);

  // ── Display text style (Instrument Serif — editorial headlines) ───────────
  static TextStyle get displaySerif => GoogleFonts.instrumentSerif(
        fontSize: 44,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        height: 1.05,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
      );

  // ── Borders ───────────────────────────────────────────────────────────────
  static Color divider(BuildContext context) => AppColors.divider;
  static const Color socialBorder = AppColors.border;

  // ── Shadows ───────────────────────────────────────────────────────────────
  // Card: soft navy-tinted shadow (T.borderInk at ~5%)
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0D0A2A6B), // navy 5%
          blurRadius: 20,
          offset: Offset(0, 4),
          spreadRadius: -2,
        ),
      ];

  // Stacked card dramatic shadow (onboarding collage)
  static List<BoxShadow> get stackedCardShadow => const [
        BoxShadow(
          color: Color(0x2E0A2A6B), // navy 18%
          blurRadius: 36,
          offset: Offset(0, 18),
        ),
      ];

  // Floating chip shadow
  static List<BoxShadow> get floatingShadow => const [
        BoxShadow(
          color: Color(0x240A2A6B), // navy 14%
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ];
}
