import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/utils/amount_input_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/guest_contact_model.dart';
import '../data/loan_repository.dart';
import '../providers/loan_providers.dart';

class AddLoanSheet extends ConsumerStatefulWidget {
  const AddLoanSheet({super.key});

  @override
  ConsumerState<AddLoanSheet> createState() => _AddLoanSheetState();
}

class _AddLoanSheetState extends ConsumerState<AddLoanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _loanType = 'given'; // 'given' | 'taken'
  Map<String, dynamic>? _selectedContact; // {_id, name, avatarUrl, isGuest}
  DateTime? _dueDate;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedContact == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a person')));
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(loanRepositoryProvider);
      final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));
      final currency = ref.read(authProvider).user?.currency ?? 'PKR';
      final contact = _selectedContact!;

      await repo.createLoan(
        counterpartyId: contact['_id'].toString(),
        counterpartyType: contact['isGuest'] == true ? 'guest' : 'user',
        counterpartyName: contact['name'].toString(),
        counterpartyAvatar: contact['avatarUrl']?.toString(),
        loanType: _loanType,
        amount: amount,
        currency: currency,
        description: _descCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        dueDate: _dueDate,
      );
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
    final currency = ref.watch(authProvider).user?.currency ?? 'PKR';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
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
              const Text(
                'New Loan Entry',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),

              // Type toggle
              const Text('Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              _TypeToggle(
                value: _loanType,
                onChanged: (v) => setState(() => _loanType = v),
              ),
              const SizedBox(height: 20),

              // Person picker
              const Text('Person', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              _ContactPickerTile(
                selected: _selectedContact,
                onSelect: (c) => setState(() => _selectedContact = c),
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Amount *',
                  prefixText: '${Money.symbolOf(currency)} ',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: AmountInputFormatter.list(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter amount';
                  final n = double.tryParse(v.replaceAll(',', ''));
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'e.g. For rent, groceries…',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),

              // Due date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.event_rounded,
                    color: _dueDate != null ? AppColors.primary : null),
                title: Text(
                  _dueDate == null
                      ? 'No due date'
                      : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _dueDate != null ? AppColors.primary : null,
                  ),
                ),
                subtitle: const Text('Reminder when loan is due'),
                trailing: _dueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _dueDate = null),
                      )
                    : null,
                onTap: _pickDate,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const Divider(),
              const SizedBox(height: 4),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any extra details',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _loanType == 'given' ? 'Record as Lent' : 'Record as Borrowed',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }
}

// ── Loan type toggle ───────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TypeBtn(
            label: 'I Gave',
            icon: Icons.arrow_upward_rounded,
            selected: value == 'given',
            color: AppColors.accent,
            onTap: () => onChanged('given'),
          ),
          _TypeBtn(
            label: 'I Took',
            icon: Icons.arrow_downward_rounded,
            selected: value == 'taken',
            color: AppColors.danger,
            onTap: () => onChanged('taken'),
          ),
        ],
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Contact picker tile ────────────────────────────────────────────────────────

class _ContactPickerTile extends ConsumerWidget {
  const _ContactPickerTile({required this.selected, required this.onSelect});
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () => _showPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected != null ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: selected == null
            ? Row(
                children: [
                  Icon(Icons.person_search_rounded, color: cs.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 10),
                  Text(
                    'Select person…',
                    style: TextStyle(color: cs.onSurface.withOpacity(0.55), fontSize: 15),
                  ),
                ],
              )
            : Row(
                children: [
                  _MiniAvatar(
                    name: selected!['name'].toString(),
                    isGuest: selected!['isGuest'] == true,
                    avatarUrl: selected!['avatarUrl']?.toString(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selected!['name'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.4)),
                ],
              ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactPickerSheet(ref: ref),
    );
    if (picked != null) onSelect(picked);
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.name, required this.isGuest, this.avatarUrl});
  final String name;
  final bool isGuest;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isGuest
            ? AppColors.warn.withOpacity(0.2)
            : AppColors.primary.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isGuest ? AppColors.warn : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Contact picker bottom sheet ────────────────────────────────────────────────

class ContactPickerSheet extends ConsumerStatefulWidget {
  const ContactPickerSheet({super.key, required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends ConsumerState<ContactPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guestAsync = ref.watch(guestContactsProvider);
    final appUsersAsync = ref.watch(appUsersProvider);
    final theme = Theme.of(context);

    final guests = guestAsync.valueOrNull ?? [];
    final appUsers = appUsersAsync.valueOrNull ?? [];

    final q = _query.toLowerCase();
    final filteredGuests = q.isEmpty
        ? guests
        : guests.where((c) => c.name.toLowerCase().contains(q)).toList();
    final filteredUsers = q.isEmpty
        ? appUsers
        : appUsers.where((u) => (u['name'] ?? '').toString().toLowerCase().contains(q)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  const Text(
                    'Select Person',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Add guest'),
                    onPressed: () => _showAddGuest(context),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by name…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  if (filteredGuests.isNotEmpty) ...[
                    _SectionHeader('Guest contacts'),
                    for (final c in filteredGuests)
                      _ContactRow(
                        id: c.id,
                        name: c.name,
                        subtitle: c.phone ?? c.email ?? '',
                        isGuest: true,
                        onTap: () => Navigator.pop(context, {
                          '_id': c.id,
                          'name': c.name,
                          'avatarUrl': null,
                          'isGuest': true,
                        }),
                      ),
                  ],
                  if (filteredUsers.isNotEmpty) ...[
                    _SectionHeader('App users'),
                    for (final u in filteredUsers)
                      _ContactRow(
                        id: u['_id'].toString(),
                        name: u['name'].toString(),
                        subtitle: u['email']?.toString() ?? '',
                        isGuest: false,
                        avatarUrl: u['avatarUrl']?.toString(),
                        onTap: () => Navigator.pop(context, {
                          '_id': u['_id'].toString(),
                          'name': u['name'].toString(),
                          'avatarUrl': u['avatarUrl']?.toString(),
                          'isGuest': false,
                        }),
                      ),
                  ],
                  if (filteredGuests.isEmpty && filteredUsers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          _query.isEmpty
                              ? 'No contacts yet.\nTap "Add guest" to add one.'
                              : 'No results for "$_query"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddGuest(BuildContext context) async {
    final added = await showModalBottomSheet<GuestContactModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddGuestSheet(),
    );
    if (added != null && mounted) {
      Navigator.pop(context, {
        '_id': added.id,
        'name': added.name,
        'avatarUrl': null,
        'isGuest': true,
      });
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.isGuest,
    this.avatarUrl,
    required this.onTap,
  });
  final String id;
  final String name;
  final String subtitle;
  final bool isGuest;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isGuest
              ? AppColors.warn.withOpacity(0.2)
              : AppColors.primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isGuest ? AppColors.warn : AppColors.primary,
            ),
          ),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: isGuest
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warn.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Guest',
                  style: TextStyle(fontSize: 10, color: AppColors.warn, fontWeight: FontWeight.w700)),
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ── Add guest contact sheet ────────────────────────────────────────────────────

class _AddGuestSheet extends ConsumerStatefulWidget {
  const _AddGuestSheet();

  @override
  ConsumerState<_AddGuestSheet> createState() => _AddGuestSheetState();
}

class _AddGuestSheetState extends ConsumerState<_AddGuestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(loanRepositoryProvider);
      final id = await repo.addGuestContact(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, GuestContactModel(
          id: id,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        ));
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                const Text('Add Guest Contact',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full name *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Add Contact',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
