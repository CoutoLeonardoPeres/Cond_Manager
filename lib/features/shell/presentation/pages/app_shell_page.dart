import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShellPage extends ConsumerWidget {
  const AppShellPage({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    _NavItem('/', Icons.dashboard_rounded, 'Dashboard'),
    _NavItem('/condominiums', Icons.apartment_rounded, 'Condomínios'),
    _NavItem('/tickets', Icons.support_agent_rounded, 'Chamados'),
    _NavItem('/work-orders', Icons.assignment_rounded, 'Ordens de Serviço'),
    _NavItem('/providers', Icons.engineering_rounded, 'Prestadores'),
    _NavItem('/materials', Icons.inventory_2_rounded, 'Materiais'),
    _NavItem('/preventive', Icons.event_repeat_rounded, 'Preventiva'),
    _NavItem('/financial', Icons.payments_rounded, 'Financeiro'),
    _NavItem('/users', Icons.people_rounded, 'Usuários'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _destinations.indexWhere((d) => d.path == location);
    final safeIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final isWide = MediaQuery.sizeOf(context).width >= 960;

    final navItems = _destinations
        .map((d) => ClayNavItem(icon: d.icon, label: d.label))
        .toList();

    return ClayScaffold(
      appBar: ClayAppBar(
        title: 'Cond Manager',
        actions: [
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
          : ClayBottomNav(
              items: navItems.take(5).toList(),
              selectedIndex: safeIndex.clamp(0, 4),
              onSelected: (i) => context.go(_destinations[i].path),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isWide)
            SizedBox(
              width: 240,
              child: ClayNavRail(
                items: navItems,
                selectedIndex: safeIndex,
                onSelected: (i) => context.go(_destinations[i].path),
              ),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: isWide
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(ClayTokens.radiusLg),
                    )
                  : BorderRadius.zero,
              child: child,
            ),
          ),
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
