import 'package:cond_manager/core/modules/app_module_providers.dart';
import 'package:cond_manager/core/modules/app_module_switcher.dart';
import 'package:cond_manager/core/modules/company_module_access.dart';
import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/features/access_logs/presentation/providers/access_log_providers.dart';
import 'package:cond_manager/features/access_logs/presentation/widgets/access_session_scope.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/shell/presentation/providers/mobile_nav_shortcuts_provider.dart';
import 'package:cond_manager/features/shell/presentation/widgets/mobile_nav_menu_sheet.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/shared/widgets/app_loading_scaffold.dart';
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
    _NavItem('/rental/expenses', Icons.receipt_long_rounded, 'Despesas'),
    _NavItem('/rental/reports', Icons.assessment_rounded, 'Relatórios'),
  ];

  static const _mobileNavPrimaryCount = 4;
  static const _mobileNavMenuPath = '__nav_menu__';

  static List<_NavItem> _mobileBottomItems(
    List<_NavItem> destinations,
    List<String> savedPaths,
  ) {
    if (destinations.length <= 5) return destinations;

    final picked = <_NavItem>[];
    for (final path in savedPaths) {
      if (picked.length >= _mobileNavPrimaryCount) break;
      for (final d in destinations) {
        if (d.path == path) {
          picked.add(d);
          break;
        }
      }
    }

    for (final d in destinations) {
      if (picked.length >= _mobileNavPrimaryCount) break;
      if (!picked.any((p) => p.path == d.path)) picked.add(d);
    }

    return [
      ...picked,
      const _NavItem(_mobileNavMenuPath, Icons.apps_rounded, 'Menu'),
    ];
  }

  static int _mobileBottomSelectedIndex(
    List<_NavItem> mobileItems,
    int destinationIndex,
    List<_NavItem> destinations,
  ) {
    if (destinations.length <= 5) {
      return destinationIndex.clamp(0, mobileItems.length - 1);
    }

    final current = destinations[destinationIndex.clamp(0, destinations.length - 1)];
    final idx = mobileItems.indexWhere((d) => d.path == current.path);
    if (idx >= 0) return idx;
    return _mobileNavPrimaryCount;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.value;
    final sessionActive = authAsync.value?.session != null;

    if (authAsync.isLoading) {
      return const AppLoadingScaffold(message: 'Carregando sessão…');
    }

    if (sessionActive && profileAsync.isLoading) {
      return const AppLoadingScaffold(message: 'Carregando perfil…');
    }

    if (sessionActive && profile == null && !profileAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sessão ativa, mas perfil não encontrado.\nVerifique o cadastro no Supabase.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ClayTokens.textSecondary),
          ),
        ),
      );
    }

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

    final savedShortcuts = ref.watch(mobileNavShortcutsProvider(activeModule));
    final mobileBottomDestinations = _mobileBottomItems(destinations, savedShortcuts);
    final mobileNavItems = mobileBottomDestinations
        .map((d) => ClayNavItem(icon: d.icon, label: d.label))
        .toList();
    final mobileSelectedIndex = _mobileBottomSelectedIndex(
      mobileBottomDestinations,
      safeIndex,
      destinations,
    );
    final moduleLabel = activeModule == AppModule.rental ? 'Locação' : 'Manutenção';
    final isCompactHeader = MediaQuery.sizeOf(context).width < 600;

    void onMobileNavSelected(int i) {
      final item = mobileBottomDestinations[i];
      if (item.path == _mobileNavMenuPath) {
        showMobileNavMenuSheet(
          context: context,
          currentPath: location,
          module: activeModule,
          ref: ref,
          items: destinations
              .map(
                (d) => MobileNavMenuItem(path: d.path, icon: d.icon, label: d.label),
              )
              .toList(),
        );
        return;
      }
      context.go(item.path);
    }

    return AccessSessionScope(
      child: ClayScaffold(
        showOrbs: false,
        appBar: ClayAppBar(
          title: isCompactHeader ? moduleLabel : 'Cond Manager · $moduleLabel',
          actions: [
            const AppModuleSwitcher(),
            profileAsync.when(
              data: (profile) => _ProfileChip(name: profile?.fullName ?? ''),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout_rounded, size: 22),
              tooltip: 'Sair',
              color: ClayTokens.muted,
              onPressed: () async {
                await endAccessSessionTracking(ref);
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        bottomNavigationBar: isWide
            ? null
            : MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: AppTypography.navTextScaler),
                child: ClayBottomNav(
                  items: mobileNavItems,
                  selectedIndex: mobileSelectedIndex.clamp(0, mobileNavItems.length - 1),
                  onSelected: onMobileNavSelected,
                ),
              ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isWide)
              MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: AppTypography.navTextScaler),
                child: ClayNavRail(
                  items: navItems,
                  selectedIndex: safeIndex,
                  onSelected: (i) => context.go(destinations[i].path),
                ),
              ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: ClayTokens.backgroundGradient,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final showName = MediaQuery.sizeOf(context).width > 500;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: showName ? 12 : 4, vertical: 4),
      decoration: BoxDecoration(
        color: ClayTokens.cardBg,
        borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
        border: Border.all(color: ClayTokens.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: ClayTokens.accent,
            child: Text(
              (name.isNotEmpty ? name : 'U').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ],
        ],
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
