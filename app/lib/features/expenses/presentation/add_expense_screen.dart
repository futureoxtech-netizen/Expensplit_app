import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/receipt_picker.dart';
import '../../auth/data/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/providers/group_providers.dart';
import '../data/expense_model.dart';
import '../providers/expense_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.groupId, this.initialExpense})
      : assert(groupId != null || initialExpense != null,
            'Provide groupId for create or initialExpense for edit');
  final String? groupId;
  final ExpenseModel? initialExpense;

  bool get isEdit => initialExpense != null;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String _category = 'food';
  String _splitMode = 'equal';
  String? _paidBy;
  final Set<String> _participants = {};
  final Map<String, TextEditingController> _valueCtrls = {};
  bool _loading = false;
  bool _prePopulated = false;
  late final ReceiptController _receipt;

  @override
  void initState() {
    super.initState();
    final e = widget.initialExpense;
    _receipt = ReceiptController(initialUrl: e?.receiptUrl);
    if (e != null) {
      _description.text = e.description;
      _amount.text = e.amount.toStringAsFixed(2);
      _notes.text = e.notes;
      _category = e.category;
      _splitMode = e.splitMode;
      _paidBy = e.paidBy.id;
      for (final s in e.shares) {
        _participants.add(s.user.id);
        _ctrlFor(s.user.id).text = s.amount.toStringAsFixed(2);
      }
      _prePopulated = true;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _notes.dispose();
    _receipt.dispose();
    for (final c in _valueCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(String userId) =>
      _valueCtrls.putIfAbsent(userId, () => TextEditingController());

  List<Map<String, dynamic>> _buildSplits() {
    return _participants.map((id) {
      final raw = _valueCtrls[id]?.text;
      return <String, dynamic>{
        'userId': id,
        if (_splitMode != 'equal') 'value': double.tryParse(raw ?? '') ?? 0,
      };
    }).toList();
  }

  Future<void> _submit(List<UserModel> members) async {
    final desc = _description.text.trim();
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (desc.isEmpty || amount <= 0 || _paidBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill description, amount and who paid')),
      );
      return;
    }
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one participant')),
      );
      return;
    }

    setState(() => _loading = true);

    // Upload the receipt (if a new one was picked) BEFORE creating the
    // expense, so the record is saved with its URL. If this fails we never
    // touched the expense, so just surface the error.
    String receiptUrl;
    try {
      receiptUrl = await _receipt.resolveUrl(ref);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showErrorSnack(context, e, fallback: 'Could not upload receipt');
      }
      return;
    }

    try {
      if (widget.isEdit) {
        final updated = await ref.read(expenseRepositoryProvider).update(
              widget.initialExpense!.id,
              description: desc,
              amount: amount,
              splitMode: _splitMode,
              paidBy: _paidBy!,
              splits: _buildSplits(),
              category: _category,
              notes: _notes.text.trim(),
              receiptUrl: receiptUrl,
            );
        final gid = updated.groupId;
        ref.invalidate(groupExpensesProvider(gid));
        ref.invalidate(groupExpensesPagedProvider(gid));
        ref.invalidate(groupBalancesProvider(gid));
        ref.invalidate(expenseDetailProvider(updated.id));
        ref.invalidate(expenseFeedProvider);
      } else {
        await ref.read(expenseRepositoryProvider).create(
              groupId: widget.groupId!,
              description: desc,
              amount: amount,
              splitMode: _splitMode,
              paidBy: _paidBy!,
              splits: _buildSplits(),
              category: _category,
              notes: _notes.text.trim(),
              receiptUrl: receiptUrl,
            );
        ref.invalidate(groupExpensesProvider(widget.groupId!));
        ref.invalidate(groupExpensesPagedProvider(widget.groupId!));
        ref.invalidate(groupBalancesProvider(widget.groupId!));
        ref.invalidate(expenseFeedProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(widget.isEdit ? 'Expense updated!' : 'Expense added!'),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
        context.pop();
      }
    } catch (e) {
      // The expense save failed but we may have just uploaded a receipt —
      // delete it so it doesn't orphan in storage.
      await _receipt.rollback(ref);
      if (mounted)
        showErrorSnack(context, e, fallback: 'Could not save expense');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGroupId = widget.groupId ?? widget.initialExpense!.groupId;
    final groupAsync = ref.watch(groupDetailProvider(effectiveGroupId));
    final me = ref.watch(authProvider).user;

    return Scaffold(
      appBar:
          AppBar(title: Text(widget.isEdit ? 'Edit expense' : 'Add expense')),
      body: SafeArea(
        child: groupAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(friendlyError(e))),
          data: (group) {
            final members = group.members.map((m) => m.user).toList();
            _paidBy ??= me?.id ?? members.first.id;
            // In create mode only: default all members as participants
            if (!_prePopulated && _participants.isEmpty) {
              _participants.addAll(members.map((u) => u.id));
            }
            final amount = double.tryParse(_amount.text.trim()) ?? 0;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                AppTextField(
                  controller: _description,
                  label: 'Description',
                  prefixIcon: Icons.short_text_rounded,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _amount,
                  label: 'Amount (${group.currency})',
                  prefixText: Money.symbolOf(group.currency),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                const Text('Category',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in [
                        'food',
                        'groceries',
                        'transport',
                        'shopping',
                        'rent',
                        'utilities',
                        'entertainment',
                        'travel',
                        'health',
                        'gifts',
                        'other',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Paid by',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final u = members[i];
                      final selected = _paidBy == u.id;
                      return GestureDetector(
                        onTap: () => setState(() => _paidBy = u.id),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Avatar(
                                  name: u.name,
                                  imageUrl: u.avatarUrl,
                                  size: 44),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 60,
                              child: Text(
                                u.name.split(' ').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Split mode',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final m in ['equal', 'exact', 'percent', 'shares'])
                      ChoiceChip(
                        label: Text(m),
                        selected: _splitMode == m,
                        onSelected: (_) => setState(() => _splitMode = m),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _splitModeHelp(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Participants',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._buildParticipantRows(members, amount, group.currency),
                if (_splitMode != 'equal')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _splitSummary(amount, group.currency),
                  ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _notes,
                  label: 'Notes (optional)',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 16),
                const Text('Receipt',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ReceiptPicker(controller: _receipt),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: widget.isEdit ? 'Save changes' : 'Save expense',
                  loading: _loading,
                  onPressed: () => _submit(members),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _splitModeHelp() {
    switch (_splitMode) {
      case 'equal':
        return 'Split evenly across everyone you tick.';
      case 'exact':
        return 'Enter the exact amount each person owes. Must sum to the total.';
      case 'percent':
        return 'Enter percentages. Must sum to 100.';
      case 'shares':
        return 'Enter share weights — e.g. 1, 1, 2. Larger weight = bigger share.';
      default:
        return '';
    }
  }

  List<Widget> _buildParticipantRows(
      List<UserModel> members, double total, String currency) {
    return [
      for (final u in members)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _participants.contains(u.id),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _participants.add(u.id);
                  } else {
                    _participants.remove(u.id);
                  }
                }),
              ),
              Avatar(name: u.name, imageUrl: u.avatarUrl, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(u.name.isEmpty ? u.email : u.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (_splitMode == 'equal' &&
                  _participants.contains(u.id) &&
                  total > 0)
                Text(
                  Money.format(total / _participants.length, code: currency),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              if (_splitMode != 'equal' && _participants.contains(u.id))
                SizedBox(
                  width: 92,
                  child: TextField(
                    controller: _ctrlFor(u.id),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: _splitMode == 'percent'
                          ? '%'
                          : (_splitMode == 'shares' ? 'shares' : '0.00'),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  Widget _splitSummary(double total, String currency) {
    final values = _participants
        .map((id) => double.tryParse(_valueCtrls[id]?.text ?? '') ?? 0)
        .toList();
    final sum = values.fold<double>(0, (a, b) => a + b);
    String label;
    Color color;
    if (_splitMode == 'exact') {
      final diff = (sum - total).abs();
      label = diff < 0.01
          ? 'Sums to ${Money.format(total, code: currency)} ✓'
          : 'Off by ${Money.format(diff, code: currency)}';
      color = diff < 0.01 ? AppColors.accent : AppColors.danger;
    } else if (_splitMode == 'percent') {
      final diff = (sum - 100).abs();
      label = diff < 0.01
          ? 'Sums to 100% ✓'
          : 'Currently ${sum.toStringAsFixed(1)}%';
      color = diff < 0.01 ? AppColors.accent : AppColors.danger;
    } else {
      label = sum > 0
          ? 'Total weight: ${sum.toStringAsFixed(0)}'
          : 'Add at least one share';
      color = sum > 0 ? AppColors.accent : AppColors.danger;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.summarize_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
