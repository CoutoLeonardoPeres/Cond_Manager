import 'package:cond_manager/features/materials/domain/entities/material.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';

class MaterialSuppliersSelector extends StatelessWidget {
  const MaterialSuppliersSelector({
    super.key,
    required this.available,
    required this.selectedIds,
    required this.primaryId,
    required this.onChanged,
    this.enabled = true,
  });

  final List<ProviderPickerForMaterial> available;
  final Set<String> selectedIds;
  final String? primaryId;
  final void Function(Set<String> ids, String? primaryId) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (available.isEmpty) {
      return const Text(
        'Cadastre fornecedores na aba Fornecedores.',
        style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Fornecedores',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: available.map((s) {
            final selected = selectedIds.contains(s.id);
            return FilterChip(
              label: Text(s.label),
              selected: selected,
              onSelected: enabled
                  ? (v) {
                      final next = Set<String>.from(selectedIds);
                      if (v) {
                        next.add(s.id);
                      } else {
                        next.remove(s.id);
                      }
                      var primary = primaryId;
                      if (!v && primary == s.id) {
                        primary = next.isEmpty ? null : next.first;
                      } else if (v && next.length == 1) {
                        primary = s.id;
                      }
                      onChanged(next, primary);
                    }
                  : null,
            );
          }).toList(),
        ),
        if (selectedIds.length > 1) ...[
          const SizedBox(height: 12),
          ClayDropdownField<ProviderPickerForMaterial?>(
            label: 'Fornecedor principal',
            value: primaryId != null
                ? available.cast<ProviderPickerForMaterial?>().firstWhere(
                      (p) => p?.id == primaryId,
                      orElse: () => null,
                    )
                : null,
            items: available
                .where((s) => selectedIds.contains(s.id))
                .cast<ProviderPickerForMaterial?>()
                .toList(),
            itemLabel: (p) => p?.label ?? '—',
            onChanged: enabled
                ? (p) => onChanged(selectedIds, p?.id)
                : null,
          ),
        ],
      ],
    );
  }
}
