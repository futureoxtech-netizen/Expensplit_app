import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// The Expensplit brand mark. We have two source PNGs and they serve
/// different purposes — pick the right one for the surface:
///
///   • `assets/images/logo.png` — transparent glyph, no padding. Use
///     this when the logo sits over a coloured/gradient backdrop and
///     should blend seamlessly (splash screen, gradient hero cards).
///   • `assets/app_logo.png` — same glyph with a baked-in white
///     background and proper uniform spacing around the artwork. Use
///     this when the logo sits on a light surface or needs to read as
///     a self-contained tile (auth screens, About dialogs, share
///     previews). Also the source for the OS launcher icon.
///
/// The default ([variant: BrandLogoVariant.auto]) picks the right asset
/// based on whether a backdrop is being drawn. Callers can override
/// with [variant] when they need a specific look.
enum BrandLogoVariant {
  /// Pick automatically based on the requested backdrop: the framed
  /// (white-bg) asset only when [BrandLogo.showWhiteBackdrop] is on so
  /// the baked-in white merges with the surrounding circle; the
  /// transparent glyph in every other case (gradient backdrop, no
  /// backdrop, coloured cards). This keeps callers from accidentally
  /// rendering a white square on a non-white surface.
  auto,

  /// Force the transparent glyph (`assets/images/logo.png`).
  transparent,

  /// Force the white-background framed asset (`assets/app_logo.png`).
  framed,
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 72,
    this.radius,
    this.showGradientBackdrop = false,
    this.showWhiteBackdrop = false,
    this.variant = BrandLogoVariant.auto,
  });

  final double size;
  final double? radius;
  final bool showGradientBackdrop;
  final bool showWhiteBackdrop;
  final BrandLogoVariant variant;

  String get _assetPath {
    switch (variant) {
      case BrandLogoVariant.transparent:
        return 'assets/images/logo.png';
      case BrandLogoVariant.framed:
        return 'assets/app_logo.png';
      case BrandLogoVariant.auto:
        // The framed asset has a baked-in white background, so it only
        // composites cleanly when the surface behind it is also white
        // (i.e. [showWhiteBackdrop] is on). Everywhere else — gradient
        // backdrops or no backdrop on a coloured card — fall back to
        // the transparent glyph so we never show an unintended white
        // square around the logo.
        return showWhiteBackdrop
            ? 'assets/app_logo.png'
            : 'assets/images/logo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.24;
    final asset = _assetPath;

    Widget fallback({Color? color}) => Icon(
          Icons.account_balance_wallet_rounded,
          size: size * 0.55,
          color: color ?? Colors.white,
        );

    final glyph = Image.asset(
      asset,
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
        child: fallback(),
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
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => fallback(
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
