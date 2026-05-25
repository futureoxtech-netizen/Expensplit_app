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
      cardTheme: CardThemeData(
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
        isDark: false,
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
      chipTheme: _chipTheme(
        bg: AppColors.lightSurface,
        text: AppColors.lightOnSurface,
        border: AppColors.lightBorder,
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
      cardTheme: CardThemeData(
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
        isDark: true,
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
      chipTheme: _chipTheme(
        bg: AppColors.darkSurface,
        text: AppColors.darkOnSurface,
        border: AppColors.darkBorder,
      ),
    );
  }

  /// Shared ChoiceChip/FilterChip styling. Selected chips use the brand
  /// primary as the fill with white text+icon for high contrast, instead
  /// of Material's default low-contrast tinted background.
  static ChipThemeData _chipTheme({
    required Color bg,
    required Color text,
    required Color border,
  }) {
    return ChipThemeData(
      backgroundColor: bg,
      selectedColor: AppColors.primary,
      disabledColor: bg,
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: text,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: Colors.white,
      ),
      checkmarkColor: Colors.white,
      side: BorderSide(color: border, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      showCheckmark: true,
      iconTheme: const IconThemeData(size: 16, color: Colors.white),
    );
  }

  static InputDecorationTheme _inputDecoration({
    required Color fill,
    required Color border,
    required Color text,
    required Color hint,
    required bool isDark,
  }) {
    final radius = BorderRadius.circular(14);
    // Light mode: darken the border so it stands out against the white fill.
    // Dark mode:  lighten the border so it stands out against the dark fill.
    // 0.30 darkening / 0.28 lightening gives a clearly visible but not harsh stroke.
    final visibleBorder = isDark
        ? Color.lerp(border, Colors.white, 0.28)!
        : Color.lerp(border, Colors.black, 0.30)!;
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: GoogleFonts.inter(color: hint, fontSize: 14),
      labelStyle: GoogleFonts.inter(color: hint, fontSize: 13, fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: visibleBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: visibleBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
    );
  }
}
