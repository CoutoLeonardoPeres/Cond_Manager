import 'package:cond_manager/features/materials/domain/entities/material.dart' as mat;
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';

class MaterialIdsSelector extends StatelessWidget {
  const MaterialIdsSelector({
    super.key,
    required this.materials,
    required this.selectedIds,
    required this.onChanged,
    this.enabled = true,
  });

  final List<mat.Material> materials;
  final Set<String> selectedIds;
  final void Function(Set<String> ids) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return const Text(
        'Nenhum material cadastrado neste condomínio.',
        style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Materiais fornecidos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'Um material pode ter vários fornecedores; selecione todos que este fornecedor atende.',
          style: TextStyle(color: ClayTokens.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: materials.map((m) {
            final selected = selectedIds.contains(m.id);
            return FilterChip(
              label: Text(m.name),
              selected: selected,
              onSelected: enabled
                  ? (v) {
                      final next = Set<String>.from(selectedIds);
                      if (v) {
                        next.add(m.id);
                      } else {
                        next.remove(m.id);
                      }
                      onChanged(next);
                    }
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}
