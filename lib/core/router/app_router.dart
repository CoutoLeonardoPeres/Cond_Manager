import 'package:cond_manager/core/modules/app_module_providers.dart';
import 'package:cond_manager/core/modules/company_module_access.dart';
import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/auth/presentation/pages/accept_invite_page.dart';
import 'package:cond_manager/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:cond_manager/features/auth/presentation/pages/login_page.dart';
import 'package:cond_manager/features/auth/presentation/pages/register_page.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/presentation/condominium_route_prefix.dart';
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
import 'package:cond_manager/features/modules/presentation/pages/company_modules_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_booking_form_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_bookings_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_calendar_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_charge_form_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_charges_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_expense_detail_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_expense_form_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_expenses_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_dashboard_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_lease_form_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_leases_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_parties_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_tenant_intake_link_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/public_tenant_intake_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_party_form_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_properties_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_property_form_page.dart';
import 'package:cond_manager/features/rental/presentation/pages/rental_property_report_page.dart';
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
      final path = state.uri.path;
      final isAuthRoute = path.startsWith('/login') ||
          path.startsWith('/register') ||
          path.startsWith('/forgot-password');
      final isInviteRoute = path.startsWith('/invite/');
      final isPublicIntakeRoute = path.startsWith('/cadastro-locatario/');

      if (!isLoggedIn && !isAuthRoute && !isInviteRoute && !isPublicIntakeRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        final profile = ref.read(currentProfileProvider).valueOrNull;
        return profile?.permissions.homeRoute ?? '/';
      }
      // Rotas públicas — não redirecionar para o painel (manutenção/locação).
      if (isInviteRoute || isPublicIntakeRoute) return null;

      if (isLoggedIn && !isAuthRoute) {
        final profile = ref.read(currentProfileProvider).valueOrNull;
        if (profile != null && !profile.permissions.canAccessRoute(path)) {
          final active =
              ref.read(activeAppModuleProvider) ?? profile.modules.defaultModule;
          return profile.permissions.homeRouteForModule(active);
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
      GoRoute(
        path: '/cadastro-locatario/:token',
        builder: (_, state) => PublicTenantIntakePage(
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
          GoRoute(
            path: '/rental',
            builder: (_, _) => const RentalDashboardPage(),
          ),
          GoRoute(
            path: '/rental/properties/new',
            builder: (_, _) => const RentalPropertyFormPage(),
          ),
          GoRoute(
            path: '/rental/properties/:id/edit',
            builder: (_, state) => RentalPropertyFormPage(
              propertyId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/rental/properties',
            builder: (_, _) => const RentalPropertiesPage(),
          ),
          GoRoute(
            path: '/rental/leases/new',
            builder: (_, _) => const RentalLeaseFormPage(),
          ),
          GoRoute(
            path: '/rental/leases/:id/edit',
            builder: (_, state) => RentalLeaseFormPage(
              leaseId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/rental/leases',
            builder: (_, _) => const RentalLeasesPage(),
          ),
          GoRoute(
            path: '/rental/bookings/new',
            builder: (_, state) => RentalBookingFormPage(
              initialPropertyId: state.uri.queryParameters['propertyId'],
            ),
          ),
          GoRoute(
            path: '/rental/bookings/:id/edit',
            builder: (_, state) => RentalBookingFormPage(
              bookingId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/rental/bookings',
            builder: (_, _) => const RentalBookingsPage(),
          ),
          GoRoute(
            path: '/rental/parties/intake-link',
            builder: (_, _) => const RentalTenantIntakeLinkPage(),
          ),
          GoRoute(
            path: '/rental/parties/new',
            builder: (_, _) => const RentalPartyFormPage(),
          ),
          GoRoute(
            path: '/rental/parties/:id/edit',
            builder: (_, state) => RentalPartyFormPage(
              partyId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/rental/parties',
            builder: (_, _) => const RentalPartiesPage(),
          ),
          GoRoute(
            path: '/rental/charges/new',
            builder: (_, _) => const RentalChargeFormPage(),
          ),
          GoRoute(
            path: '/rental/charges/:id/edit',
            builder: (_, state) => RentalChargeFormPage(
              chargeId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/rental/charges',
            builder: (_, _) => const RentalChargesPage(),
          ),
          GoRoute(
            path: '/rental/expenses/new',
            builder: (_, _) => const RentalExpenseFormPage(),
          ),
          GoRoute(
            path: '/rental/expenses/:id/edit',
            builder: (_, state) => RentalExpenseFormPage(
              expenseId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/rental/expenses/:id',
            builder: (_, state) => RentalExpenseDetailPage(
              expenseId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/rental/expenses',
            builder: (_, _) => const RentalExpensesPage(),
          ),
          GoRoute(
            path: '/rental/calendar',
            builder: (_, _) => const RentalCalendarPage(),
          ),
          GoRoute(
            path: '/rental/condominiums/new',
            builder: (_, _) => const CondominiumFormPage(
              routePrefix: CondominiumRoutePrefix.rental,
            ),
          ),
          GoRoute(
            path: '/rental/condominiums/:id/edit',
            builder: (_, state) => CondominiumFormPage(
              condominiumId: state.pathParameters['id'],
              routePrefix: CondominiumRoutePrefix.rental,
            ),
          ),
          GoRoute(
            path: '/rental/condominiums/:id',
            builder: (_, state) => CondominiumDetailPage(
              condominiumId: state.pathParameters['id']!,
              routePrefix: CondominiumRoutePrefix.rental,
            ),
          ),
          GoRoute(
            path: '/rental/condominiums',
            builder: (_, _) => const CondominiumsListPage(
              routePrefix: CondominiumRoutePrefix.rental,
            ),
          ),
          GoRoute(
            path: '/rental/reports',
            builder: (_, _) => const RentalPropertyReportPage(),
          ),
          GoRoute(
            path: '/admin/modules',
            builder: (_, _) => const CompanyModulesPage(),
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
  ref.listen(activeAppModuleProvider, (_, _) => notifier.refresh());
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
