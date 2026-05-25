import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/brand_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, v, _) {
            return Opacity(
              opacity: v.clamp(0, 1),
              child: Transform.scale(
                scale: v,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 120, showGradientBackdrop: true),
                    const SizedBox(height: 16),
                    const BrandWordmark(fontSize: 30),
                    const SizedBox(height: 8),
                    Text(
                      'Split bills. Stay friends.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
