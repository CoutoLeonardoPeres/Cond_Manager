import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:cond_manager/shared/widgets/form/month_filter_bar.dart';
import 'package:cond_manager/shared/widgets/form/responsive_filter_layout.dart';
import 'package:flutter/material.dart';

/// Chips de filtro rápido + navegação por mês.
class RentalListFiltersBar extends StatelessWidget {
  const RentalListFiltersBar({
    super.key,
    this.quickFilters,
    this.quickFilter,
    this.onQuickFilterChanged,
    this.month,
    this.onMonthChanged,
    this.status,
    this.onStatusChanged,
    this.extra,
  });

  final List<RentalChargeQuickFilter>? quickFilters;
  final RentalChargeQuickFilter? quickFilter;
  final ValueChanged<RentalChargeQuickFilter>? onQuickFilterChanged;

  final DateTime? month;
  final ValueChanged<DateTime?>? onMonthChanged;

  final RentalLeaseStatus? status;
  final ValueChanged<RentalLeaseStatus?>? onStatusChanged;

  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[];

    if (quickFilters != null && onQuickFilterChanged != null) {
      fields.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickFilters!.map((f) {
            final selected = quickFilter == f;
            return FilterChip(
              label: Text(f.label),
              selected: selected,
              onSelected: (_) => onQuickFilterChanged!(f),
              selectedColor: ClayTokens.primary.withValues(alpha: 0.18),
              checkmarkColor: ClayTokens.primary,
              labelStyle: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? ClayTokens.primary : ClayTokens.textSecondary,
              ),
              side: BorderSide(
                color: selected
                    ? ClayTokens.primary.withValues(alpha: 0.5)
                    : ClayTokens.muted.withValues(alpha: 0.35),
              ),
            );
          }).toList(),
        ),
      );
    }

    if (onMonthChanged != null) {
      fields.add(
        RentalMonthFilterBar(
          compact: true,
          month: month,
          onChanged: onMonthChanged!,
        ),
      );
    }

    if (onStatusChanged != null) {
      fields.add(
        ClayDropdownField<RentalLeaseStatus?>(
          label: 'Status do contrato',
          value: status,
          items: [null, ...RentalLeaseStatus.values],
          itemLabel: (s) => s?.label ?? 'Todos os status',
          onChanged: onStatusChanged,
        ),
      );
    }

    if (extra != null) fields.add(extra!);

    if (fields.isEmpty) return const SizedBox.shrink();

    return ResponsiveFilterLayout(
      wideColumns: fields.length.clamp(1, 4),
      mobileItemHeight: onMonthChanged != null ? 72 : 84,
      fields: fields,
    );
  }
}

typedef RentalMonthFilterBar = MonthFilterBar;
