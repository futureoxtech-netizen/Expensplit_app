import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/storage/hive_setup.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_load());

  static ThemeMode _load() {
    final box = Hive.box(HiveSetup.settingsBox);
    final raw = box.get('themeMode') as String?;
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final box = Hive.box(HiveSetup.settingsBox);
    await box.put(
      'themeMode',
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      },
    );
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());
