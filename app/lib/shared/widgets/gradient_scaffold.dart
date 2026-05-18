import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// A scaffold with a soft aurora background behind content.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.padding,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final EdgeInsetsGeometry? padding;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _Aurora(dark: isDark)),
          SafeArea(
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Aurora extends StatelessWidget {
  const _Aurora({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkBg : AppColors.lightBg,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120, left: -80,
            child: _blob(color: AppColors.primary.withOpacity(dark ? 0.30 : 0.18), size: 320),
          ),
          Positioned(
            top: 120, right: -90,
            child: _blob(color: AppColors.accent.withOpacity(dark ? 0.22 : 0.16), size: 280),
          ),
          Positioned(
            bottom: -100, left: -40,
            child: _blob(color: const Color(0xFF44C4FF).withOpacity(dark ? 0.18 : 0.14), size: 240),
          ),
        ],
      ),
    );
  }

  Widget _blob({required Color color, required double size}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 120, spreadRadius: 40),
          ],
        ),
      );
}
