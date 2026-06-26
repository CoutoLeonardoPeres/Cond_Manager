import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/auth/presentation/pages/accept_invite_page.dart';
import 'package:cond_manager/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:cond_manager/features/auth/presentation/pages/login_page.dart';
import 'package:cond_manager/features/auth/presentation/pages/register_page.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/presentation/pages/condominium_detail_page.dart';
import 'package:cond_manager/features/condominiums/presentation/pages/condominium_form_page.dart';
import 'package:cond_manager/features/condominiums/presentation/pages/condominiums_list_page.dart';
import 'package:cond_manager/features/access_logs/presentation/pages/access_logs_page.dart';
import 'package:cond_manager/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:cond_manager/features/shell/presentation/pages/app_shell_page.dart';
import 'package:cond_manager/features/tickets/presentation/pages/ticket_detail_page.dart';
import 'package:cond_manager/features/tickets/presentation/pages/ticket_form_page.dart';
import 'package:cond_manager/features/tickets/presentation/pages/tickets_list_page.dart';
import 'package:cond_manager/features/materials/presentation/pages/material_supplier_form_page.dart';
import 'package:cond_manager/features/materials/presentation/pages/material_detail_page.dart';
import 'package:cond_manager/features/materials/presentation/pages/material_form_page.dart';
import 'package:cond_manager/features/materials/presentation/pages/materials_page.dart';
import 'package:cond_manager/features/preventive/presentation/pages/preventive_page.dart';
import 'package:cond_manager/features/preventive/presentation/pages/preventive_plan_detail_page.dart';
import 'package:cond_manager/features/preventive/presentation/pages/preventive_plan_form_page.dart';
import 'package:cond_manager/features/providers/presentation/pages/provider_form_page.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/features/providers/presentation/pages/providers_list_page.dart';
import 'package:cond_manager/features/work_orders/presentation/pages/work_order_detail_page.dart';
import 'package:cond_manager/features/work_orders/presentation/pages/work_order_form_page.dart';
import 'package:cond_manager/features/work_orders/presentation/pages/work_orders_list_page.dart';
import 'package:cond_manager/features/financial/presentation/pages/financial_form_page.dart';
import 'package:cond_manager/features/financial/presentation/pages/financial_page.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:cond_manager/features/users/presentation/pages/user_form_page.dart';
import 'package:cond_manager/features/users/presentation/pages/users_page.dart';
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
      final isInviteRoute = state.matchedLocation.startsWith('/invite/');

      if (!isLoggedIn && !isAuthRoute && !isInviteRoute) return '/login';
      if (isLoggedIn && isAuthRoute) {
        final profile = ref.read(currentProfileProvider).valueOrNull;
        return profile?.permissions.homeRoute ?? '/';
      }
      if (isLoggedIn && !isAuthRoute) {
        final profile = ref.read(currentProfileProvider).valueOrNull;
        if (profile != null && !profile.permissions.canAccessRoute(state.matchedLocation)) {
          return profile.permissions.homeRoute;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/invite/:token',
        builder: (_, state) => AcceptInvitePage(
          token: state.pathParameters['token']!,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShellPage(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const DashboardPage(),
          ),
          GoRoute(
            path: '/condominiums/new',
            builder: (_, _) => const CondominiumFormPage(),
          ),
          GoRoute(
            path: '/condominiums/:id/edit',
            builder: (_, state) => CondominiumFormPage(
              condominiumId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/condominiums/:id',
            builder: (_, state) => CondominiumDetailPage(
              condominiumId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/condominiums',
            builder: (_, _) => const CondominiumsListPage(),
          ),
          GoRoute(
            path: '/tickets/new',
            builder: (_, _) => const TicketFormPage(),
          ),
          GoRoute(
            path: '/tickets/:id',
            builder: (_, state) => TicketDetailPage(
              ticketId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/tickets',
            builder: (_, _) => const TicketsListPage(),
          ),
          GoRoute(
            path: '/work-orders/new',
            builder: (_, state) => WorkOrderFormPage(
              initialTicketId: state.uri.queryParameters['ticketId'],
              initialCondominiumId: state.uri.queryParameters['condominiumId'],
            ),
          ),
          GoRoute(
            path: '/work-orders/:id',
            builder: (_, state) => WorkOrderDetailPage(
              workOrderId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/work-orders',
            builder: (_, _) => const WorkOrdersListPage(),
          ),
          GoRoute(
            path: '/providers/new',
            builder: (_, state) {
              final serviceTypeParam = state.uri.queryParameters['serviceType'];
              return ProviderFormPage(
                initialCondominiumId: state.uri.queryParameters['condominiumId'],
                initialServiceType: serviceTypeParam != null
                    ? ServiceType.fromValue(serviceTypeParam)
                    : null,
              );
            },
          ),
          GoRoute(
            path: '/providers/:id/edit',
            builder: (_, state) => ProviderFormPage(
              providerId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/providers',
            builder: (_, _) => const ProvidersListPage(),
          ),
          GoRoute(
            path: '/materials/suppliers/new',
            builder: (_, state) => MaterialSupplierFormPage(
              initialCondominiumId: state.uri.queryParameters['condominiumId'],
            ),
          ),
          GoRoute(
            path: '/materials/suppliers/:id/edit',
            builder: (_, state) => MaterialSupplierFormPage(
              supplierId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/materials/new',
            builder: (_, state) => MaterialFormPage(
              initialCondominiumId: state.uri.queryParameters['condominiumId'],
              initialServiceType: state.uri.queryParameters['serviceType'],
            ),
          ),
          GoRoute(
            path: '/materials/:id/edit',
            builder: (_, state) => MaterialFormPage(
              materialId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/materials/:id',
            builder: (_, state) => MaterialDetailPage(
              materialId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/materials',
            builder: (_, _) => const MaterialsPage(),
          ),
          GoRoute(
            path: '/preventive/new',
            builder: (_, _) => const PreventivePlanFormPage(),
          ),
          GoRoute(
            path: '/preventive/:id/edit',
            builder: (_, state) => PreventivePlanFormPage(
              planId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/preventive/:id',
            builder: (_, state) => PreventivePlanDetailPage(
              planId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/preventive',
            builder: (_, _) => const PreventivePage(),
          ),
          GoRoute(
            path: '/financial/new',
            builder: (_, state) {
              final scopeParam = state.uri.queryParameters['scope'];
              return FinancialFormPage(
                initialScope: scopeParam != null
                    ? FinancialScope.fromValue(scopeParam)
                    : null,
                initialCondominiumId: state.uri.queryParameters['condominiumId'],
              );
            },
          ),
          GoRoute(
            path: '/financial/:id/edit',
            builder: (_, state) => FinancialFormPage(
              recordId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/financial',
            builder: (_, _) => const FinancialPage(),
          ),
          GoRoute(
            path: '/users/new',
            builder: (_, _) => const UserFormPage(),
          ),
          GoRoute(
            path: '/users/:id/edit',
            builder: (_, state) => UserFormPage(
              profileId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/users',
            builder: (_, _) => const UsersPage(),
          ),
          GoRoute(
            path: '/access-logs',
            builder: (_, _) => const AccessLogsPage(),
          ),
        ],
      ),
    ],
  );
});

final _routerRefreshProvider = Provider<_RouterRefresh>((ref) {
  final notifier = _RouterRefresh();
  ref.listen(authStateProvider, (_, _) => notifier.refresh());
  ref.listen(currentProfileProvider, (_, _) => notifier.refresh());
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
