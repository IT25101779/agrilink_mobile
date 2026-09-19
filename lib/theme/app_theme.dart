import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pages slide in from the side with a soft parallax (instead of the stock zoom).
const PageTransitionsTheme kPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
);

/// Sinhala and Tamil letters are not in Plus Jakarta Sans, so every text style
/// falls back to the bundled Noto fonts (see pubspec.yaml). Without this those
/// scripts render as boxes or badly-shaped letters.
const List<String> kScriptFallback = ["NotoSansSinhala", "NotoSansTamil"];

TextStyle _jakarta({double? fontSize, FontWeight? fontWeight, Color? color, double? height, double? letterSpacing}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  ).copyWith(fontFamilyFallback: kScriptFallback);
}

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
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(fontFamilyFallback: kScriptFallback);

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
        headlineMedium: _jakarta(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
        titleLarge: _jakarta(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleMedium: _jakarta(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyLarge: _jakarta(fontSize: 15, color: AppColors.ink, height: 1.4),
        bodyMedium: _jakarta(fontSize: 13.5, color: AppColors.inkMuted, height: 1.4),
        labelLarge: _jakarta(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _jakarta(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      // ---- design-system polish: smoother pages, friendlier dialogs and sheets ----
      pageTransitionsTheme: kPageTransitions,
      dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      listTileTheme: ListTileThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: _jakarta(color: AppColors.inkMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: _jakarta(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: _jakarta(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          textStyle: _jakarta(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.forestLight,
        labelStyle: _jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.forest),
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
        contentTextStyle: _jakarta(color: Colors.white, fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      fontFamilyFallback: kScriptFallback,
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
        headlineMedium: _jakarta(fontSize: 26, fontWeight: FontWeight.w700, color: AppColorsDark.ink, letterSpacing: -0.5),
        titleLarge: _jakarta(fontSize: 19, fontWeight: FontWeight.w700, color: AppColorsDark.ink),
        titleMedium: _jakarta(fontSize: 16, fontWeight: FontWeight.w600, color: AppColorsDark.ink),
        bodyLarge: _jakarta(fontSize: 15, color: AppColorsDark.ink, height: 1.4),
        bodyMedium: _jakarta(fontSize: 13.5, color: AppColorsDark.inkMuted, height: 1.4),
        labelLarge: _jakarta(fontSize: 14, fontWeight: FontWeight.w600, color: AppColorsDark.ink),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forestDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _jakarta(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      // ---- design-system polish: smoother pages, friendlier dialogs and sheets ----
      pageTransitionsTheme: kPageTransitions,
      dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      listTileTheme: ListTileThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColorsDark.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColorsDark.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.forest, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger)),
        labelStyle: _jakarta(color: AppColorsDark.inkMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: _jakarta(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColorsDark.border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: _jakarta(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: _jakarta(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColorsDark.forestLight,
        labelStyle: _jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gold),
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
        contentTextStyle: _jakarta(color: AppColorsDark.ink, fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
