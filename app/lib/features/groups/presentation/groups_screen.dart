import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../providers/group_providers.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsListProvider);

    return GradientScaffold(
      padding: EdgeInsets.zero,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(groupsListProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
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
            const SizedBox(height: 20),
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
                  children: [
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
              error: (e, _) => Text('$e'),
            ),
          ],
        ),
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
