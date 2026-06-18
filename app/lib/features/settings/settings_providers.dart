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

// ─── Optional feature modules ────────────────────────────────────────────────
// Users can turn off modules they don't use so the UI stays focused. Core
// surfaces (Home, Groups, Activity, Profile) are always on; only these extras
// are toggleable.
enum AppModule { tracker, khata, goals, reports }

extension AppModuleInfo on AppModule {
  String get key => name;

  String get label => switch (this) {
        AppModule.tracker => 'Personal Tracker',
        AppModule.khata => 'Khata Book',
        AppModule.goals => 'Goals',
        AppModule.reports => 'Reports',
      };

  String get subtitle => switch (this) {
        AppModule.tracker => 'Daily personal expense tracking',
        AppModule.khata => 'Personal loans, dues & lending',
        AppModule.goals => 'Savings goals and targets',
        AppModule.reports => 'Monthly insights & breakdowns',
      };

  IconData get icon => switch (this) {
        AppModule.tracker => Icons.track_changes_rounded,
        AppModule.khata => Icons.account_balance_wallet_rounded,
        AppModule.goals => Icons.flag_rounded,
        AppModule.reports => Icons.insights_rounded,
      };
}

/// The set of currently-enabled modules. Persists the *disabled* keys in Hive
/// so the default (nothing stored) is "all enabled", and any module added in a
/// future build is enabled by default too.
class EnabledModulesNotifier extends StateNotifier<Set<AppModule>> {
  EnabledModulesNotifier() : super(_load());

  static const _key = 'disabledModules';

  static Set<AppModule> _load() {
    final box = Hive.box(HiveSetup.settingsBox);
    final raw = (box.get(_key) as String?) ?? '';
    final disabled = raw.split(',').where((s) => s.isNotEmpty).toSet();
    return AppModule.values.where((m) => !disabled.contains(m.key)).toSet();
  }

  bool isEnabled(AppModule m) => state.contains(m);

  Future<void> setEnabled(AppModule m, bool enabled) async {
    final next = {...state};
    if (enabled) {
      next.add(m);
    } else {
      next.remove(m);
    }
    state = next;
    final disabled =
        AppModule.values.where((x) => !next.contains(x)).map((x) => x.key).join(',');
    await Hive.box(HiveSetup.settingsBox).put(_key, disabled);
  }
}

final enabledModulesProvider =
    StateNotifierProvider<EnabledModulesNotifier, Set<AppModule>>(
        (ref) => EnabledModulesNotifier());
