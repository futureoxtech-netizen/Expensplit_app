import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/avatar.dart';
import '../../activity/providers/unread_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../groups/presentation/friends_summary_screen.dart';
import '../../groups/presentation/groups_screen.dart';
import '../../groups/providers/group_providers.dart';
import '../../loans/providers/loan_providers.dart';
import '../../personal/presentation/personal_tracker_screen.dart';
import '../../settings/settings_providers.dart';

/// Five-tab bottom navigation with a "More" tab that opens a styled
/// modal sheet for the secondary destinations. Keeping the bar to five
/// items prevents the cramped seven-icon layout that felt cluttered
/// and unprofessional.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  // Drives the primary-tab pager. Created on demand (and recreated) so the
  // pager always mounts on the tab matching the current route. Null while on a
  // secondary route, where the routed `child` is shown instead.
  PageController? _pageCtrl;

  // The page the pager is currently on (its source of truth). Guards against
  // feeding a route change back into the pager that put it there.
  int _pageIndex = 0;

  // True while a tab-tap animation is driving the pager, so onPageChanged
  // doesn't fire a route change for each intermediate page it scrolls past.
  bool _programmaticMove = false;

  @override
  void dispose() {
    _pageCtrl?.dispose();
    super.dispose();
  }

  /// The screen widget for a primary tab path. Built directly (not via the
  /// router) so all tabs can live side-by-side in the [PageView] for a
  /// finger-tracking swipe, the way WhatsApp's pager works.
  Widget _screenForPath(String path) {
    switch (path) {
      case '/groups':
        return const GroupsScreen();
      case '/friends':
        return const FriendsSummaryScreen();
      case '/tracker':
        return const PersonalTrackerScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final modules = ref.watch(enabledModulesProvider);
    // Primary destinations — Home/Groups/Friends are always present; the
    // Personal Tracker tab only shows when its module is enabled. The "More"
    // button takes the final slot.
    final primaryTabs = <_NavItem>[
      const _NavItem('/home', Icons.dashboard_rounded, 'Home'),
      const _NavItem('/groups', Icons.groups_rounded, 'Groups'),
      const _NavItem('/friends', Icons.people_alt_rounded, 'Friends'),
      if (modules.contains(AppModule.tracker))
        const _NavItem('/tracker', Icons.track_changes_rounded, 'Tracker'),
    ];
    final primaryIndex = primaryTabs.indexWhere((t) => t.path == location);
    final isPrimary = primaryIndex >= 0;
    // Bottom-bar selection: a primary tab, or the "More" slot for secondaries.
    final index = isPrimary ? primaryIndex : primaryTabs.length;

    // Keep the pager in step with the route. Entering the pager (from a
    // secondary route or a deep link) recreates the controller so it mounts on
    // the right page; a tab tap while already in the pager animates to it.
    if (isPrimary) {
      if (_pageCtrl == null) {
        _pageIndex = primaryIndex;
        _pageCtrl = PageController(initialPage: primaryIndex);
      } else if (primaryIndex != _pageIndex) {
        _pageIndex = primaryIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final c = _pageCtrl;
          if (c != null && c.hasClients) {
            c.animateToPage(primaryIndex,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic);
          }
        });
      }
    } else if (_pageCtrl != null) {
      // Leaving the pager — dispose after this frame (the PageView is no longer
      // built, so its controller is safely detached by then).
      final old = _pageCtrl;
      _pageCtrl = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
    }

    final unread = ref.watch(unreadActivityProvider);
    // Pending group-invite count → badge on the Groups tab for discoverability.
    final inviteCount = ref.watch(myInvitesProvider).maybeWhen(
          data: (invites) => invites.length,
          orElse: () => 0,
        );
    final isHome = location == '/home';

    // Tabs navigate with `context.go`, which replaces the route rather than
    // stacking it — so at a tab root the back stack is empty and the system
    // back button would otherwise exit the app. Intercept that: anywhere
    // other than the dashboard, back returns to the dashboard first. On the
    // dashboard (or any genuinely pushed route, where canPop is true) we let
    // the default behaviour run.
    return PopScope(
      canPop: isHome || context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        // Primary tabs live in a finger-tracking PageView (swipe follows the
        // drag, half-and-half, like WhatsApp). Secondary routes render the
        // routed child as before. The bottom bar stays put either way.
        body: isPrimary
            ? PageView(
                controller: _pageCtrl,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (i) {
                  if (_programmaticMove) return;
                  if (i == _pageIndex || i >= primaryTabs.length) return;
                  _pageIndex = i;
                  context.go(primaryTabs[i].path);
                },
                children: [
                  for (final t in primaryTabs) _screenForPath(t.path),
                ],
              )
            : widget.child,
        bottomNavigationBar: NavigationBar(
          height: 70,
          selectedIndex: index,
          onDestinationSelected: (i) {
            if (i < primaryTabs.length) {
              // Tapping a primary tab while in the pager animates to it;
              // coming from a secondary route, navigate so the pager rebuilds
              // on that tab.
              _pageIndex = i;
              context.go(primaryTabs[i].path);
              final c = _pageCtrl;
              if (isPrimary && c != null && c.hasClients) {
                _programmaticMove = true;
                c
                    .animateToPage(i,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic)
                    .whenComplete(() => _programmaticMove = false);
              }
            } else {
              _showMoreSheet(context, location);
            }
          },
          destinations: [
            for (final t in primaryTabs)
              NavigationDestination(
                icon: _Badged(
                  count: t.path == '/groups' ? inviteCount : 0,
                  child: Icon(t.icon, size: 22),
                ),
                selectedIcon: _Badged(
                  count: t.path == '/groups' ? inviteCount : 0,
                  child:
                      Icon(t.icon, color: AppColors.primary, size: 22),
                ),
                label: t.label,
              ),
            NavigationDestination(
              icon: _Badged(
                count: unread,
                child: const Icon(Icons.grid_view_rounded, size: 22),
              ),
              selectedIcon: _Badged(
                count: unread,
                child: const Icon(Icons.grid_view_rounded,
                    color: AppColors.primary, size: 22),
              ),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMoreSheet(BuildContext context, String currentLoc) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _MoreSheet(currentLoc: currentLoc),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}

// ─── More sheet ─────────────────────────────────────────────────────────────

class _MoreSheet extends ConsumerWidget {
  const _MoreSheet({required this.currentLoc});
  final String currentLoc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final unread = ref.watch(unreadActivityProvider);
    final loansPending = ref.watch(pendingApprovalCountProvider);
    final mode = ref.watch(themeModeProvider);
    final modules = ref.watch(enabledModulesProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grip (hidden on wide screens since the dialog has no drag affordance)
          if (MediaQuery.of(context).size.width < 600)
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 8),
          // Profile header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Avatar(
                      name: user?.name ?? '?',
                      imageUrl: user?.avatarUrl,
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? '—',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: cs.onSurface.withOpacity(0.45)),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, color: cs.onSurface.withOpacity(0.08)),
          // Menu items
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (modules.contains(AppModule.goals))
                  _MoreTile(
                    icon: Icons.flag_rounded,
                    label: 'Goals',
                    subtitle: 'Track savings and spend targets',
                    selected: currentLoc.startsWith('/goals'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/goals');
                    },
                  ),
                if (modules.contains(AppModule.khata))
                  _MoreTile(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Khata Book',
                    subtitle: 'Track personal loans & dues',
                    selected: currentLoc.startsWith('/loans'),
                    badgeCount: loansPending,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/loans');
                    },
                  ),
                _MoreTile(
                  icon: Icons.notifications_rounded,
                  label: 'Activity',
                  subtitle: 'Notifications and recent updates',
                  selected: currentLoc.startsWith('/activity'),
                  badgeCount: unread,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/activity');
                  },
                ),
                if (modules.contains(AppModule.reports))
                  _MoreTile(
                    icon: Icons.insights_rounded,
                    label: 'Reports',
                    subtitle: 'Monthly insights and category breakdown',
                    selected: currentLoc.startsWith('/reports'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/reports');
                    },
                  ),
                const SizedBox(height: 8),
                _SectionLabel('Preferences'),
                _MoreTile(
                  icon: Icons.tune_rounded,
                  label: 'Modules',
                  subtitle: 'Turn features on or off',
                  selected: currentLoc.startsWith('/settings/modules'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings/modules');
                  },
                ),
                _MoreTile(
                  icon: Icons.person_rounded,
                  label: 'Profile & settings',
                  subtitle: 'Account, currency and privacy',
                  selected: currentLoc.startsWith('/profile'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/profile');
                  },
                ),
                _ThemeTile(
                  mode: mode,
                  onChanged: (m) => ref.read(themeModeProvider.notifier).set(m),
                ),
                const SizedBox(height: 16),
                // Sign out
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side:
                          BorderSide(color: AppColors.danger.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.selected = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool selected;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color:
            selected ? AppColors.primary.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: selected ? AppColors.primary : null,
                              ),
                            ),
                          ),
                          if (badgeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badgeCount > 99 ? '99+' : '$badgeCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurface.withOpacity(0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.mode, required this.onChanged});
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.palette_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Theme',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            _ThemeSegment(mode: mode, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({required this.mode, required this.onChanged});
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = <(ThemeMode, IconData, String)>[
    (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
    (ThemeMode.system, Icons.brightness_auto_rounded, 'Auto'),
    (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in _options)
            GestureDetector(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: mode == o.$1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  o.$2,
                  size: 16,
                  color: mode == o.$1
                      ? Colors.white
                      : cs.onSurface.withOpacity(0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Badge for nav items ────────────────────────────────────────────────────

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
