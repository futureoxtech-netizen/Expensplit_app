import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../providers/activity_providers.dart';
import '../providers/unread_provider.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unreadActivityProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(activityFeedProvider);
    return GradientScaffold(
      padding: EdgeInsets.zero,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activityFeedProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            const Text('Activity',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            async.when(
              loading: () => const ShimmerLoader(height: 72),
              error: (e, _) => Text(friendlyError(e)),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_toggle_off_rounded,
                    title: 'Nothing yet',
                    subtitle: 'When friends add expenses or settle up, it appears here.',
                  );
                }
                return Column(
                  children: [
                    for (final a in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: a.groupId == null
                                ? null
                                : () => context.push('/groups/${a.groupId}'),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Theme.of(context).dividerColor),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Avatar(
                                        name: a.actorName ?? '?',
                                        imageUrl: a.actorAvatar,
                                        size: 38,
                                      ),
                                      Positioned(
                                        bottom: -2,
                                        right: -2,
                                        child: _activityBadge(a.type),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: a.actorName ?? 'Someone',
                                                style: const TextStyle(fontWeight: FontWeight.w700),
                                              ),
                                              TextSpan(text: ' ${a.message}'),
                                              if (a.groupName != null) ...[
                                                const TextSpan(text: ' · '),
                                                TextSpan(
                                                  text: a.groupName,
                                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFmt.relative(a.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
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
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityBadge(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'expense.created':
        icon = Icons.add_rounded;
        color = Colors.green;
        break;
      case 'expense.updated':
        icon = Icons.edit_rounded;
        color = Colors.orange;
        break;
      case 'expense.deleted':
        icon = Icons.delete_rounded;
        color = Colors.red;
        break;
      case 'settlement.created':
        icon = Icons.handshake_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = Colors.grey;
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 11, color: Colors.white),
    );
  }
}
