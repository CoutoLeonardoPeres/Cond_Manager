import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/dashboard/presentation/providers/dashboard_financial_providers.dart';
import 'package:cond_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:cond_manager/features/dashboard/presentation/widgets/dashboard_charts_section.dart';
import 'package:cond_manager/features/dashboard/presentation/widgets/dashboard_filters_bar.dart';
import 'package:cond_manager/features/dashboard/presentation/widgets/dashboard_financial_kpi_section.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_expense_due_alerts_section.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RentalDashboardPage extends ConsumerWidget {
  const RentalDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    if (!(profile?.permissions.hasModule(AppModule.rental) ?? false)) {
      return const Center(child: Text('Módulo de locação não contratado.'));
    }

    final filter = ref.watch(dashboardFilterProvider);
    final condos = ref.watch(accessibleCondominiumsProvider).value ?? const [];
    final propertiesAsync = ref.watch(rentalPropertiesListProvider);
    final leasesAsync = ref.watch(rentalLeasesListProvider);
    final bookingsAsync = ref.watch(rentalShortStayBookingsListProvider);
    final alertsAsync = ref.watch(rentalExpenseDueAlertsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardFinancialMetricsProvider);
        ref.invalidate(rentalPropertiesListProvider);
        ref.invalidate(rentalLeasesListProvider);
        ref.invalidate(rentalShortStayBookingsListProvider);
        ref.invalidate(rentalExpenseDueAlertsProvider);
        await ref.read(dashboardFinancialMetricsProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Locação',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const RentalExpenseDueAlertsSection(
                  badgeOnly: true,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            DashboardFiltersBar(
              filter: filter,
              condominiums: condos,
              onChanged: (f) => ref.read(dashboardFilterProvider.notifier).state = f,
              compact: true,
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 700 ? 4 : 2;
                final spacing = 6.0;
                final tileWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: tileWidth,
                      child: _MiniStatCard(
                        label: 'Imóveis',
                        value: propertiesAsync.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'),
                        icon: Icons.home_work_rounded,
                        onTap: () => context.go('/rental/properties'),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _MiniStatCard(
                        label: 'Contratos',
                        value: leasesAsync.maybeWhen(
                          data: (l) =>
                              '${l.where((x) => x.status == RentalLeaseStatus.active).length}',
                          orElse: () => '—',
                        ),
                        icon: Icons.description_rounded,
                        onTap: () => context.go('/rental/leases'),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _MiniStatCard(
                        label: 'Reservas',
                        value: bookingsAsync.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'),
                        icon: Icons.event_available_rounded,
                        onTap: () => context.go('/rental/bookings'),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _MiniStatCard(
                        label: 'A vencer',
                        value: alertsAsync.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'),
                        icon: Icons.notifications_active_rounded,
                        onTap: () => context.go('/rental/expenses'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Financeiro e ocupação',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            const DashboardFinancialKpiSection(
              compact: true,
              pairOccupancyProfitability: true,
            ),
            const SizedBox(height: 8),
            const DashboardChartsSection(
              compact: true,
              showHeader: false,
              pairOccupancyProfitabilityCharts: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      radius: ClayTokens.radiusSm,
      child: Row(
        children: [
          Icon(icon, color: ClayTokens.primary, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: ClayTokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
