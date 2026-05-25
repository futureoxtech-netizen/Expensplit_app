import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/auth_header.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).resetPassword(
            email: widget.email,
            otp: widget.otp,
            newPassword: _passwordCtrl.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated! Please sign in.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not reset password');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GradientScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 16),
            const AuthHeader(backTarget: '/forgot-password'),
            const SizedBox(height: 32),
            const Text(
              'Set new password',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose a strong password for your account.',
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _passwordCtrl,
              label: 'New password',
              hint: 'At least 8 characters',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscure1,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure1 = !_obscure1),
                icon: Icon(
                    _obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
              validator: (v) => (v == null || v.length < 8) ? 'Minimum 8 characters' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _confirmCtrl,
              label: 'Confirm new password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscure2,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure2 = !_obscure2),
                icon: Icon(
                    _obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
              validator: (v) =>
                  (v != _passwordCtrl.text) ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Update Password',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
