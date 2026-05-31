import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';

/// Lets a signed-in user change their password. The server verifies the
/// current password before applying the new one, so a wrong current password
/// (or a Google-only account) comes back as a friendly error here.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (mounted) {
        showSuccessSnack(context, 'Password updated');
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not change password');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Change password'),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
          children: [
            Text(
              'Enter your current password, then choose a new one.',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _currentCtrl,
              label: 'Current password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscureCurrent,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                icon: Icon(
                  _obscureCurrent
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your current password' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _newCtrl,
              label: 'New password',
              hint: 'At least 8 characters',
              prefixIcon: Icons.lock_reset_rounded,
              obscureText: _obscureNew,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 8) return 'Minimum 8 characters';
                if (v == _currentCtrl.text) {
                  return 'New password must be different';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmCtrl,
              label: 'Confirm new password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (v) =>
                  (v != _newCtrl.text) ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Update password',
              loading: _saving,
              onPressed: _submit,
            ),
            // const SizedBox(height: 16),
            // Center(
            //   child: TextButton(
            //     onPressed: () => context.go('/forgot-password'),
            //     child: const Text('Forgot your current password?'),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
