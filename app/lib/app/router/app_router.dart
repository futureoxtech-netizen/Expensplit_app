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
import '../../features/expenses/data/expense_model.dart';
import '../../features/auth/data/user_model.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRefresh(ref);

  return GoRouter(
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
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/groups', builder: (_, __) => const GroupsScreen()),
          GoRoute(path: '/activity', builder: (_, __) => const ActivityScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      GoRoute(path: '/groups/new', builder: (_, __) => const CreateGroupScreen()),
      GoRoute(path: '/groups/join', builder: (_, __) => const JoinGroupScreen()),
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
            currency: 'USD',
            category: 'other',
            splitMode: 'equal',
            paidBy: UserModel(id: '', name: '', email: ''),
            shares: [],
            spentAt: DateTime.now(),
          ));
        },
      ),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }
}
