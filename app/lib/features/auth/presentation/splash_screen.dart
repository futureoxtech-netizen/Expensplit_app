import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

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
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: AppColors.brandGradient,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 44),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
