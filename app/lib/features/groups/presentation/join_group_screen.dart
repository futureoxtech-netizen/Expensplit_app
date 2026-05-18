import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/group_providers.dart';

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
      if (mounted) context.go('/groups/${group.id}');
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not join group');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              const Text('Enter invite code',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Ask a group member to share the invite code, then enter it below.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
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
