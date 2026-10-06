import 'package:flutter/material.dart';

/// MAMO design tokens — diturunkan dari Figma (Mobile + Admin Website).
/// Primary: #3B5BFF (login admin gradient) / #4F46E5 (aksen sidebar) / #6366F1 brand.
class MamoColors {
  MamoColors._();

  static const primary = Color(0xFF3B5BFF);
  static const primaryDark = Color(0xFF2A3FCC);
  static const brandIndigo = Color(0xFF6366F1);
  static const brandPurple = Color(0xFF8B5CF6);

  static const bg = Color(0xFFF7FBFB);
  static const surface = Colors.white;
  static const cardBorder = Color(0xFFEDF1F5);

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);

  static const success = Color(0xFF22C55E);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFFACC15);
  static const warningBg = Color(0xFFFEF9C3);
  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0xFFFEE2E2);
  static const infoBg = Color(0xFFDBEAFE);
  static const purple = Color(0xFFE879F9);
  static const purpleBg = Color(0xFFFAE8FF);

  static const navy = Color(0xFF0F1B3D);

  /// Gradien logo/kartu login
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2A78), Color(0xFF3B5BFF)],
  );
}

class MamoRadius {
  MamoRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

class MamoSpacing {
  MamoSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class MamoTheme {
  MamoTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MamoColors.primary,
        primary: MamoColors.primary,
        surface: MamoColors.surface,
      ),
      scaffoldBackgroundColor: MamoColors.bg,
      fontFamily: 'Inter',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: MamoColors.surface,
        foregroundColor: MamoColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: MamoColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: MamoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MamoRadius.lg),
          side: const BorderSide(color: MamoColors.cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MamoColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MamoRadius.md),
          borderSide: const BorderSide(color: MamoColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MamoRadius.md),
          borderSide: const BorderSide(color: MamoColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MamoRadius.md),
          borderSide: const BorderSide(color: MamoColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: MamoColors.textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MamoColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MamoRadius.md)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MamoColors.primary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: MamoColors.cardBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MamoRadius.md)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: MamoColors.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: MamoColors.surface,
        indicatorColor: MamoColors.infoBg,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? MamoColors.primary : MamoColors.textMuted,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 22,
              color: states.contains(WidgetState.selected) ? MamoColors.primary : MamoColors.textMuted,
            )),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: MamoColors.surface,
        side: const BorderSide(color: MamoColors.cardBorder),
        labelStyle: const TextStyle(fontSize: 12, color: MamoColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MamoRadius.pill)),
      ),
      dividerTheme: const DividerThemeData(color: MamoColors.cardBorder, thickness: 1, space: 1),
    );
  }
}
