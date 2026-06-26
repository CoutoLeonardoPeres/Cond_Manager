import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
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
            ],
          ),
          const SizedBox(height: 24),
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
