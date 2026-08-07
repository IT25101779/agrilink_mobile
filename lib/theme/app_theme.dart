import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AgriLink AI design tokens. Change a value here and it ripples through
/// every screen that uses standard Material widgets and theme colors,
/// instead of each screen hardcoding its own hex values.
class AppColors {
  static const forest = Color(0xFF0B5D3B);
  static const forestDark = Color(0xFF073D27);
  static const forestLight = Color(0xFFEFF7F1);
  static const gold = Color(0xFFE0A72E);
  static const goldLight = Color(0xFFFFF6E3);
  static const indigo = Color(0xFF4F46E5);
  static const indigoLight = Color(0xFFEEF0FD);
  static const ink = Color(0xFF1F2A24);
  static const inkMuted = Color(0xFF6C7B72);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF7F9F6);
  static const border = Color(0xFFE1E9E3);
  static const danger = Color(0xFFDC4C4C);
  static const dangerLight = Color(0xFFFCEBEB);
}

/// Dark-mode counterparts for the few tokens that genuinely need to flip
/// (surfaces, backgrounds, borders, body text). Brand/accent colors
/// (forest, gold, indigo, danger) stay the same in both modes — they're
/// saturated enough to read clearly on light or dark backgrounds, the same
/// way most apps keep a colored badge or brand mark consistent across
/// themes rather than muting it.
class AppColorsDark {
  static const ink = Color(0xFFEDF2EE);
  static const inkMuted = Color(0xFF9CAAA2);
  static const surface = Color(0xFF1C231E);
  static const background = Color(0xFF12160F);
  static const border = Color(0xFF2B342C);
  static const forestLight = Color(0xFF1B3527);
  static const goldLight = Color(0xFF3A2F14);
  static const indigoLight = Color(0xFF262347);
  static const dangerLight = Color(0xFF3A2020);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.forest,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.forest,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme.copyWith(
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.ink, height: 1.4),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.inkMuted, height: 1.4),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.inkMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.forestLight,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.forest),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.forest,
        linearTrackColor: AppColors.border,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.forest : Colors.grey.shade400,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.forestLight : Colors.grey.shade200,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColorsDark.ink,
      displayColor: AppColorsDark.ink,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColorsDark.background,
      primaryColor: AppColors.forest,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.forest,
        secondary: AppColors.gold,
        surface: AppColorsDark.surface,
        error: AppColors.danger,
        onSurface: AppColorsDark.ink,
      ),
      textTheme: textTheme.copyWith(
        headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w700, color: AppColorsDark.ink, letterSpacing: -0.5),
        titleLarge: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w700, color: AppColorsDark.ink),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColorsDark.ink),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColorsDark.ink, height: 1.4),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColorsDark.inkMuted, height: 1.4),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColorsDark.ink),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forestDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColorsDark.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColorsDark.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColorsDark.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger)),
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColorsDark.inkMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColorsDark.border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColorsDark.forestLight,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gold),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: AppColorsDark.border, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.forest, linearTrackColor: AppColorsDark.border),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.forest : Colors.grey.shade600,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColorsDark.forestLight : Colors.grey.shade800,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsDark.surface,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: AppColorsDark.ink, fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
