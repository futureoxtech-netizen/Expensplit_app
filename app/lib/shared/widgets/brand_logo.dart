import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// The Expensplit brand mark. Renders `assets/images/logo.png`, which
/// has already been cropped to the visible artwork with a small
/// uniform margin — so the widget can stay simple and the displayed
/// glyph genuinely matches the requested [size].
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 72,
    this.radius,
    this.showGradientBackdrop = false,
    this.showWhiteBackdrop = false,
  });

  final double size;
  final double? radius;
  final bool showGradientBackdrop;
  final bool showWhiteBackdrop;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.24;

    final glyph = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(r),
        ),
        child: Icon(
          Icons.account_balance_wallet_rounded,
          size: size * 0.55,
          color: Colors.white,
        ),
      ),
    );

    if (!showGradientBackdrop && !showWhiteBackdrop) return glyph;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        color: showWhiteBackdrop ? Colors.white : null,
        gradient: showGradientBackdrop ? AppColors.brandGradient : null,
        boxShadow: [
          BoxShadow(
            color: (showWhiteBackdrop ? Colors.black : AppColors.primary)
                .withOpacity(0.18),
            blurRadius: size * 0.32,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          Icons.account_balance_wallet_rounded,
          size: size * 0.55,
          color: showWhiteBackdrop ? AppColors.primary : Colors.white,
        ),
      ),
    );
  }
}

/// Word-mark "Expensplit" in the brand typeface. Used standalone or
/// inside [BrandLockup].
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.fontSize = 22,
    this.color,
  });

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      'Expensplit',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: color ?? Colors.white,
        height: 1.0,
      ),
    );

    if (color != null) return text;

    return ShaderMask(
      shaderCallback: (rect) => AppColors.brandGradient.createShader(rect),
      child: text,
    );
  }
}

/// Logo + wordmark pair with proper baseline alignment. [alignment]
/// controls horizontal positioning (defaults to start, i.e. left).
/// [spacing] is the gap between the glyph and the wordmark — kept
/// tight by default so the lockup reads as a single unit.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.logoSize = 36,
    this.wordmarkFontSize,
    this.axis = Axis.horizontal,
    this.spacing = 8,
    this.wordmarkColor,
    this.alignment = MainAxisAlignment.start,
  });

  final double logoSize;
  final double? wordmarkFontSize;
  final Axis axis;
  final double spacing;
  final Color? wordmarkColor;

  /// Horizontal alignment when [axis] is horizontal. Defaults to
  /// [MainAxisAlignment.start] (left). Set to [MainAxisAlignment.center]
  /// for hero/header lockups.
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final fs = wordmarkFontSize ?? logoSize * 0.62;
    final logo = BrandLogo(size: logoSize);
    final wordmark = BrandWordmark(fontSize: fs, color: wordmarkColor);

    if (axis == Axis.horizontal) {
      return Row(
        mainAxisAlignment: alignment,
        mainAxisSize: alignment == MainAxisAlignment.start
            ? MainAxisSize.max
            : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [logo, SizedBox(width: spacing), wordmark],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [logo, SizedBox(height: spacing), wordmark],
    );
  }
}
