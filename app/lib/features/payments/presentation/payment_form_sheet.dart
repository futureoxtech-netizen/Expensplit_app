import 'package:flutter/material.dart';

import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/payment_method_model.dart';

/// Opens the add/edit payment-method form. Returns the entered values as the
/// API input map (`{type, label, accountName, accountNumber, bankName, note}`)
/// or `null` if the user cancels. Pass [initial] to pre-fill for editing.
Future<Map<String, dynamic>?> showPaymentFormSheet(
  BuildContext context, {
  PaymentMethodModel? initial,
}) {
  return showAppSheet<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _PaymentFormSheet(initial: initial),
  );
}

class _PaymentFormSheet extends StatefulWidget {
  const _PaymentFormSheet({this.initial});
  final PaymentMethodModel? initial;

  @override
  State<_PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends State<_PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _accountName;
  late final TextEditingController _accountNumber;
  late final TextEditingController _bankName;
  late final TextEditingController _note;
  late String _type;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _type = i?.type ?? 'bank';
    _label = TextEditingController(text: i?.label ?? '');
    _accountName = TextEditingController(text: i?.accountName ?? '');
    _accountNumber = TextEditingController(text: i?.accountNumber ?? '');
    _bankName = TextEditingController(text: i?.bankName ?? '');
    _note = TextEditingController(text: i?.note ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _accountName.dispose();
    _accountNumber.dispose();
    _bankName.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _isBank => _type == 'bank';

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, {
      'type': _type,
      'label': _label.text.trim(),
      'accountName': _accountName.text.trim(),
      'accountNumber': _accountNumber.text.trim(),
      'bankName': _isBank ? _bankName.text.trim() : '',
      'note': _note.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final meta = PaymentType.of(_type);
    final editing = widget.initial != null;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSheetHandle(),
              const SizedBox(height: 6),
              Text(
                editing ? 'Edit payment method' : 'Add payment method',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              // Type chooser
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Method',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in PaymentType.all)
                    ChoiceChip(
                      label: Text(t.label),
                      avatar: Icon(t.icon,
                          size: 18,
                          color: _type == t.id ? Colors.white : t.color),
                      selected: _type == t.id,
                      selectedColor: meta.color,
                      labelStyle: TextStyle(
                        color: _type == t.id ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _type = t.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isBank) ...[
                AppTextField(
                  controller: _bankName,
                  label: 'Bank name',
                  hint: 'e.g. HBL, Meezan, Allied',
                  prefixIcon: Icons.account_balance_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
              ],
              AppTextField(
                controller: _accountName,
                label: 'Account holder name',
                hint: 'Name on the account (optional)',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v != null && v.trim().length > 80) ? 'Name is too long' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _accountNumber,
                label: 'Account number / handle',
                hint: meta.hint,
                prefixIcon: Icons.tag_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'This is required so people can pay you';
                  if (t.length > 120) return 'Too long';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _label,
                label: 'Label (optional)',
                hint: 'e.g. Salary account, Personal wallet',
                prefixIcon: Icons.label_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v != null && v.trim().length > 60) ? 'Label is too long' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _note,
                label: 'Note (optional)',
                hint: 'Anything else the payer should know',
                prefixIcon: Icons.sticky_note_2_outlined,
                maxLines: 2,
                minLines: 1,
                validator: (v) =>
                    (v != null && v.trim().length > 200) ? 'Note is too long' : null,
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: editing ? 'Save changes' : 'Add method',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
