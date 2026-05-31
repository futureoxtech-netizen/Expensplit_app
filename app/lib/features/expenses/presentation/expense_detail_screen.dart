import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/providers/group_providers.dart';
import '../../reactions/presentation/reaction_editor.dart';
import '../providers/expense_providers.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});
  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expenseDetailProvider(expenseId));
    final me = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense'),
        actions: [
          async.maybeWhen(
            data: (e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit',
                  onPressed: () =>
                      context.push('/expenses/${e.id}/edit', extra: e),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Delete',
                  onPressed: () =>
                      _confirmDelete(context, ref, e.id, e.groupId),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (e) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                CategoryIcon(category: e.category, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.description,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        DateFmt.medium(e.spentAt),
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    Money.format(e.amount, code: e.currency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paid by ${e.paidBy.name} · ${e.splitMode} split',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Shares',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            for (final s in e.shares)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Avatar(
                        name: s.user.name,
                        imageUrl: s.user.avatarUrl,
                        size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.user.name +
                            (me != null && me.id == s.user.id ? ' (you)' : ''),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      Money.format(s.amount, code: e.currency),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            if (e.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Notes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(e.notes),
            ],
            const SizedBox(height: 20),
            const Text('Reactions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              'Tap to react · long-press a reaction to see who',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 10),
            ReactionEditor(
              targetType: 'expense',
              targetId: e.id,
              groupId: e.groupId,
              reactions: e.reactions,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String groupId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(expenseRepositoryProvider).delete(id);
      ref.invalidate(groupExpensesProvider(groupId));
      ref.invalidate(groupBalancesProvider(groupId));
      ref.invalidate(expenseDetailProvider(id));
      ref.invalidate(expenseFeedProvider);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted)
        showErrorSnack(context, e, fallback: 'Could not delete expense');
    }
  }
}
