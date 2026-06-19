import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'brand_logo.dart';

/// A compact, consistent header for secondary auth screens (forgot
/// password, verify email, reset password, etc.). Renders a left-side
/// back button followed by a left-aligned inline brand lockup so the
/// screen has identity without a huge centered logo eating vertical space.
///
/// For the *primary* auth screens (login, register) prefer a centered
/// [BrandLogo] hero instead of this header.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.backTarget,
    this.onBack,
    this.showWordmark = true,
  });

  /// Route to navigate to when the back button is tapped. If null and
  /// [onBack] is also null, the button is hidden.
  final String? backTarget;

  /// Custom back handler. Takes precedence over [backTarget].
  final VoidCallback? onBack;

  /// Whether to show the "Expensplit" wordmark next to the small logo.
  /// Hide it when vertical space is at a premium.
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasBack = onBack != null || backTarget != null;

    return SizedBox(
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasBack)
            _BackButton(
              onTap: onBack ?? () => context.go(backTarget!),
              color: cs.onSurface,
            )
          else
            const SizedBox(width: 4),
          const SizedBox(width: 10),
          if (showWordmark)
            const BrandLockup(
              logoSize: 28,
              wordmarkFontSize: 16,
              spacing: 6,
              alignment: MainAxisAlignment.start,
            )
          else
            const BrandLogo(size: 32),
          const Spacer(),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap, required this.color});
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: color.withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}
