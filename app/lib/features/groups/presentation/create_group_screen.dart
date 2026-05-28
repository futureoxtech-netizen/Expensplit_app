import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/group_providers.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _category = 'trip';
  Color _color = AppColors.primary;
  bool _loading = false;
  final _palette = const [
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFFFF6B6B),
    Color(0xFFFFC857),
    Color(0xFF44C4FF),
    Color(0xFFFD79A8),
    Color(0xFFA29BFE),
    Color(0xFFE17055),
  ];

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 2) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(groupRepositoryProvider);
      final group = await repo.create(
        name: name,
        description: _description.text.trim(),
        category: _category,
        coverColor: '#${_color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        currency: ref.read(authProvider).user?.currency,
      );
      ref.invalidate(groupsListProvider);
      // pushReplacement (not go) so the create screen is removed but the
      // groups list stays underneath — otherwise the new group detail has
      // no back button.
      if (mounted) context.pushReplacement('/groups/${group.id}');
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not create group');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            AppTextField(
              controller: _name,
              label: 'Group name',
              hint: 'e.g. Weekend Trip',
              prefixIcon: Icons.group_rounded,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _description,
              label: 'Description (optional)',
              hint: 'What is this group about?',
              prefixIcon: Icons.notes_rounded,
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in ['family', 'trip', 'roommates', 'office', 'event', 'other'])
                  ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Cover color', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: Border.all(
                          color: _color == c ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(color: c.withOpacity(0.4), blurRadius: 12),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Create group', loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
