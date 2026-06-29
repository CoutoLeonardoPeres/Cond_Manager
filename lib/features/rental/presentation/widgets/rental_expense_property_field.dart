import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seletor de imóvel para despesas de locação (sempre visível no módulo rental).
class RentalExpensePropertyField extends ConsumerWidget {
  const RentalExpensePropertyField({
    super.key,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final RentalProperty? value;
  final ValueChanged<RentalProperty?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(rentalPropertiesListProvider);

    return propertiesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text('Erro ao carregar imóveis: $e'),
      ),
      data: (properties) {
        if (properties.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Nenhum imóvel cadastrado.',
              style: TextStyle(color: ClayTokens.textSecondary),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClayDropdownField<RentalProperty?>(
            label: required ? 'Imóvel *' : 'Imóvel',
            hint: 'Selecione o imóvel',
            value: value,
            items: [null, ...properties],
            itemLabel: (p) => p?.title ?? 'Selecione…',
            onChanged: onChanged,
            validator: required
                ? (p) => p == null ? 'Selecione o imóvel.' : null
                : null,
          ),
        );
      },
    );
  }
}
