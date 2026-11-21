import 'package:flutter/material.dart';

/// Looki 2027 palette — cream + navy + sky + gold.
class AppColors {
  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFAF7F2);    // T.bg — warm cream
  static const Color backgroundDeep = Color(0xFFF2EEE6); // T.bgDeep — deeper cream
  static const Color surface = Color(0xFFFFFFFF);        // cards, inputs
  static const Color surfaceAlt = Color(0xFFFBF8F3);     // T.surfaceAlt

  // ── Ink (navy) ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0A2A6B);        // T.ink / T.primary
  static const Color ink2 = Color(0xFF16367A);
  static const Color inkSoft = Color(0xFF3F558E);        // labels, secondary headings
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Accent (sky blue) ─────────────────────────────────────────────────────
  static const Color accent = Color(0xFF1E6FE8);         // T.accent
  static const Color onAccent = Color(0xFFFFFFFF);

  // ── Gold (reflex / premium) ───────────────────────────────────────────────
  static const Color gold = Color(0xFFD9B382);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0A2A6B);    // T.ink
  static const Color textSecondary = Color(0xFF8A92A8);  // T.muted
  static const Color textMutedSoft = Color(0xFFB8BDCB);  // T.mutedSoft

  // ── Borders / dividers ────────────────────────────────────────────────────
  static const Color border = Color(0xFFE7E3DA);          // T.border — warm cream tint
  static const Color borderInk = Color(0x1A0A2A6B);      // T.borderInk (10% navy)
  static const Color borderStrong = Color(0x2E0A2A6B);   // T.borderStrong (18% navy)
  static const Color divider = Color(0xFFECE7DC);         // T.divider

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFF3B30);
  static const Color errorBg = Color(0xFFFDECEB);
  static const Color success = Color(0xFF34C759);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color successDark = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9500);
  static const Color warningBg = Color(0xFFFFF3E0);

  // ── Reliability tiers ─────────────────────────────────────────────────────
  static const Color trusted = Color(0xFF22C55E);
  static const Color normal = Color(0xFF3B82F6);
  static const Color risky = Color(0xFFF59E0B);
  static const Color restricted = Color(0xFFEF4444);

  // ── Legacy aliases ────────────────────────────────────────────────────────
  static const Color inputBackground = surface;
  static const Color onPrimaryLegacy = onPrimary;
  static const Color errorContainer = Color(0xFFFF8B9A); // keep for any banner
}

ThemeData buildLoomeaTheme({required TextTheme textTheme}) {
  final baseTextTheme = textTheme.apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  return ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: const Color(0xFFD9E4F8),
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      secondaryContainer: const Color(0xFFD6E4FB),
      tertiary: AppColors.gold,
      onTertiary: AppColors.textPrimary,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorBg,
    ),
    textTheme: baseTextTheme.copyWith(
      // Display — Instrument Serif moments (set per-widget)
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -0.035 * 44,
        color: AppColors.textPrimary,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 15,
        color: AppColors.onPrimary,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.14 * 10,
        color: AppColors.textSecondary,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.textPrimary,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: AppColors.inkSoft,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size.fromHeight(50),
        shape: const StadiumBorder(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01 * 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size.fromHeight(50),
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.surface,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.background,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    cardColor: AppColors.surface,
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.backgroundDeep,
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
      side: const BorderSide(color: AppColors.border),
    ),
    useMaterial3: true,
  );
}
