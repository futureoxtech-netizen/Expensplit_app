import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color color) => GoogleFonts.interTextTheme().apply(
        bodyColor: color,
        displayColor: color,
      );

  static ThemeData light() {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        error: AppColors.danger,
      ),
      textTheme: _textTheme(AppColors.lightOnSurface),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      inputDecorationTheme: _inputDecoration(
        fill: AppColors.lightSurface,
        border: AppColors.lightBorder,
        text: AppColors.lightOnSurface,
        hint: AppColors.lightMuted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorder, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        error: AppColors.danger,
      ),
      textTheme: _textTheme(AppColors.darkOnSurface),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      inputDecorationTheme: _inputDecoration(
        fill: AppColors.darkSurface,
        border: AppColors.darkBorder,
        text: AppColors.darkOnSurface,
        hint: AppColors.darkMuted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecoration({
    required Color fill,
    required Color border,
    required Color text,
    required Color hint,
  }) {
    final radius = BorderRadius.circular(14);
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: GoogleFonts.inter(color: hint, fontSize: 14),
      labelStyle: GoogleFonts.inter(color: hint, fontSize: 13, fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }
}
