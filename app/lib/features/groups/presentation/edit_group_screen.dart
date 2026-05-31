import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expense_providers.dart';
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
  String _currency = 'PKR';
  Color _color = AppColors.primary;
  bool _loading = false;
  bool _busy = false; // leave / delete in flight
  bool _loadedFromGroup = false;

  static const _currencies = [
    'USD',
    'EUR',
    'GBP',
    'INR',
    'PKR',
    'JPY',
    'CAD',
    'AUD'
  ];
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
      if (mounted)
        showErrorSnack(context, e, fallback: 'Could not save changes');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Both leaving and deleting remove a group's expenses from *my* view, so
  /// every surface that aggregates them must be refreshed — not just the
  /// groups list. (For other members, the realtime `group:*` events do the
  /// same on their devices.)
  void _invalidateAfterGroupExit(String groupId) {
    ref.invalidate(groupsListProvider);
    ref.invalidate(groupDetailProvider(groupId));
    ref.invalidate(groupBalancesProvider(groupId));
    ref.invalidate(expenseFeedProvider);
    ref.invalidate(expenseFeedPagedProvider);
    ref.invalidate(monthlyAnalyticsProvider);
    ref.invalidate(friendsSummaryProvider);
  }

  Future<void> _confirmLeave(
    GroupModel group, {
    required bool dissolves,
    required bool transfersOwnership,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave group?'),
        content: Text(
          dissolves
              ? 'You\'re the only member of "${group.name}". Leaving will '
                  'permanently delete the group and all of its expenses. '
                  'This cannot be undone.'
              : transfersOwnership
                  ? 'You\'re the owner of "${group.name}". Leaving will pass '
                      'ownership to another member. You can be re-invited later.'
                  : 'Leave "${group.name}"? Your past expenses stay visible to '
                      'the other members. You can be re-invited later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(dissolves ? 'Leave & delete' : 'Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final deleted = await ref.read(groupRepositoryProvider).leave(group.id);
      _invalidateAfterGroupExit(group.id);
      if (mounted) {
        showSuccessSnack(
          context,
          deleted
              ? 'You left — "${group.name}" was deleted'
              : 'You left "${group.name}"',
        );
        context.go('/groups');
      }
    } catch (e) {
      if (mounted)
        showErrorSnack(context, e, fallback: 'Could not leave group');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(
    GroupModel group, {
    bool hasUnsettled = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Dialog(
          backgroundColor: cs.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    gradient: AppColors.dangerGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withOpacity(0.32),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.delete_forever_rounded,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Delete group?',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'This permanently deletes “${group.name}” and every expense '
                  'and settlement in it — for all members. This can’t be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
                if (hasUnsettled) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.danger.withOpacity(0.22)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 18, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This group still has unsettled balances. Those '
                            'records will be lost for everyone.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                              color: cs.onSurface.withOpacity(0.18)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Delete',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(groupRepositoryProvider).deleteGroup(group.id);
      _invalidateAfterGroupExit(group.id);
      if (mounted) {
        showSuccessSnack(context, '"${group.name}" deleted');
        context.go('/groups');
      }
    } catch (e) {
      if (mounted)
        showErrorSnack(context, e, fallback: 'Could not delete group');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(groupDetailProvider(widget.groupId));
    return Scaffold(
      appBar: AppBar(title: const Text('Group settings')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(friendlyError(e))),
          data: (group) {
            _seed(group);

            final me = ref.watch(authProvider).user;
            GroupMember? myMember;
            for (final m in group.members) {
              if (m.user.id == me?.id) {
                myMember = m;
                break;
              }
            }
            final isOwner = myMember?.role == 'owner';
            // Owner and admins can delete the group; regular members can't.
            final canDelete = isOwner || myMember?.role == 'admin';
            final realMembers =
                group.members.where((m) => !m.user.isPlaceholder).toList();
            final iAmOnlyRealMember =
                realMembers.length == 1 && realMembers.first.user.id == me?.id;

            // My net balance in this group, if balances have loaded. Used to
            // gate "leave": you must be settled up first (unless you're the
            // last real member, in which case leaving just dissolves it).
            final balancesAsync =
                ref.watch(groupBalancesProvider(widget.groupId));
            final double? myNet = balancesAsync.maybeWhen(
              data: (b) {
                final mine =
                    b.balances.where((x) => x.userId == me?.id).toList();
                return mine.isEmpty ? 0.0 : mine.first.net;
              },
              orElse: () => null,
            );
            final hasOutstanding = myNet != null && myNet.abs() >= 0.01;
            // Whether anyone in the group still has an unsettled balance — used
            // to add a stronger warning to the delete confirmation.
            final groupHasUnsettled = balancesAsync.maybeWhen(
              data: (b) => b.balances.any((x) => x.net.abs() >= 0.01),
              orElse: () => false,
            );
            final leaveBlocked = hasOutstanding && !iAmOnlyRealMember;

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
                const Text('Category',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in [
                      'family',
                      'trip',
                      'roommates',
                      'office',
                      'event',
                      'other'
                    ])
                      ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Currency',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _currencies.contains(_currency) ? _currency : 'PKR',
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v ?? 'PKR'),
                ),
                const SizedBox(height: 18),
                const Text('Cover color',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
                              color: _color.value == c.value
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: c.withOpacity(0.4), blurRadius: 12),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                    label: 'Save changes',
                    loading: _loading,
                    onPressed: _submit),
                const SizedBox(height: 32),
                const _SectionLabel('Membership'),
                _DangerTile(
                  icon: Icons.logout_rounded,
                  color: AppColors.danger,
                  title: 'Leave group',
                  subtitle: leaveBlocked
                      ? "You can't leave while you have unsettled balances. "
                          'Settle up with the other members first, then try again.'
                      : iAmOnlyRealMember
                          ? "You're the only member — leaving will delete this "
                              'group and all its expenses.'
                          : isOwner
                              ? "You're the owner — leaving transfers ownership "
                                  'to another member.'
                              : 'Your past expenses stay for the other members.',
                  enabled: !leaveBlocked && !_busy,
                  onTap: () => _confirmLeave(
                    group,
                    dissolves: iAmOnlyRealMember,
                    transfersOwnership: isOwner && !iAmOnlyRealMember,
                  ),
                ),
                if (canDelete) ...[
                  const SizedBox(height: 10),
                  _DangerTile(
                    icon: Icons.delete_forever_rounded,
                    color: AppColors.danger,
                    title: 'Delete group',
                    subtitle:
                        'Permanently deletes this group and all its expenses '
                        'and settlements for everyone. This cannot be undone.',
                    enabled: !_busy,
                    onTap: () =>
                        _confirmDelete(group, hasUnsettled: groupHasUnsettled),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
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

/// A bordered, tappable row for destructive actions (leave / delete). When
/// [enabled] is false it renders muted and ignores taps — used to explain why
/// leaving is blocked (outstanding balance) without hiding the option.
class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tint = enabled ? color : cs.onSurface.withOpacity(0.4);
    return Opacity(
      opacity: enabled ? 1 : 0.7,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: enabled
                    ? color.withOpacity(0.35)
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: tint, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: tint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
