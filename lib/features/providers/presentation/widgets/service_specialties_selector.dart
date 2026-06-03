import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';

class ServiceSpecialtiesSelector extends StatelessWidget {
  const ServiceSpecialtiesSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.errorText,
  });

  final Set<ServiceType> selected;
  final ValueChanged<Set<ServiceType>> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Áreas / tipos de serviço *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: ClayTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Selecione todas as categorias em que o prestador atua (ex.: elétrica, portões, paisagismo).',
          style: TextStyle(fontSize: 12, color: ClayTokens.textMuted, height: 1.35),
        ),
        const SizedBox(height: 12),
        ClaySurface(
          depth: ClayDepth.pressed,
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ServiceType.values.map((type) {
              final isOn = selected.contains(type);
              return FilterChip(
                label: Text(type.label),
                selected: isOn,
                onSelected: (on) {
                  final next = Set<ServiceType>.from(selected);
                  if (on) {
                    next.add(type);
                  } else {
                    next.remove(type);
                  }
                  onChanged(next);
                },
                selectedColor: ClayTokens.primary.withValues(alpha: 0.2),
                checkmarkColor: ClayTokens.primary,
              );
            }).toList(),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: const TextStyle(color: ClayTokens.error, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
