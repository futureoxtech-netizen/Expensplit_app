import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/group_model.dart';
import '../providers/group_providers.dart';

class EditGroupScreen extends ConsumerStatefulWidget {
  const EditGroupScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends ConsumerState<EditGroupScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _category = 'trip';
  String _currency = 'USD';
  Color _color = AppColors.primary;
  bool _loading = false;
  bool _loadedFromGroup = false;

  static const _currencies = ['USD', 'EUR', 'GBP', 'INR', 'PKR', 'JPY', 'CAD', 'AUD'];
  static const _palette = [
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFFFF6B6B),
    Color(0xFFFFC857),
    Color(0xFF44C4FF),
    Color(0xFFFD79A8),
    Color(0xFFA29BFE),
    Color(0xFFE17055),
  ];

  void _seed(GroupModel g) {
    if (_loadedFromGroup) return;
    _name.text = g.name;
    _description.text = g.description;
    _category = g.category;
    _currency = g.currency;
    try {
      _color = Color(int.parse(g.coverColor.replaceFirst('#', '0xFF')));
    } catch (_) {}
    _loadedFromGroup = true;
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 2) return;
    setState(() => _loading = true);
    try {
      final colorHex =
          '#${_color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
      await ref.read(groupRepositoryProvider).update(
            widget.groupId,
            name: _name.text.trim(),
            description: _description.text.trim(),
            category: _category,
            coverColor: colorHex,
            currency: _currency,
          );
      ref.invalidate(groupDetailProvider(widget.groupId));
      ref.invalidate(groupsListProvider);
      ref.invalidate(groupBalancesProvider(widget.groupId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not save changes');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(groupDetailProvider(widget.groupId));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit group')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(friendlyError(e))),
          data: (group) {
            _seed(group);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                AppTextField(controller: _name, label: 'Group name'),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _description,
                  label: 'Description',
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 14),
                const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
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
                const SizedBox(height: 18),
                const Text('Currency', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _currencies.contains(_currency) ? _currency : 'USD',
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                ),
                const SizedBox(height: 18),
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c,
                            border: Border.all(
                              color: _color.value == c.value ? Colors.white : Colors.transparent,
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
                PrimaryButton(label: 'Save changes', loading: _loading, onPressed: _submit),
              ],
            );
          },
        ),
      ),
    );
  }
}
