import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_expense_due_alerts_section.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RentalDashboardPage extends ConsumerWidget {
  const RentalDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    if (!(profile?.permissions.hasModule(AppModule.rental) ?? false)) {
      return const Center(child: Text('Módulo de locação não contratado.'));
    }

    final propertiesAsync = ref.watch(rentalPropertiesListProvider);
    final leasesAsync = ref.watch(rentalLeasesListProvider);
    final bookingsAsync = ref.watch(rentalBookingsListProvider);
    final alertsAsync = ref.watch(rentalExpenseDueAlertsProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Locação',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gestão de imóveis, contratos, reservas e cobranças para imobiliárias, '
            'hotéis, pousadas, hostels, Airbnb e proprietários.',
            style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                label: 'Imóveis',
                value: propertiesAsync.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'),
                icon: Icons.home_work_rounded,
                onTap: () => context.go('/rental/properties'),
              ),
              _StatCard(
                label: 'Contratos ativos',
                value: leasesAsync.maybeWhen(
                  data: (l) =>
                      '${l.where((x) => x.status == RentalLeaseStatus.active).length}',
                  orElse: () => '—',
                ),
                icon: Icons.description_rounded,
                onTap: () => context.go('/rental/leases'),
              ),
              _StatCard(
                label: 'Reservas',
                value: bookingsAsync.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'),
                icon: Icons.event_available_rounded,
                onTap: () => context.go('/rental/bookings'),
              ),
              _StatCard(
                label: 'Contas a vencer',
                value: alertsAsync.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'),
                icon: Icons.notifications_active_rounded,
                onTap: () => context.go('/rental/expenses'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const RentalExpenseDueAlertsSection(maxItems: 4),
          Text(
            'Tipos atendidos',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TypeChip('Quartos e hotéis'),
              _TypeChip('Casas e apartamentos'),
              _TypeChip('Salas comerciais'),
              _TypeChip('Galpões e lojas'),
              _TypeChip('Temporada / Airbnb'),
              _TypeChip('Longo prazo'),
            ],
          ),
          const SizedBox(height: 24),
          _VacantPropertiesSection(
            propertiesAsync: propertiesAsync,
            leasesAsync: leasesAsync,
            bookingsAsync: bookingsAsync,
            currency: currency,
          ),
          const SizedBox(height: 24),
          bookingsAsync.when(
            data: (bookings) {
              final upcoming = bookings
                  .where((b) => b.checkIn.isAfter(DateTime.now().subtract(const Duration(days: 1))))
                  .take(5)
                  .toList();
              if (upcoming.isEmpty) {
                return const Text(
                  'Nenhuma reserva próxima. Cadastre imóveis e crie reservas.',
                  style: TextStyle(color: ClayTokens.textSecondary),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximas reservas',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...upcoming.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClayListTileCard(
                        icon: Icons.nights_stay_rounded,
                        title: b.guestName,
                        subtitle:
                            '${b.propertyTitle} · ${DateFormat('dd/MM').format(b.checkIn)} → ${DateFormat('dd/MM').format(b.checkOut)} · ${b.status.label}'
                            '${b.totalAmount != null ? ' · ${currency.format(b.totalAmount)}' : ''}',
                        onTap: () => context.go('/rental/bookings'),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return SizedBox(
      width: 160,
      child: ClayCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: ClayTokens.primary),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _VacantPropertiesSection extends StatelessWidget {
  const _VacantPropertiesSection({
    required this.propertiesAsync,
    required this.leasesAsync,
    required this.bookingsAsync,
    required this.currency,
  });

  final AsyncValue<List<RentalProperty>> propertiesAsync;
  final AsyncValue leasesAsync;
  final AsyncValue bookingsAsync;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return propertiesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
      data: (properties) {
        return leasesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
          data: (leases) {
            return bookingsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (bookings) {
                final vacant = rentalVacantProperties(
                  properties: properties,
                  bookings: bookings,
                  leases: leases,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Imóveis sem ocupação',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        ClaySurface(
                          depth: ClayDepth.pressed,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Text(
                            '${vacant.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: vacant.isEmpty ? ClayTokens.success : ClayTokens.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sem contrato ativo nem reserva vigente hoje (${DateFormat('dd/MM/yyyy').format(DateTime.now())}).',
                      style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (vacant.isEmpty)
                      const ClaySurface(
                        depth: ClayDepth.pressed,
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Todos os imóveis ativos estão ocupados no momento.',
                          style: TextStyle(color: ClayTokens.textSecondary),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 720
                              ? 4
                              : constraints.maxWidth >= 540
                                  ? 3
                                  : constraints.maxWidth >= 360
                                      ? 2
                                      : 1;
                          const spacing = 8.0;
                          final tileWidth =
                              (constraints.maxWidth - spacing * (columns - 1)) / columns;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: vacant.map((property) {
                              final rate =
                                  property.listingMode == RentalListingMode.daily ||
                                          property.listingMode == RentalListingMode.shortTerm ||
                                          property.listingMode == RentalListingMode.vacationRental
                                      ? property.baseDailyRate
                                      : property.baseRentAmount;

                              final locationParts = [
                                property.addressNeighborhood?.trim(),
                                property.effectiveAddressCity,
                              ].whereType<String>().where((s) => s.isNotEmpty).toList();

                              return SizedBox(
                                width: tileWidth,
                                child: ClayCard(
                                  onTap: () => context.go(
                                    '/rental/bookings/new?propertyId=${property.id}&returnTo=/rental',
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  radius: ClayTokens.radiusSm,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.event_available_outlined,
                                            size: 14,
                                            color: ClayTokens.warning.withValues(alpha: 0.9),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              property.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          property.propertyType.label,
                                          ...locationParts,
                                          if (rate != null) currency.format(rate),
                                        ].join(' · '),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: ClayTokens.textSecondary,
                                          fontSize: 10,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
