import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../activity/providers/unread_provider.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    ('/home', Icons.dashboard_rounded, 'Home'),
    ('/groups', Icons.groups_rounded, 'Groups'),
    ('/friends', Icons.people_alt_rounded, 'Friends'),
    ('/activity', Icons.notifications_rounded, 'Activity'),
    ('/profile', Icons.person_rounded, 'Profile'),
  ];

  int _indexOfLocation(String loc) {
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexOfLocation(location);
    final unread = ref.watch(unreadActivityProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: _tabs[i].$1 == '/activity'
                  ? _Badged(count: unread, child: Icon(_tabs[i].$2, size: 22))
                  : Icon(_tabs[i].$2, size: 22),
              selectedIcon: _tabs[i].$1 == '/activity'
                  ? _Badged(count: unread, child: Icon(_tabs[i].$2, color: AppColors.primary, size: 22))
                  : Icon(_tabs[i].$2, color: AppColors.primary, size: 22),
              label: _tabs[i].$3,
            ),
        ],
      ),
    );
  }
}

class _Badged extends StatelessWidget {
  const _Badged({required this.count, required this.child});
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        Positioned(
          top: -6,
          right: -10,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: count > 9 ? 5 : 4,
              vertical: 2,
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
