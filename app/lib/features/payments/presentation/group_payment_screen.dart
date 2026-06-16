import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/payment_method_model.dart';
import '../providers/payment_providers.dart';
import 'payment_form_sheet.dart';
import 'payment_method_tile.dart';

/// Shows every member's shared payment info for a group, and lets the current
/// user add their own — either imported from their saved profile methods or
/// entered manually — so the people who owe them know where to send money.
class GroupPaymentScreen extends ConsumerStatefulWidget {
  const GroupPaymentScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<GroupPaymentScreen> createState() => _GroupPaymentScreenState();
}

class _GroupPaymentScreenState extends ConsumerState<GroupPaymentScreen> {
  bool _busy = false;

  String get _gid => widget.groupId;

  Future<void> _run(Future<void> Function() action, {required String success}) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(groupPaymentInfosProvider(_gid));
      if (mounted) showSuccessSnack(context, success);
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Something went wrong');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Entry point: offer "import from profile" or "add manually".
  Future<void> _startAdd() async {
    final saved = ref.read(authProvider).user?.paymentMethods ?? const [];
    final choice = await showAppSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSheetHandle(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Share payment info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_added_rounded, color: AppColors.primary),
              title: const Text('Import from my saved methods'),
              subtitle: Text(saved.isEmpty
                  ? 'No saved methods — add them in your profile first'
                  : '${saved.length} saved on your profile'),
              enabled: saved.isNotEmpty,
              onTap: () => Navigator.pop(ctx, 'import'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: const Text('Enter manually'),
              subtitle: const Text('Add a one-off method just for this group'),
              onTap: () => Navigator.pop(ctx, 'manual'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'manual') {
      await _addManual();
    } else if (choice == 'import') {
      await _importFromProfile();
    }
  }

  Future<void> _addManual() async {
    final input = await showPaymentFormSheet(context);
    if (input == null) return;
    await _run(() => ref.read(groupPaymentRepositoryProvider).add(_gid, input),
        success: 'Payment info shared');
  }

  Future<void> _importFromProfile() async {
    final saved = ref.read(authProvider).user?.paymentMethods ?? const [];
    final picked = await showAppSheet<PaymentMethodModel>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            const AppSheetHandle(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose a method to share',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            for (final m in saved)
              ListTile(
                leading: Icon(m.typeMeta.icon, color: m.typeMeta.color),
                title: Text(m.title),
                subtitle: Text(m.accountNumber),
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (!mounted || picked == null) return;
    await _run(() => ref.read(groupPaymentRepositoryProvider).add(_gid, picked.toInput()),
        success: 'Payment info shared');
  }

  Future<void> _edit(PaymentMethodModel m) async {
    final input = await showPaymentFormSheet(context, initial: m);
    if (input == null) return;
    await _run(() => ref.read(groupPaymentRepositoryProvider).update(_gid, m.id, input),
        success: 'Payment info updated');
  }

  Future<void> _delete(PaymentMethodModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove payment info?'),
        content: Text('“${m.title}” will be removed from this group.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => ref.read(groupPaymentRepositoryProvider).remove(_gid, m.id),
        success: 'Payment info removed');
  }

  @override
  Widget build(BuildContext context) {
    final meId = ref.watch(authProvider.select((s) => s.user?.id));
    final async = ref.watch(groupPaymentInfosProvider(_gid));

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Group payments'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _startAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add my info'),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(groupPaymentInfosProvider(_gid)),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load payment info',
              subtitle: friendlyError(e),
            ),
          ]),
          data: (infos) {
            final mine = infos.where((m) => m.userId == meId).toList();
            final others = infos.where((m) => m.userId != meId).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 14, left: 2),
                  child: Text(
                    'Share where you want to be paid, and copy anyone else\'s details to pay them back.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const _SectionLabel('Your payment info'),
                if (mine.isEmpty)
                  const _HintCard(
                    text: 'You haven\'t shared any payment info in this group yet. '
                        'Tap “Add my info” below.',
                  )
                else
                  for (final m in mine)
                    PaymentMethodTile(
                      method: m,
                      onEdit: _busy ? null : () => _edit(m),
                      onDelete: _busy ? null : () => _delete(m),
                    ),
                const SizedBox(height: 18),
                const _SectionLabel('Other members'),
                if (others.isEmpty)
                  const _HintCard(text: 'No one else has shared payment info yet.')
                else
                  for (final m in others)
                    PaymentMethodTile(method: m, showOwner: true),
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
        padding: const EdgeInsets.only(left: 2, bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 13.5, color: cs.onSurface.withOpacity(0.7))),
    );
  }
}
