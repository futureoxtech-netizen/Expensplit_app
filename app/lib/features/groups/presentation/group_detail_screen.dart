import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/pagination/paged_sliver_list.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/network/realtime.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/data/expense_model.dart';
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
        final color = _parseColor(group.coverColor) ?? AppColors.primary;
        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            // Explicit leading — go_router's `pushReplacement` keeps history
            // intact, but if the user arrived via `go` (e.g. older builds,
            // a deep link) the auto-back disappears. Fall back to /groups.
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/groups');
                }
              },
            ),
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
              labelColor: color,
              indicatorColor: color,
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Balances'),
                Tab(text: 'Members'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: color,
            onPressed: () => context.push('/groups/${group.id}/expenses/new'),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add expense', style: TextStyle(color: Colors.white)),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _ExpensesTab(groupId: group.id, groupColor: color),
              _BalancesTab(group: group, groupColor: color),
              _MembersTab(group: group, groupColor: color),
            ],
          ),
        );
      },
    );
  }

  void _showInviteSheet(BuildContext context, GroupModel g) {
    showAppFixedSheet<void>(
      context: context,
      builder: (sheetCtx) => _InviteSheet(group: g),
    );
  }
}

/// Parses `#RRGGBB` into a Flutter [Color]. Returns null if [hex] is not a
/// well-formed 6-digit hex string — callers should fall back to a default.
Color? _parseColor(String hex) {
  final clean = hex.replaceFirst('#', '');
  if (clean.length != 6) return null;
  final parsed = int.tryParse(clean, radix: 16);
  if (parsed == null) return null;
  return Color(0xFF000000 | parsed);
}

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({required this.group});
  final GroupModel group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grip (hidden on wide screens)
            if (MediaQuery.of(context).size.width < 600)
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // Gradient hero header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Invite to group',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share this code or QR with friends to join “${group.name}”.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            // QR card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cs.onSurface.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: QrImageView(
                data: group.inviteCode,
                size: 190,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF6C5CE7),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF111126),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Code chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.25),
                ),
              ),
              child: SelectableText(
                group.inviteCode,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: group.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite code copied'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                          color: AppColors.primary.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text(
                      'Copy code',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesTab extends ConsumerStatefulWidget {
  const _ExpensesTab({required this.groupId, required this.groupColor});
  final String groupId;
  final Color groupColor;

  @override
  ConsumerState<_ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<_ExpensesTab> {
  final _scrollCtrl = ScrollController();
  PaginatedScrollListener? _scrollListener;

  @override
  void initState() {
    super.initState();
    _scrollListener = PaginatedScrollListener(
      controller: _scrollCtrl,
      onLoadMore: () => ref
          .read(groupExpensesPagedProvider(widget.groupId).notifier)
          .loadMore(),
    );
  }

  @override
  void dispose() {
    _scrollListener?.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupExpensesPagedProvider(widget.groupId));
    final notifier =
        ref.read(groupExpensesPagedProvider(widget.groupId).notifier);
    final me = ref.read(authProvider).user;

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          PagedSliverList<ExpenseModel>(
            state: state,
            onLoadFirst: notifier.loadFirst,
            onRetryMore: notifier.loadMore,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
            firstPageBuilder: (ctx, s) => s.error != null
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(friendlyError(s.error)),
                  )
                : const ShimmerLoader(),
            emptyBuilder: (ctx) => const Padding(
              padding: EdgeInsets.only(top: 100),
              child: EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No expenses yet',
                subtitle: 'Tap "Add expense" to record your first one.',
              ),
            ),
            separator: const SizedBox(height: 10),
            itemBuilder: (ctx, e, _) {
              final myShare = e.shares
                  .where((s) => s.user.id == me?.id)
                  .fold<double>(0, (a, s) => a + s.amount);
              final iPaid = me != null && e.paidBy.id == me.id;
              return _ExpenseRow(
                expense: e,
                myShare: myShare,
                iPaid: iPaid,
                onTap: () => GoRouter.of(context).push('/expenses/${e.id}'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BalancesTab extends ConsumerWidget {
  const _BalancesTab({required this.group, required this.groupColor});
  final GroupModel group;
  final Color groupColor;

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
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
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
          isScrollControlled: true,
          useSafeArea: true,
          clipBehavior: Clip.antiAlias,
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
  const _MembersTab({required this.group, required this.groupColor});
  final GroupModel group;
  final Color groupColor;

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
                    color: groupColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(m.role,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: groupColor)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        PrimaryButton(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Invite member',
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [groupColor, Color.lerp(groupColor, Colors.white, 0.18)!],
          ),
          onPressed: () => _invite(context, ref),
        ),
      ],
    );
  }

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _InviteByEmailSheet(
        groupName: group.name,
        groupColor: groupColor,
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      await ref.read(groupRepositoryProvider).addMember(group.id, email);
      ref.invalidate(groupDetailProvider(group.id));
      if (context.mounted) showSuccessSnack(context, 'Member added to "${group.name}"');
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e, fallback: 'Could not invite member');
    }
  }
}

/// Bottom sheet that collects an email and returns it via Navigator.pop.
/// Returns null when the user dismisses without confirming.
class _InviteByEmailSheet extends StatefulWidget {
  const _InviteByEmailSheet({required this.groupName, required this.groupColor});
  final String groupName;
  final Color groupColor;

  @override
  State<_InviteByEmailSheet> createState() => _InviteByEmailSheetState();
}

class _InviteByEmailSheetState extends State<_InviteByEmailSheet> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _isEmail(String v) {
    final s = v.trim();
    if (s.isEmpty) return false;
    final at = s.indexOf('@');
    final dot = s.lastIndexOf('.');
    return at > 0 && dot > at + 1 && dot < s.length - 1;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.groupColor;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grip
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Hero icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, Color.lerp(color, Colors.white, 0.25)!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.32),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Invite to ${widget.groupName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Enter the email of someone already on Expensplit. They\'ll be added instantly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.alternate_email_rounded, color: color),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cs.onSurface.withOpacity(0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cs.onSurface.withOpacity(0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: color, width: 1.6),
                    ),
                  ),
                  validator: (v) =>
                      _isEmail(v ?? '') ? null : 'Enter a valid email address',
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: cs.onSurface.withOpacity(0.18)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Send invite',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.myShare,
    required this.iPaid,
    required this.onTap,
  });

  final dynamic expense;
  final double myShare;
  final bool iPaid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Net for me on this expense:
    //   +full amount paid - my share = what I'm owed (positive)
    //   or just -my share if I didn't pay (negative)
    final myNet = (iPaid ? expense.amount as double : 0) - myShare;
    final hasNet = myNet.abs() >= 0.01;
    final netColor = myNet > 0 ? AppColors.accent : AppColors.danger;
    final netLabel = myNet > 0 ? 'you get back' : 'you owe';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CategoryIcon(category: expense.category, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          iPaid
                              ? Icons.account_balance_wallet_rounded
                              : Icons.person_outline_rounded,
                          size: 12,
                          color: cs.onSurface.withOpacity(0.55),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            iPaid
                                ? 'You paid · ${DateFmt.relative(expense.spentAt)}'
                                : '${expense.paidBy.name} paid · ${DateFmt.relative(expense.spentAt)}',
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Money.format(expense.amount, code: expense.currency),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  if (hasNet) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: netColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$netLabel ${Money.format(myNet.abs(), code: expense.currency)}',
                        style: TextStyle(
                          color: netColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
