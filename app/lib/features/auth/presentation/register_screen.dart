import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _currency = 'USD';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).register(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            currency: _currency,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Registration failed');
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
            const SizedBox(height: 32),
            const Text('Create your account',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 8),
            Text(
              "It takes less than a minute. We'll keep things tidy.",
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 28),
            AppTextField(
              controller: _nameCtrl,
              label: 'Full name',
              prefixIcon: Icons.badge_outlined,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _emailCtrl,
              label: 'Email',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _passwordCtrl,
              label: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
              validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: const InputDecoration(labelText: 'Default currency'),
              items: const ['USD', 'EUR', 'GBP', 'INR', 'PKR', 'JPY', 'CAD', 'AUD']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? 'USD'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Create account', loading: _loading, onPressed: _submit),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
