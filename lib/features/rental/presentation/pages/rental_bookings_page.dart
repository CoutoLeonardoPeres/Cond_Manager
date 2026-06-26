import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RentalBookingsPage extends ConsumerWidget {
  const RentalBookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(rentalBookingsListProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final canCreate = ref.watch(currentProfileProvider).value?.permissions.canManageRental ?? false;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reservas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hospedagem, diárias, temporada — hotéis, pousadas, hostels e Airbnb.',
                    style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: bookingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Nenhuma reserva cadastrada.',
                            style: TextStyle(color: ClayTokens.textSecondary),
                          ),
                          if (canCreate) ...[
                            const SizedBox(height: 16),
                            ClayButton(
                              label: 'Nova reserva',
                              expand: false,
                              icon: Icons.add_rounded,
                              onPressed: () => context.go('/rental/bookings/new'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(rentalBookingsListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: bookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final b = bookings[i];
                        return ClayListTileCard(
                          icon: Icons.event_available_rounded,
                          title: b.guestName,
                          subtitle: [
                            b.propertyTitle,
                            b.channel.label,
                            b.status.label,
                            '${dateFmt.format(b.checkIn)} → ${dateFmt.format(b.checkOut)} (${b.nights} noites)',
                            if (b.totalAmount != null) currency.format(b.totalAmount),
                          ].join(' · '),
                          onTap: () => context.go('/rental/bookings/${b.id}/edit'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (canCreate)
          Positioned(
            right: 20,
            bottom: 20,
            child: ClayButton(
              label: 'Nova reserva',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go('/rental/bookings/new'),
            ),
          ),
      ],
    );
  }
}
