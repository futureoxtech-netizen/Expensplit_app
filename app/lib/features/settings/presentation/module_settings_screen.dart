import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../settings_providers.dart';

/// Lets the user turn optional modules on/off so the navigation and home
/// surfaces only show what they actually use. Everything is on by default.
class ModuleSettingsScreen extends ConsumerWidget {
  const ModuleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(enabledModulesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modules', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'Choose which features appear in the app. Turn off anything you '
            "don't use to keep your navigation clean — your data is kept and "
            'reappears if you switch a module back on.',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          for (final m in AppModule.values)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                value: enabled.contains(m),
                onChanged: (v) =>
                    ref.read(enabledModulesProvider.notifier).setEnabled(m, v),
                secondary: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(m.icon, color: AppColors.primary, size: 22),
                ),
                title: Text(m.label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                subtitle: Text(m.subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.55))),
              ),
            ),
        ],
      ),
    );
  }
}
