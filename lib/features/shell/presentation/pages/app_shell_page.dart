import 'package:cond_manager/core/modules/app_module_providers.dart';
import 'package:cond_manager/core/modules/app_module_switcher.dart';
import 'package:cond_manager/core/modules/company_module_access.dart';
import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/access_logs/presentation/providers/access_log_providers.dart';
import 'package:cond_manager/features/access_logs/presentation/widgets/access_session_scope.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShellPage extends ConsumerWidget {
  const AppShellPage({super.key, required this.child});

  final Widget child;

  static const _maintenanceDestinations = [
    _NavItem('/', Icons.dashboard_rounded, 'Dashboard'),
    _NavItem('/condominiums', Icons.apartment_rounded, 'Condomínios'),
    _NavItem('/tickets', Icons.support_agent_rounded, 'Chamados'),
    _NavItem('/work-orders', Icons.assignment_rounded, 'Ordens de Serviço'),
    _NavItem('/providers', Icons.engineering_rounded, 'Prestadores'),
    _NavItem('/materials', Icons.inventory_2_rounded, 'Materiais'),
    _NavItem('/preventive', Icons.event_repeat_rounded, 'Preventiva'),
    _NavItem('/financial', Icons.payments_rounded, 'Financeiro'),
    _NavItem('/users', Icons.people_rounded, 'Usuários'),
    _NavItem('/access-logs', Icons.history_rounded, 'Log de acesso'),
    _NavItem('/admin/modules', Icons.extension_rounded, 'Módulos'),
  ];

  static const _rentalDestinations = [
    _NavItem('/rental', Icons.dashboard_rounded, 'Início'),
    _NavItem('/rental/condominiums', Icons.apartment_rounded, 'Condomínios'),
    _NavItem('/rental/properties', Icons.home_work_rounded, 'Imóveis'),
    _NavItem('/rental/leases', Icons.description_rounded, 'Contratos'),
    _NavItem('/rental/bookings', Icons.event_available_rounded, 'Reservas'),
    _NavItem('/rental/calendar', Icons.view_timeline_rounded, 'Ocupação'),
    _NavItem('/rental/parties', Icons.people_rounded, 'Pessoas'),
    _NavItem('/rental/charges', Icons.payments_rounded, 'Cobranças'),
    _NavItem('/rental/reports', Icons.assessment_rounded, 'Relatórios'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.value;
    final perms = AppPermissions(profile);
    final moduleAccess = profile.modules;

    final activeModule = ref.watch(activeAppModuleProvider) ?? moduleAccess.defaultModule;

    if (ref.read(activeAppModuleProvider) == null && profile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeAppModuleProvider.notifier).state = moduleAccess.defaultModule;
      });
    }

    final allowedPaths = perms.allowedNavPathsForModule(activeModule);
    final allDestinations =
        activeModule == AppModule.rental ? _rentalDestinations : _maintenanceDestinations;

    final destinations =
        allDestinations.where((d) => allowedPaths.any((p) => d.path == p)).toList();

    if (destinations.isEmpty) {
      return const Center(child: Text('Sem módulos disponíveis para seu perfil.'));
    }

    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = destinations.indexWhere((d) {
      if (d.path == '/' || d.path == '/rental') {
        return location == d.path;
      }
      return location == d.path || location.startsWith('${d.path}/');
    });
    final safeIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final isWide = MediaQuery.sizeOf(context).width >= 960;

    final navItems = destinations
        .map((d) => ClayNavItem(icon: d.icon, label: d.label))
        .toList();

    final bottomCount = navItems.length.clamp(1, 5);
    final moduleLabel = activeModule == AppModule.rental ? 'Locação' : 'Manutenção';

    return AccessSessionScope(
      child: ClayScaffold(
        appBar: ClayAppBar(
          title: 'Cond Manager · $moduleLabel',
          actions: [
            const AppModuleSwitcher(),
            profileAsync.when(
              data: (profile) => ClaySurface(
                depth: ClayDepth.raised,
                radius: ClayTokens.radiusFull,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: ClayTokens.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (profile?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (MediaQuery.sizeOf(context).width > 500) ...[
                      const SizedBox(width: 10),
                      Text(
                        profile?.fullName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            ClaySurface(
              depth: ClayDepth.raised,
              radius: ClayTokens.radiusFull,
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.logout_rounded, size: 22),
                tooltip: 'Sair',
                color: ClayTokens.textSecondary,
                onPressed: () async {
                  await endAccessSessionTracking(ref);
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        bottomNavigationBar: isWide
            ? null
            : MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: AppTypography.navTextScaler),
                child: ClayBottomNav(
                  items: navItems.take(bottomCount).toList(),
                  selectedIndex: safeIndex.clamp(0, bottomCount - 1),
                  onSelected: (i) => context.go(destinations[i].path),
                ),
              ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isWide)
              MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: AppTypography.navTextScaler),
                child: SizedBox(
                  width: 240,
                  child: ClayNavRail(
                    items: navItems,
                    selectedIndex: safeIndex,
                    onSelected: (i) => context.go(destinations[i].path),
                  ),
                ),
              ),
            Expanded(
              child: ClipRRect(
                borderRadius: isWide
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(ClayTokens.radiusHero),
                      )
                    : BorderRadius.zero,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}
