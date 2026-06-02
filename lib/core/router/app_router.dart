import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:cond_manager/features/auth/presentation/pages/login_page.dart';
import 'package:cond_manager/features/auth/presentation/pages/register_page.dart';
import 'package:cond_manager/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:cond_manager/features/shell/presentation/pages/app_shell_page.dart';
import 'package:cond_manager/shared/widgets/pages/clay_placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.value?.session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShellPage(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(
            path: '/condominiums',
            builder: (_, _) => const ClayPlaceholderPage(
              title: 'Condomínios',
              icon: Icons.apartment_rounded,
            ),
          ),
          GoRoute(
            path: '/tickets',
            builder: (_, _) => const ClayPlaceholderPage(
              title: 'Chamados',
              icon: Icons.support_agent_rounded,
            ),
          ),
          GoRoute(
            path: '/work-orders',
            builder: (_, _) => const ClayPlaceholderPage(
              title: 'Ordens de Serviço',
              icon: Icons.assignment_rounded,
            ),
          ),
          GoRoute(
            path: '/providers',
            builder: (_, _) => const ClayPlaceholderPage(
              title: 'Prestadores',
              icon: Icons.engineering_rounded,
            ),
          ),
          GoRoute(
            path: '/materials',
            builder: (_, _) => const ClayPlaceholderPage(
              title: 'Materiais',
              icon: Icons.inventory_2_rounded,
            ),
          ),
          GoRoute(
            path: '/preventive',
            builder: (_, _) => const ClayPlaceholderPage(
              title: 'Preventiva',
              icon: Icons.event_repeat_rounded,
            ),
          ),
          GoRoute(
            path: '/financial',
            builder: (_, _) => const ClayPlaceholderPage(
              title: 'Financeiro',
              icon: Icons.payments_rounded,
            ),
          ),
          GoRoute(
            path: '/users',
            builder: (_, _) => const ClayPlaceholderPage(
              title: 'Usuários',
              icon: Icons.people_rounded,
            ),
          ),
        ],
      ),
    ],
  );
});

final _routerRefreshProvider = Provider<_RouterRefresh>((ref) {
  final notifier = _RouterRefresh();
  ref.listen(authStateProvider, (_, _) => notifier.refresh());
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
