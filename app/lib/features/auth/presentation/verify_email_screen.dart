import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/auth_header.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.currency,
  });

  final String name;
  final String email;
  final String password;
  final String currency;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final List<TextEditingController> _ctrs = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  int _cooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    for (final c in _ctrs) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 0) {
        t.cancel();
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  String get _otp => _ctrs.map((c) => c.text).join();

  Future<void> _submit() async {
    if (_otp.length < 6) {
      showErrorSnack(context, 'Enter all 6 digits', fallback: 'Enter all 6 digits');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).register(
            name: widget.name,
            email: widget.email,
            password: widget.password,
            currency: widget.currency,
            otp: _otp,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Verification failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(authProvider.notifier).sendOtp(widget.email);
      if (mounted) {
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent to your email')),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not resend code');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Widget _buildDigitBox(int i) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Borders must be clearly visible regardless of background.
    // Light: medium grey-lavender against white fill.
    // Dark:  soft indigo-grey against dark fill.
    final borderColor = isDark ? const Color(0xFF5B5B72) : const Color(0xFFA2A2AE);
    final fillColor   = isDark ? const Color(0xFF1C1C28) : Colors.white;
    final textColor   = isDark ? const Color(0xFFE9E9F2) : const Color(0xFF111126);
    return SizedBox(
      width: 50,
      height: 62,
      child: TextFormField(
        controller: _ctrs[i],
        focusNode: _nodes[i],
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.0,
          color: textColor,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && i < 5) {
            _nodes[i + 1].requestFocus();
          }
          if (v.isEmpty && i > 0) {
            _nodes[i - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          const AuthHeader(backTarget: '/register'),
          const SizedBox(height: 32),
          const Text(
            'Verify your email',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to\n${widget.email}',
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFC857), width: 1),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB8860B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Can't find the email? Check your spam / junk folder.",
                    style: TextStyle(fontSize: 13, color: Color(0xFF7A5800)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, _buildDigitBox),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Verify & Create Account',
            loading: _loading,
            onPressed: _otp.length == 6 ? _submit : null,
          ),
          const SizedBox(height: 20),
          Center(
            child: _resending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _cooldown == 0 ? _resend : null,
                    child: Text(
                      _cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code',
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('← Change email'),
            ),
          ),
        ],
      ),
    );
  }
}
