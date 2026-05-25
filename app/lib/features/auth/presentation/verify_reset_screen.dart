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

class VerifyResetScreen extends ConsumerStatefulWidget {
  const VerifyResetScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyResetScreen> createState() => _VerifyResetScreenState();
}

class _VerifyResetScreenState extends ConsumerState<VerifyResetScreen> {
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
    for (final c in _ctrs) c.dispose();
    for (final n in _nodes) n.dispose();
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
      // Hit the verify-only endpoint so a wrong code fails fast here
      // instead of after the user has typed a new password.
      await ref.read(authProvider.notifier).verifyResetOtp(
            email: widget.email,
            otp: _otp,
          );
      if (mounted) {
        context.go('/reset-password', extra: {
          'email': widget.email,
          'otp': _otp,
        });
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Invalid or expired code');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(authProvider.notifier).sendForgotOtp(widget.email);
      if (mounted) {
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New reset code sent!')),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Failed to resend code');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GradientScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          const AuthHeader(backTarget: '/forgot-password'),
          const SizedBox(height: 32),
          const Text(
            'Check your email',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.65)),
              children: [
                const TextSpan(text: 'We sent a 6-digit reset code to '),
                TextSpan(
                  text: widget.email,
                  style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
              ],
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
          const SizedBox(height: 24),
          Builder(builder: (context) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final borderColor = isDark ? const Color(0xFF5B5B72) : const Color(0xFFA2A2AE);
            final fillColor   = isDark ? const Color(0xFF1C1C28) : Colors.white;
            final textColor   = isDark ? const Color(0xFFE9E9F2) : const Color(0xFF111126);
            return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              return SizedBox(
                width: 50,
                height: 62,
                child: TextField(
                  controller: _ctrs[i],
                  focusNode: _nodes[i],
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    color: textColor,
                  ),
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
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) {
                      _nodes[i + 1].requestFocus();
                    } else if (v.isEmpty && i > 0) {
                      _nodes[i - 1].requestFocus();
                    }
                    setState(() {});
                  },
                ),
              );
            }),
          ); // end Builder
          }),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Verify Code',
            loading: _loading,
            onPressed: _otp.length == 6 ? _submit : null,
          ),
          const SizedBox(height: 16),
          Center(
            child: _cooldown > 0
                ? Text(
                    'Resend code in ${_cooldown}s',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
                  )
                : TextButton(
                    onPressed: _resending ? null : _resend,
                    child: _resending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend code'),
                  ),
          ),
        ],
      ),
    );
  }
}
