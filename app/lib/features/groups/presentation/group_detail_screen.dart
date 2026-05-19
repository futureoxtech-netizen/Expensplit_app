import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/network/realtime.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expense_providers.dart';
import '../../settlements/providers/settlement_providers.dart';
import '../data/group_model.dart';
import '../providers/group_providers.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realtimeBridgeProvider).joinGroup(widget.groupId);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));

    return groupAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(friendlyError(e)))),
      data: (group) {
        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit group',
                onPressed: () => context.push('/groups/${group.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_2_rounded),
                tooltip: 'Invite',
                onPressed: () => _showInviteSheet(context, group),
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Balances'),
                Tab(text: 'Members'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            onPressed: () => context.push('/groups/${group.id}/expenses/new'),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add expense', style: TextStyle(color: Colors.white)),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _ExpensesTab(groupId: group.id),
              _BalancesTab(group: group),
              _MembersTab(group: group),
            ],
          ),
        );
      },
    );
  }

  void _showInviteSheet(BuildContext context, GroupModel g) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Invite to group',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(data: g.inviteCode, size: 180),
            ),
            const SizedBox(height: 16),
            SelectableText(
              g.inviteCode,
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: g.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy code'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(groupExpensesProvider(groupId));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupExpensesProvider(groupId)),
      child: async.when(
        loading: () => const Padding(padding: EdgeInsets.all(16), child: ShimmerLoader()),
        error: (e, _) => ListView(children: [Padding(padding: const EdgeInsets.all(20), child: Text(friendlyError(e)))]),
        data: (page) {
          if (page.items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'No expenses yet',
                  subtitle: 'Tap "Add expense" to record your first one.',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: page.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final e = page.items[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => GoRouter.of(context).push('/expenses/${e.id}'),
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
                        CategoryIcon(category: e.category),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.description,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                '${e.paidBy.name} paid · ${DateFmt.relative(e.spentAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Money.format(e.amount, code: e.currency),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BalancesTab extends ConsumerWidget {
  const _BalancesTab({required this.group});
  final GroupModel group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authProvider).user;
    final async = ref.watch(groupBalancesProvider(group.id));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupBalancesProvider(group.id)),
      child: async.when(
        loading: () => const Padding(padding: EdgeInsets.all(16), child: ShimmerLoader()),
        error: (e, _) => ListView(children: [Padding(padding: const EdgeInsets.all(20), child: Text(friendlyError(e)))]),
        data: (b) {
          if (b.balances.every((x) => x.net.abs() < 0.01)) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                EmptyState(
                  icon: Icons.balance_rounded,
                  title: 'All settled',
                  subtitle: "Nobody owes anybody — let's keep it that way.",
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              const Text('Net balances',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...b.balances.map((x) {
                final c = x.net >= 0 ? AppColors.accent : AppColors.danger;
                final label = x.net >= 0 ? 'is owed' : 'owes';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Avatar(name: x.user?.name ?? '?', size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${x.user?.name ?? 'Someone'} $label',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        Money.format(x.net.abs(), code: group.currency),
                        style: TextStyle(fontWeight: FontWeight.w800, color: c),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 18),
              const Text('Simplified payments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (b.transfers.isEmpty)
                const GlassCard(child: Text('All squared away.')),
              for (final t in b.transfers)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${t.fromUser?.name ?? 'Someone'} → ${t.toUser?.name ?? 'Someone'}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        Money.format(t.amount, code: group.currency),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 10),
                      if (me != null && (t.from == me.id || t.to == me.id))
                        ElevatedButton(
                          onPressed: () => _showGroupSettleSheet(
                              context, ref, t.from, t.to, t.amount, group,
                              t.fromUser?.name, t.toUser?.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text('Settle'),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showGroupSettleSheet(
    BuildContext context,
    WidgetRef ref,
    String from,
    String to,
    double suggestedAmount,
    GroupModel group,
    String? fromName,
    String? toName,
  ) async {
    final ctrl = TextEditingController(
        text: suggestedAmount.toStringAsFixed(2));
    final entered = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Settle up',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${fromName ?? 'Someone'} → ${toName ?? 'Someone'}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${group.currency} ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final entered = double.tryParse(ctrl.text.trim());
                    if (entered == null || entered <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Enter a valid amount')));
                      return;
                    }
                    Navigator.pop(ctx, entered);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm settlement',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
    ctrl.dispose();
    if (entered != null && context.mounted) {
      await _settle(context, ref, from, to, entered, group);
    }
  }

  Future<void> _settle(
    BuildContext context,
    WidgetRef ref,
    String from,
    String to,
    double amount,
    GroupModel group,
  ) async {
    try {
      await ref.read(settlementRepositoryProvider).create(
            groupId: group.id,
            from: from,
            to: to,
            amount: amount,
            currency: group.currency,
          );
      ref.invalidate(groupBalancesProvider(group.id));
      ref.invalidate(groupExpensesProvider(group.id));
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (modalCtx) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                const Text('Settlement Recorded!',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  Money.format(amount, code: group.currency),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'has been recorded as settled',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(modalCtx),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Done',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e, fallback: 'Could not record payment');
    }
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.group});
  final GroupModel group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        for (final m in group.members)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Avatar(name: m.user.name, imageUrl: m.user.avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.user.name.isEmpty ? m.user.email : m.user.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        m.user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(m.role,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        PrimaryButton(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Invite member',
          onPressed: () => _invite(context, ref),
        ),
      ],
    );
  }

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite by email'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'name@example.com'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Invite')),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      await ref.read(groupRepositoryProvider).addMember(group.id, email);
      ref.invalidate(groupDetailProvider(group.id));
      if (context.mounted) showSuccessSnack(context, 'Member added');
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e, fallback: 'Could not invite member');
    }
  }
}
