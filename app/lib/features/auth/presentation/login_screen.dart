import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart' show GoogleSignInButton;

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
  String? _errorCode; // tracks special error codes for inline UI

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorCode = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      if (e is Failure && e.code == 'USE_GOOGLE') {
        setState(() => _errorCode = 'USE_GOOGLE');
      } else if (e is Failure && e.code == 'USER_NOT_FOUND') {
        setState(() => _errorCode = 'USER_NOT_FOUND');
      } else {
        showErrorSnack(context, e, fallback: 'Login failed');
      }
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
            const Center(child: BrandLogo(size: 84, showWhiteBackdrop: true)),
            const SizedBox(height: 20),
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
            const SizedBox(height: 28),
            AppTextField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              onChanged: (_) { if (_errorCode != null) setState(() => _errorCode = null); },
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
              onChanged: (_) { if (_errorCode != null) setState(() => _errorCode = null); },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/forgot-password'),
                child: const Text('Forgot password?'),
              ),
            ),
            // ── Inline error banners ──────────────────────────────────────
            if (_errorCode == 'USE_GOOGLE') ...[
              const SizedBox(height: 4),
              _InlineBanner(
                color: const Color(0xFF4285F4),
                icon: Icons.account_circle_rounded,
                title: 'This account uses Google Sign-In',
                body: 'Use the "Continue with Google" button below to sign in.',
              ),
            ],
            if (_errorCode == 'USER_NOT_FOUND') ...[
              const SizedBox(height: 4),
              _InlineBanner(
                color: AppColors.warn,
                icon: Icons.person_search_rounded,
                title: 'No account found',
                body: 'There is no account with this email. Would you like to create one?',
                action: TextButton(
                  onPressed: () => context.go('/register'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.warn,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Create account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(label: 'Sign in', loading: _loading, onPressed: _submit),
            const SizedBox(height: 8),
            GoogleSignInButton(),
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

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13, color: color)),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(fontSize: 12, color: color.withOpacity(0.85))),
                if (action != null) ...[const SizedBox(height: 4), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
