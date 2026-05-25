import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/brand_logo.dart';
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
      await ref.read(authProvider.notifier).sendOtp(_emailCtrl.text.trim());
      if (mounted) {
        context.go(
          '/verify-email',
          extra: {
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'password': _passwordCtrl.text,
            'currency': _currency,
          },
        );
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not send verification code');
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
            const SizedBox(height: 32),
            const Center(child: BrandLogo(size: 78, showWhiteBackdrop: true)),
            const SizedBox(height: 18),
            const Text('Create your account',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 8),
            Text(
              "It takes less than a minute. We'll keep things tidy.",
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface.withValues(alpha: 0.65),
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
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: 'Default currency'),
                items: const ['USD', 'EUR', 'GBP', 'INR', 'PKR', 'JPY', 'CAD', 'AUD']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v ?? 'USD'),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Sign Up',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            GoogleSignInButton(),
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

const _kGoogleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _loading = false;
  bool _pressed = false;

  Future<void> _handleTap() async {
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).googleSignIn();
      if (context.mounted) context.go('/home');
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().contains('cancelled') ? 'Sign-in cancelled' : 'Google sign-in failed';
        showErrorSnack(context, e, fallback: msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // ── OR divider ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // ── Button ────────────────────────────────────────────────────────────
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: _loading ? null : _handleTap,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF3A3A5A) : const Color(0xFFDDDDEE),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4285F4).withOpacity(_pressed ? 0.08 : 0.14),
                    blurRadius: _pressed ? 6 : 16,
                    spreadRadius: _pressed ? 0 : 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    SvgPicture.string(_kGoogleLogoSvg, height: 22, width: 22),
                  const SizedBox(width: 12),
                  Text(
                    _loading ? 'Signing in…' : 'Continue with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
