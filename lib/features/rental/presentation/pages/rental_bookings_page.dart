import 'package:cond_manager/core/formatters/brazilian_mask_formatters.dart';
import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking_search_filter.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RentalBookingsPage extends ConsumerStatefulWidget {
  const RentalBookingsPage({super.key});

  @override
  ConsumerState<RentalBookingsPage> createState() => _RentalBookingsPageState();
}

class _RentalBookingsPageState extends ConsumerState<RentalBookingsPage> {
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  List<RentalBooking> _sortBookings(List<RentalBooking> bookings) {
    final list = [...bookings];
    list.sort((a, b) => a.guestName.toLowerCase().compareTo(b.guestName.toLowerCase()));
    return list;
  }

  void _updateSearch(RentalBookingSearchFilter next) {
    ref.read(rentalBookingSearchFilterProvider.notifier).state = next;
  }

  void _clearFilters() {
    _nameController.clear();
    _cpfController.clear();
    _phoneController.clear();
    _emailController.clear();
    _updateSearch(const RentalBookingSearchFilter());
  }

  void _syncControllers(RentalBookingSearchFilter filter) {
    if (_nameController.text != filter.name) _nameController.text = filter.name;
    if (_cpfController.text != filter.cpf) _cpfController.text = filter.cpf;
    if (_phoneController.text != filter.phone) _phoneController.text = filter.phone;
    if (_emailController.text != filter.email) _emailController.text = filter.email;
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(rentalBookingsListProvider);
    final searchFilter = ref.watch(rentalBookingSearchFilterProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final canCreate = ref.watch(currentProfileProvider).value?.permissions.canManageRental ?? false;

    _syncControllers(searchFilter);

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
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const minGridWidth = 880.0;
                      final gridWidth = constraints.maxWidth < minGridWidth
                          ? minGridWidth
                          : constraints.maxWidth;

                      final grid = FormGrid(
                        columns: 4,
                        items: [
                          FormGridField(
                            child: ClayTextField(
                              controller: _nameController,
                              label: 'Nome',
                              hint: 'Hóspede',
                              prefixIcon: const Icon(Icons.person_search_rounded, size: 20),
                              onChanged: (v) => _updateSearch(searchFilter.copyWith(name: v)),
                            ),
                          ),
                          FormGridField(
                            child: ClayTextField(
                              controller: _cpfController,
                              label: 'CPF',
                              hint: '000.000.000-00',
                              keyboardType: TextInputType.number,
                              inputFormatters: [CpfMaskFormatter()],
                              onChanged: (v) => _updateSearch(searchFilter.copyWith(cpf: v)),
                            ),
                          ),
                          FormGridField(
                            child: ClayTextField(
                              controller: _phoneController,
                              label: 'Telefone',
                              hint: '(00) 00000-0000',
                              keyboardType: TextInputType.phone,
                              inputFormatters: [PhoneMaskFormatter()],
                              onChanged: (v) => _updateSearch(searchFilter.copyWith(phone: v)),
                            ),
                          ),
                          FormGridField(
                            child: ClayTextField(
                              controller: _emailController,
                              label: 'E-mail',
                              hint: 'email@exemplo.com',
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (v) => _updateSearch(searchFilter.copyWith(email: v)),
                            ),
                          ),
                        ],
                      );

                      if (constraints.maxWidth < minGridWidth) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(width: gridWidth, child: grid),
                        );
                      }
                      return grid;
                    },
                  ),
                  if (searchFilter.hasActiveFilters) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                        label: const Text('Limpar filtros'),
                      ),
                    ),
                  ],
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

                  final filtered = _sortBookings(filterRentalBookings(bookings, searchFilter));
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Nenhuma reserva encontrada com os filtros selecionados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ClayTokens.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ClayButton(
                            label: 'Limpar filtros',
                            expand: false,
                            icon: Icons.filter_alt_off_rounded,
                            onPressed: _clearFilters,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(rentalBookingsListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final b = filtered[i];
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
