import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../data/group_model.dart';
import '../providers/group_providers.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsListProvider);
    final invitesAsync = ref.watch(myInvitesProvider);

    return GradientScaffold(
      padding: EdgeInsets.zero,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupsListProvider);
          ref.invalidate(myInvitesProvider);
        },
        child: ListView(
          // No FAB on this screen — bottom nav bar clearance only.
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const Text('Groups',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Split bills with people that matter.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.add_rounded,
                    label: 'New group',
                    color: AppColors.primary,
                    onTap: () => context.push('/groups/new'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.qr_code_2_rounded,
                    label: 'Join with code',
                    color: AppColors.accent,
                    onTap: () => context.push('/groups/join'),
                  ),
                ),
              ],
            ),
            invitesAsync.maybeWhen(
              data: (invites) => invites.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _InvitesSection(invites: invites),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return EmptyState(
                    icon: Icons.groups_2_rounded,
                    title: 'No groups yet',
                    subtitle: 'Create your first group to start tracking shared expenses.',
                    actionLabel: 'Create a group',
                    onAction: () => context.push('/groups/new'),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Your groups',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                      ),
                    ),
                    for (final g in groups)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GroupRow(
                          name: g.name,
                          color: g.coverColor,
                          memberCount: g.members.length,
                          description: g.description.isEmpty ? g.category : g.description,
                          onTap: () => context.push('/groups/${g.id}'),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const ShimmerLoader(height: 78),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(groupsListProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner listing pending group invitations with Accept / Decline actions.
class _InvitesSection extends ConsumerStatefulWidget {
  const _InvitesSection({required this.invites});
  final List<GroupInvite> invites;

  @override
  ConsumerState<_InvitesSection> createState() => _InvitesSectionState();
}

class _InvitesSectionState extends ConsumerState<_InvitesSection> {
  // Busy group ids — disables buttons during in-flight requests.
  final _busy = <String>{};

  static const int _kPageSize = 3;
  // Approximate rendered height of one invite card (padding + icon row +
  // button row + spacing). Used to size the internal scroll area.
  static const double _kCardHeight = 138.0;

  int _visibleCount = _kPageSize;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Trigger load-more when within 80 px of the bottom of the inner list.
  void _onScroll() {
    final total = widget.invites.length;
    if (_visibleCount >= total) return;
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 80) {
      setState(() {
        _visibleCount = (_visibleCount + _kPageSize).clamp(0, total);
      });
    }
  }

  Future<void> _accept(GroupInvite invite) async {
    if (_busy.contains(invite.groupId)) return;
    setState(() => _busy.add(invite.groupId));
    try {
      await ref.read(groupRepositoryProvider).acceptInvite(invite.groupId);
      ref.invalidate(myInvitesProvider);
      ref.invalidate(groupsListProvider);
      if (mounted) showSuccessSnack(context, 'You joined "${invite.name}"');
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not join group');
    } finally {
      if (mounted) setState(() => _busy.remove(invite.groupId));
    }
  }

  Future<void> _decline(GroupInvite invite) async {
    if (_busy.contains(invite.groupId)) return;
    setState(() => _busy.add(invite.groupId));
    try {
      await ref.read(groupRepositoryProvider).declineInvite(invite.groupId);
      ref.invalidate(myInvitesProvider);
      if (mounted) showSuccessSnack(context, 'Invitation declined');
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e, fallback: 'Could not decline invitation');
      }
    } finally {
      if (mounted) setState(() => _busy.remove(invite.groupId));
    }
  }

  void _showLess() {
    setState(() => _visibleCount = _kPageSize);
    // Snap inner list back to top.
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.invites.length;
    final visible = widget.invites.take(_visibleCount).toList();
    final remaining = (total - _visibleCount).clamp(0, total);
    final isExpanded = _visibleCount > _kPageSize;
    final cs = Theme.of(context).colorScheme;

    // Height of the scroll area: fits exactly the number of visible cards, up
    // to _kPageSize. With one invite it's one card tall (no dead space); with
    // more than _kPageSize it caps at _kPageSize and the area scrolls. The
    // extra loader row (when more remain) gets a little headroom.
    final cardsToFit = visible.length.clamp(1, _kPageSize);
    final scrollAreaHeight = cardsToFit * _kCardHeight + (remaining > 0 ? 44.0 : 0.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 2, right: 2),
            child: Row(
              children: [
                const Icon(Icons.mark_email_unread_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Group invitations',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: cs.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                // Quick hint label when more items exist
                if (remaining > 0)
                  Text(
                    '$remaining more',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // ── Scrollable invite list ─────────────────────────────────────
          // Fixed height = 3 cards. When visibleCount > 3 the user can scroll
          // inside this area; reaching the bottom auto-loads the next page.
          SizedBox(
            height: scrollAreaHeight,
            child: ListView.builder(
              controller: _scrollCtrl,
              itemCount: visible.length + (remaining > 0 ? 1 : 0),
              padding: EdgeInsets.zero,
              itemBuilder: (ctx, i) {
                // Last slot = loading indicator while the next batch is
                // "virtually" being loaded (it auto-appends on scroll).
                if (i == visible.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Scroll for $remaining more',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final invite = visible[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InviteCard(
                    invite: invite,
                    busy: _busy.contains(invite.groupId),
                    onAccept: () => _accept(invite),
                    onDecline: () => _decline(invite),
                  ),
                );
              },
            ),
          ),

          // ── Footer: Show less / scroll hint divider ────────────────────
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _showLess,
                  icon: const Icon(Icons.expand_less_rounded, size: 18),
                  label: const Text(
                    'Show less',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.onSurface.withOpacity(0.55),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            )
          else if (total <= _kPageSize)
            const SizedBox(height: 6)
          else
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe_down_rounded,
                      size: 14, color: cs.onSurface.withOpacity(0.3)),
                  const SizedBox(width: 4),
                  Text(
                    'Scroll up to see more',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final GroupInvite invite;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  Color _parse() {
    try {
      return Color(int.parse(invite.coverColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _parse();
    final cs = Theme.of(context).colorScheme;
    final inviterName = invite.invitedBy?.name ?? 'Someone';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [c, c.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Avatar(
                          name: inviterName,
                          imageUrl: invite.invitedBy?.avatarUrl,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '$inviterName invited you · ${invite.memberCount} member${invite.memberCount == 1 ? '' : 's'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onDecline,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: BorderSide(color: cs.onSurface.withOpacity(0.18)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Decline',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Accept',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.name,
    required this.color,
    required this.memberCount,
    required this.description,
    required this.onTap,
  });

  final String name;
  final String color;
  final int memberCount;
  final String description;
  final VoidCallback onTap;

  Color _parse() {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _parse();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [c, c.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      '$memberCount members · $description',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
