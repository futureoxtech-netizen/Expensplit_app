import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/utils/amount_input_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../data/loan_model.dart';
import '../providers/loan_providers.dart';

class AddPaymentSheet extends ConsumerStatefulWidget {
  const AddPaymentSheet({super.key, required this.loan, required this.onAdded});
  final LoanModel loan;
  final VoidCallback onAdded;

  @override
  ConsumerState<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _noteCtrl = TextEditingController();

  String _method = 'cash';
  DateTime _date = DateTime.now();
  bool _loading = false;

  static const _methods = [
    ('cash', 'Cash', Icons.payments_outlined),
    ('bank', 'Bank', Icons.account_balance_rounded),
    ('upi', 'UPI', Icons.qr_code_scanner_rounded),
    ('other', 'Other', Icons.attach_money_rounded),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with the remaining amount.
    final rem = widget.loan.remaining;
    _amountCtrl = TextEditingController(
      text: rem > 0 ? rem.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(loanRepositoryProvider);
      final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));
      await repo.addPayment(
        loanId: widget.loan.id,
        amount: amount,
        note: _noteCtrl.text.trim(),
        method: _method,
        paidAt: _date,
      );
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = widget.loan.currency;
    final symbol = Money.symbolOf(currency);
    final isGiven = widget.loan.loanType == 'given';
    final accent = isGiven ? AppColors.accent : AppColors.danger;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Record Payment',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.loan.counterpartyName} · Remaining: ${Money.format(widget.loan.remaining, code: currency)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isGiven ? 'They paid' : 'I paid',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountCtrl,
                  decoration: InputDecoration(
                    labelText: 'Amount *',
                    prefixText: '$symbol ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: AmountInputFormatter.list(),
                  autofocus: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter amount';
                    final n = double.tryParse(v.replaceAll(',', ''));
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    if (n > widget.loan.remaining + 0.01) {
                      return 'Exceeds remaining balance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Payment method
                const Text('Method',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final m in _methods) ...[
                      if (_methods.indexOf(m) > 0) const SizedBox(width: 8),
                      Expanded(child: _MethodChip(
                        label: m.$2,
                        icon: m.$3,
                        selected: _method == m.$1,
                        onTap: () => setState(() => _method = m.$1),
                      )),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Note
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g. Paid in cash',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),

                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today_rounded,
                      color: accent, size: 20),
                  title: Text(
                    '${_date.day}/${_date.month}/${_date.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Payment date'),
                  onTap: _pickDate,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Payment',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppColors.primary : cs.onSurface.withOpacity(0.55)),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : cs.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
