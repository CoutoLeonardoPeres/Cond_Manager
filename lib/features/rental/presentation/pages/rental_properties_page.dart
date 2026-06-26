import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/domain/enums/rental_property_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RentalPropertiesPage extends ConsumerWidget {
  const RentalPropertiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(rentalPropertyListFilterProvider);
    final propertiesAsync = ref.watch(rentalPropertiesListProvider);
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
                    'Imóveis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quartos, casas, apartamentos, prédios, salas, galpões e demais unidades locáveis.',
                    style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClayDropdownField<RentalPropertyType?>(
                          label: 'Tipo',
                          value: filter.propertyType,
                          items: [null, ...RentalPropertyType.values],
                          itemLabel: (t) => t?.label ?? 'Todos',
                          onChanged: (v) => ref.read(rentalPropertyListFilterProvider.notifier).state =
                              filter.copyWith(propertyType: v, clearType: v == null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClayDropdownField<RentalListingMode?>(
                          label: 'Modalidade',
                          value: filter.listingMode,
                          items: [null, ...RentalListingMode.values],
                          itemLabel: (m) => m?.label ?? 'Todas',
                          onChanged: (v) => ref.read(rentalPropertyListFilterProvider.notifier).state =
                              filter.copyWith(listingMode: v, clearMode: v == null),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: propertiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (properties) {
                  if (properties.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Nenhum imóvel cadastrado.',
                            style: TextStyle(color: ClayTokens.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          if (canCreate) ...[
                            const SizedBox(height: 16),
                            ClayButton(
                              label: 'Novo imóvel',
                              expand: false,
                              icon: Icons.add_rounded,
                              onPressed: () => context.go('/rental/properties/new'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(rentalPropertiesListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: properties.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _PropertyTile(
                        property: properties[i],
                        currency: currency,
                        onTap: () => context.go('/rental/properties/${properties[i].id}/edit'),
                      ),
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
              label: 'Novo imóvel',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go('/rental/properties/new'),
            ),
          ),
      ],
    );
  }
}

class _PropertyTile extends StatelessWidget {
  const _PropertyTile({
    required this.property,
    required this.currency,
    this.onTap,
  });

  final RentalProperty property;
  final NumberFormat currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rate = property.listingMode == RentalListingMode.daily ||
            property.listingMode == RentalListingMode.shortTerm ||
            property.listingMode == RentalListingMode.vacationRental
        ? property.baseDailyRate
        : property.baseRentAmount;

    return ClayListTileCard(
      icon: Icons.home_work_rounded,
      title: property.title,
      subtitle: [
        property.propertyType.label,
        property.listingMode.label,
        if (property.condominiumName != null) 'Condomínio: ${property.condominiumName}',
        property.locationLabel,
        if (property.ownerName != null) 'Proprietário: ${property.ownerName}',
        if (rate != null) currency.format(rate),
        if (property.status != 'active') 'Inativo',
      ].join(' · '),
      onTap: onTap,
    );
  }
}
