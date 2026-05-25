import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Photo library'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ref.read(authProvider.notifier).uploadAvatar(
              bytes: bytes,
              filename: picked.name,
            );
      } else {
        await ref.read(authProvider.notifier).uploadAvatar(file: File(picked.path));
      }
      if (mounted) showSuccessSnack(context, 'Profile photo updated');
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not upload photo');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _uploadingAvatar
                          ? SizedBox(
                              width: 88,
                              height: 88,
                              child: const CircularProgressIndicator(strokeWidth: 3),
                            )
                          : Avatar(
                              name: user?.name ?? '?',
                              imageUrl: user?.avatarUrl,
                              size: 88,
                            ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
            onTap: () => _pickCurrency(user?.currency ?? 'USD'),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Notifications'),
          _Tile(
            icon: Icons.notifications_active_rounded,
            title: 'Push notifications',
            subtitle: 'Receive alerts for new expenses, settlements and group activity.',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openSystemNotificationSettings(),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('About'),
          const _Tile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: 'Expensplit 0.1.0',
          ),
          const _Tile(
            icon: Icons.shield_outlined,
            title: 'Privacy',
            subtitle: 'Your data is encrypted in transit and only shared with members of groups you join.',
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
          const SizedBox(height: 12),
          _DeleteAccountButton(),
        ],
      ),
    );
  }

  void _openSystemNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "You'll get a banner whenever someone in your group adds an expense or settles up. "
          "To turn alerts off, open your phone's notification settings for Expensplit.",
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _pickCurrency(String current) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.88,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
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
                onTap: () => Navigator.pop(sheetCtx, entry.key),
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

// ── Delete Account Button ─────────────────────────────────────────────────────
class _DeleteAccountButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends ConsumerState<_DeleteAccountButton> {
  bool _loading = false;

  Future<void> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) {
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been permanently deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not delete account');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _loading ? null : _confirm,
        icon: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
              )
            : const Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 20),
        label: Text(
          _loading ? 'Deleting account…' : 'Delete account',
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _ctrl = TextEditingController();
  bool get _canDelete => _ctrl.text.trim() == 'DELETE';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_rounded, color: AppColors.danger, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Delete account?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This action is permanent and cannot be undone. Here is what will happen:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          _BulletPoint(
            icon: Icons.group_remove_rounded,
            color: AppColors.warn,
            text: 'You will be removed from all groups. If you are the owner, ownership transfers to the next member.',
          ),
          const SizedBox(height: 8),
          _BulletPoint(
            icon: Icons.receipt_long_rounded,
            color: AppColors.primary,
            text: 'Group expenses and settlements you created are kept for other members.',
          ),
          const SizedBox(height: 8),
          _BulletPoint(
            icon: Icons.person_remove_rounded,
            color: AppColors.danger,
            text: 'Your personal expenses and account data are permanently erased.',
          ),
          const SizedBox(height: 8),
          _BulletPoint(
            icon: Icons.email_rounded,
            color: Colors.green,
            text: 'You can re-register with the same email afterwards.',
          ),
          const SizedBox(height: 20),
          Text(
            'Type DELETE to confirm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'DELETE',
              filled: true,
              fillColor: AppColors.danger.withOpacity(0.06),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.danger.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.danger.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            disabledBackgroundColor: AppColors.danger.withOpacity(0.3),
          ),
          child: const Text('Delete forever'),
        ),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
