import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/payment_method_model.dart';
import 'payment_form_sheet.dart';
import 'payment_method_tile.dart';

/// Profile → Payment information. Lets the user save reusable payment methods
/// (bank, wallets, PayPal…) that they can later share/import inside a group.
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  bool _busy = false;

  Future<void> _add() async {
    final input = await showPaymentFormSheet(context);
    if (input == null) return;
    await _run(() => ref.read(authProvider.notifier).addPaymentMethod(input),
        success: 'Payment method added');
  }

  Future<void> _edit(PaymentMethodModel m) async {
    final input = await showPaymentFormSheet(context, initial: m);
    if (input == null) return;
    await _run(() => ref.read(authProvider.notifier).updatePaymentMethod(m.id, input),
        success: 'Payment method updated');
  }

  Future<void> _delete(PaymentMethodModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove payment method?'),
        content: Text('“${m.title}” will be removed from your profile.'),
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
    await _run(() => ref.read(authProvider.notifier).deletePaymentMethod(m.id),
        success: 'Payment method removed');
  }

  Future<void> _run(Future<void> Function() action, {required String success}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showSuccessSnack(context, success);
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Something went wrong');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final methods = ref.watch(authProvider.select((s) => s.user?.paymentMethods ?? const []));

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Payment information'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _add,
        icon: const Icon(Icons.add),
        label: const Text('Add method'),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: methods.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'No payment methods yet',
                  subtitle:
                      'Save your bank account or wallet so you can quickly share it in a group and get paid back.',
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 2),
                  child: Text(
                    'These are private until you choose to share one inside a group.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                for (final m in methods)
                  PaymentMethodTile(
                    method: m,
                    onEdit: _busy ? null : () => _edit(m),
                    onDelete: _busy ? null : () => _delete(m),
                  ),
              ],
            ),
    );
  }
}
