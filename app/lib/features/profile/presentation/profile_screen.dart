import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/settings_providers.dart';

const _supportedCurrencies = <String, String>{
  'USD': r'US Dollar ($)',
  'EUR': 'Euro (€)',
  'GBP': 'British Pound (£)',
  'INR': 'Indian Rupee (₹)',
  'PKR': 'Pakistani Rupee (₨)',
  'JPY': 'Japanese Yen (¥)',
  'CAD': r'Canadian Dollar (C$)',
  'AUD': r'Australian Dollar (A$)',
};

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final mode = ref.watch(themeModeProvider);

    return GradientScaffold(
      padding: EdgeInsets.zero,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          Center(
            child: Column(
              children: [
                Avatar(name: user?.name ?? '?', imageUrl: user?.avatarUrl, size: 88),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? '—',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (user?.referralCode != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Referral · ${user!.referralCode}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Preferences'),
          _Tile(
            icon: Icons.palette_rounded,
            title: 'Theme',
            trailing: DropdownButton<ThemeMode>(
              value: mode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (v) {
                if (v != null) ref.read(themeModeProvider.notifier).set(v);
              },
            ),
          ),
          _Tile(
            icon: Icons.currency_exchange_rounded,
            title: 'Default currency',
            subtitle:
                user == null ? null : '${user.currency} · ${_supportedCurrencies[user.currency] ?? ""}',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickCurrency(context, ref, user?.currency ?? 'USD'),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('About'),
          const _Tile(icon: Icons.info_outline_rounded, title: 'Version', subtitle: '0.1.0'),
          const _Tile(
            icon: Icons.shield_outlined,
            title: 'Privacy',
            subtitle: 'Your data stays local',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref, String current) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Text(
                'Choose your default currency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            for (final entry in _supportedCurrencies.entries)
              ListTile(
                title: Text(entry.value),
                trailing: entry.key == current
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(_, entry.key),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (picked == null || picked == current) return;
    try {
      await ref.read(authProvider.notifier).updateProfile(currency: picked);
      if (context.mounted) showSuccessSnack(context, 'Currency set to $picked');
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e, fallback: 'Could not update currency');
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
