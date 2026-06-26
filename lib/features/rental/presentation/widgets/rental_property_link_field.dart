import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seletor de imóvel de locação para chamados/OS quando ambos os módulos estão ativos.
class RentalPropertyLinkField extends ConsumerWidget {
  const RentalPropertyLinkField({
    super.key,
    required this.condominiumId,
    required this.value,
    required this.onChanged,
  });

  final String? condominiumId;
  final RentalProperty? value;
  final ValueChanged<RentalProperty?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    if (!(profile?.permissions.hasMaintenanceAndRental ?? false)) {
      return const SizedBox.shrink();
    }

    final propertiesAsync = ref.watch(rentalPropertiesListProvider);

    return propertiesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
      data: (all) {
        final filtered = condominiumId == null
            ? all
            : all.where((p) => p.condominiumId == condominiumId).toList();
        if (filtered.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClayDropdownField<RentalProperty?>(
            label: 'Imóvel (locação)',
            hint: 'Opcional — vincula ao portfólio de locação',
            value: value,
            items: [null, ...filtered],
            itemLabel: (p) => p?.title ?? 'Nenhum',
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}
