import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/auth_header.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();
      await ref.read(authProvider.notifier).sendForgotOtp(email);
      if (mounted) {
        context.go('/verify-reset', extra: {'email': email});
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not send reset code');
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
            const AuthHeader(backTarget: '/login'),
            const SizedBox(height: 32),
            const Text(
              'Forgot password?',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1),
            ),
            const SizedBox(height: 10),
            Text(
              "Enter the email address linked to your account and we'll send you a 6-digit reset code.",
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _emailCtrl,
              label: 'Email address',
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Send Reset Code',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Back to Sign In',
                  style: TextStyle(color: cs.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
