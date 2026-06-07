import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../maintenance_provider.dart';

/// Full-screen, non-dismissible block shown while the backend maintenance
/// switch is on. The app can't be used until maintenance ends; the provider
/// keeps polling so this clears itself automatically.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = message.trim().isNotEmpty
        ? message.trim()
        : "We're doing some scheduled maintenance to improve Expensplit. "
            'Please check back in a little while — your data is safe.';

    // Block the back button entirely.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.build_rounded,
                          color: Colors.white, size: 46),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Under maintenance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(maintenanceProvider),
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      label: const Text('Try again',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
