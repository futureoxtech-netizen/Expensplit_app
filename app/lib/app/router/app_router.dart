import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/groups/presentation/groups_screen.dart';
import '../../features/groups/presentation/group_detail_screen.dart';
import '../../features/groups/presentation/create_group_screen.dart';
import '../../features/groups/presentation/edit_group_screen.dart';
import '../../features/groups/presentation/join_group_screen.dart';
import '../../features/expenses/presentation/add_expense_screen.dart';
import '../../features/expenses/presentation/expense_detail_screen.dart';
import '../../features/expenses/presentation/all_groups_feed_screen.dart';
import '../../features/expenses/data/expense_model.dart';
import '../../features/auth/data/user_model.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/groups/presentation/friends_summary_screen.dart';
import '../../features/groups/presentation/friend_detail_screen.dart';
import '../../features/groups/data/friend_summary_model.dart';
import '../../features/personal/presentation/personal_tracker_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/verify_reset_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/goals/presentation/goals_screen.dart';
import '../../features/goals/presentation/goal_detail_screen.dart';

/// Shared by GoRouter and any service that needs a root overlay or navigator
/// outside the widget tree (e.g. [InAppBanner]). Don't pass new instances to
/// GoRouter — keep this one stable for the app lifetime.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRefresh(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      // Read fresh auth state on every redirect — capturing it from the
      // outer closure would keep the value from the time GoRouter was built.
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final status = auth.status;
      final loggedIn = status == AuthStatus.authenticated;
      final goingToAuth = loc == '/login' ||
          loc == '/register' ||
          loc == '/verify-email' ||
          loc == '/forgot-password' ||
          loc == '/verify-reset' ||
          loc == '/reset-password' ||
          loc == '/onboarding' ||
          loc == '/splash';

      // While bootstrap is still in flight, sit on splash.
      if (status == AuthStatus.unknown) return loc == '/splash' ? null : '/splash';

      // Bootstrap finished — leave the splash for the right destination.
      if (loc == '/splash') return loggedIn ? '/home' : '/onboarding';

      if (!loggedIn && !goingToAuth) return '/onboarding';
      if (loggedIn && goingToAuth) return '/home';
      return null;
    },
    routes: [
      // Splash uses a plain fade (no zoom/slide) so the handoff to the
      // app shell is a clean crossfade. The default Android zoom
      // transition left the outgoing splash logo visibly layered over
      // the incoming dashboard mid-animation — a half-blurred frame with
      // an empty band on one side. A fade removes that entirely.
      GoRoute(
        path: '/splash',
        pageBuilder: (_, __) => _fadePage(const SplashScreen()),
      ),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return VerifyEmailScreen(
            name: extra['name'] as String,
            email: extra['email'] as String,
            password: extra['password'] as String,
            currency: extra['currency'] as String,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-reset',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return VerifyResetScreen(email: extra['email'] as String);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ResetPasswordScreen(
            email: extra['email'] as String,
            otp: extra['otp'] as String,
          );
        },
      ),

      ShellRoute(
        // Fade the shell in so leaving the splash is a smooth crossfade
        // rather than the OS zoom. Tab switches inside the shell are
        // child routes and are unaffected by this page transition.
        pageBuilder: (context, state, child) =>
            _fadePage(HomeShell(child: child)),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/groups', builder: (_, __) => const GroupsScreen()),
          GoRoute(path: '/friends', builder: (_, __) => const FriendsSummaryScreen()),
          GoRoute(path: '/tracker', builder: (_, __) => const PersonalTrackerScreen()),
          GoRoute(path: '/goals', builder: (_, __) => const GoalsScreen()),
          GoRoute(path: '/activity', builder: (_, __) => const ActivityScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      GoRoute(path: '/groups/new', builder: (_, __) => const CreateGroupScreen()),
      GoRoute(path: '/groups/join', builder: (_, __) => const JoinGroupScreen()),
      GoRoute(
        path: '/friends/:id',
        builder: (_, s) {
          final f = s.extra as FriendSummary?;
          return FriendDetailScreen(
            friend: f!,
            friendId: s.pathParameters['id']!,
          );
        },
      ),
      GoRoute(path: '/expenses/all', builder: (_, __) => const AllGroupsFeedScreen()),
      GoRoute(
        path: '/groups/:id',
        builder: (_, s) => GroupDetailScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/groups/:id/edit',
        builder: (_, s) => EditGroupScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/groups/:id/expenses/new',
        builder: (_, s) => AddExpenseScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/expenses/:id',
        builder: (_, s) => ExpenseDetailScreen(expenseId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/expenses/:id/edit',
        builder: (_, s) {
          final expense = s.extra as ExpenseModel?;
          return AddExpenseScreen(initialExpense: expense ?? ExpenseModel(
            id: s.pathParameters['id']!,
            groupId: '',
            description: '',
            amount: 0,
            currency: 'PKR',
            category: 'other',
            splitMode: 'equal',
            paidBy: UserModel(id: '', name: '', email: ''),
            shares: [],
            spentAt: DateTime.now(),
          ));
        },
      ),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(
        path: '/profile/password',
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(
        path: '/goals/:id',
        builder: (_, s) => GoalDetailScreen(goalId: s.pathParameters['id']!),
      ),
    ],
  );
});

/// A page that crossfades in/out instead of using the platform's
/// default zoom/slide transition. Used for the splash → app-shell
/// handoff so the two screens never appear layered mid-animation.
CustomTransitionPage<void> _fadePage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }
}
