import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/brand_logo.dart';

/// The Flutter-side splash that takes over from the native Android
/// splash while auth state is bootstrapping. The native splash already
/// shows the logo on the dark background, so this screen's job is to
/// provide a clean, low-motion handoff — not a second "look at our
/// brand" moment.
///
/// Design notes:
///   • Logo sits centered with no decorative circle/backdrop. Most
///     professional apps (Stripe, Linear, Notion, Revolut) keep their
///     boot splash to a single centered glyph and let the brand colour
///     do the framing — we follow the same pattern.
///   • A barely-perceptible fade/scale (not a full zoom-in) prevents
///     the visible "pop" between native and Flutter splashes.
///   • A slim progress indicator anchored near the bottom communicates
///     that the app is doing work — silent splashes feel frozen on
///     slower devices.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Match the native splash, which flutter_native_splash renders white in
    // light mode and #0B0B12 in dark mode based on the system brightness.
    // Following the same brightness here keeps the native → Flutter handoff
    // seamless instead of flashing dark over a white native splash.
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final onBgColor = isDark ? Colors.white : AppColors.lightOnSurface;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOut,
                builder: (context, v, _) {
                  return Opacity(
                    opacity: v,
                    child: Transform.scale(
                      // Subtle 4% zoom-in — present but not theatrical.
                      scale: 0.96 + (0.04 * v),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BrandLogo(
                            size: 132,
                            variant: BrandLogoVariant.transparent,
                          ),
                          const SizedBox(height: 20),
                          const BrandWordmark(fontSize: 28),
                          const SizedBox(height: 10),
                          Text(
                            'Split bills. Stay friends.',
                            style: TextStyle(
                              color: onBgColor.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 36,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    onBgColor.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
