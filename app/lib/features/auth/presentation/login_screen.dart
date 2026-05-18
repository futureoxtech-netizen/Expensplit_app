import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 40),
            const Text('Welcome back',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 8),
            Text(
              'Sign in to keep your expenses in check.',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordCtrl,
              label: 'Password',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
              onSubmitted: (_) => _submit(),
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Sign in', loading: _loading, onPressed: _submit),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go('/register'),
                child: const Text("Don't have an account? Create one"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
