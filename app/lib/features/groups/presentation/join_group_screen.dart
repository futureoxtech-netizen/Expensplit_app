import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/network/realtime.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/group_providers.dart';
import 'qr_scanner_screen.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _code = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.length < 4) return;
    setState(() => _loading = true);
    try {
      final group = await ref.read(groupRepositoryProvider).joinByCode(code);
      ref.invalidate(groupsListProvider);
      // Subscribe to the new group's realtime room immediately so future
      // events arrive without waiting for the next app launch / bootstrap.
      ref.read(realtimeBridgeProvider).joinGroup(group.id);
      if (mounted) context.go('/groups/${group.id}');
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not join group');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scanQr() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (scanned == null || scanned.isEmpty) return;
    _code.text = scanned;
    // Auto-submit immediately after scanning
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join group')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Join a group',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Scan the group QR code or enter the invite code manually.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 28),

              // QR Scan button
              InkWell(
                onTap: _loading ? null : _scanQr,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 48),
                      SizedBox(height: 10),
                      Text(
                        'Scan QR code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Point camera at a group invite QR',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or enter code manually',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              AppTextField(
                controller: _code,
                label: 'Invite code',
                hint: 'e.g. AB12CD34',
                prefixIcon: Icons.vpn_key_rounded,
              ),
              const Spacer(),
              PrimaryButton(label: 'Join group', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
