import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF6C5CE7);
  static const primaryDark = Color(0xFF4E3FCB);
  static const accent = Color(0xFF00B894);
  static const danger = Color(0xFFFF6B6B);
  static const warn = Color(0xFFFFC857);

  // Light
  static const lightBg = Color(0xFFF7F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF111126);
  static const lightMuted = Color(0xFF6B6B7A);
  static const lightBorder = Color(0xFFE8E8F0);

  // Dark
  static const darkBg = Color(0xFF0B0B12);
  static const darkSurface = Color(0xFF15151E);
  static const darkElevated = Color(0xFF1C1C28);
  static const darkOnSurface = Color(0xFFE9E9F2);
  static const darkMuted = Color(0xFF8C8CA1);
  static const darkBorder = Color(0xFF24243A);

  // Gradients
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF00B894)],
  );
  static const auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E7CFF), Color(0xFF44C4FF), Color(0xFF00E5A8)],
  );
  static const dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43)],
  );
}
