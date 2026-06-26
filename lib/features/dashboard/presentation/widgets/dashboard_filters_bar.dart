import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/dashboard/domain/dashboard_filter.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardFiltersBar extends StatelessWidget {
  const DashboardFiltersBar({
    super.key,
    required this.filter,
    required this.condominiums,
    required this.onChanged,
  });

  final DashboardFilter filter;
  final List<Condominium> condominiums;
  final ValueChanged<DashboardFilter> onChanged;

  static final _yearFmt = DateFormat('yyyy');
  static final _dayFmt = DateFormat('dd/MM/yyyy');
  static final _monthFmt = DateFormat('MMMM yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final years = List.generate(6, (i) => DateTime.now().year - i);

    return ClaySurface(
      depth: ClayDepth.raised,
      radius: ClayTokens.radiusMd,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filtros',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ClayTokens.primary,
                ),
          ),
          const SizedBox(height: 10),
          if (condominiums.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todos condomínios',
                    selected: filter.condominiumId == null,
                    onTap: () => onChanged(filter.copyWith(clearCondominium: true)),
                  ),
                  ...condominiums.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: c.name,
                        selected: filter.condominiumId == c.id,
                        onTap: () => onChanged(filter.copyWith(condominiumId: c.id)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DashboardPeriodType.values.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: p.label,
                    selected: filter.period == p,
                    onTap: () {
                      final now = DateTime.now();
                      onChanged(
                        filter.copyWith(
                          period: p,
                          anchorDate: DateTime(now.year, now.month, now.day),
                          year: now.year,
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _PeriodNavigator(
            filter: filter,
            years: years,
            onChanged: onChanged,
          ),
          const SizedBox(height: 8),
          Text(
            filter.periodDescription(
              condominiumName: _condoName(filter.condominiumId),
            ),
            style: const TextStyle(
              fontSize: 12,
              color: ClayTokens.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String? _condoName(String? id) {
    if (id == null) return null;
    for (final c in condominiums) {
      if (c.id == id) return c.name;
    }
    return null;
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.filter,
    required this.years,
    required this.onChanged,
  });

  final DashboardFilter filter;
  final List<int> years;
  final ValueChanged<DashboardFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    if (filter.period == DashboardPeriodType.year) {
      return Row(
        children: [
          const Text('Ano:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: filter.effectiveYear,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: years
                  .map(
                    (y) => DropdownMenuItem(
                      value: y,
                      child: Text('$y'),
                    ),
                  )
                  .toList(),
              onChanged: (y) {
                if (y == null) return;
                onChanged(filter.copyWith(year: y));
              },
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          tooltip: 'Período anterior',
          onPressed: () => onChanged(_shift(filter, -1)),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickDate(context),
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(
              _periodLabel(filter),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Próximo período',
          onPressed: () => onChanged(_shift(filter, 1)),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        TextButton(
          onPressed: () {
            final now = DateTime.now();
            onChanged(
              filter.copyWith(
                anchorDate: DateTime(now.year, now.month, now.day),
              ),
            );
          },
          child: const Text('Hoje'),
        ),
      ],
    );
  }

  static String _periodLabel(DashboardFilter filter) {
    switch (filter.period) {
      case DashboardPeriodType.day:
        return DashboardFiltersBar._dayFmt.format(filter.anchorDate);
      case DashboardPeriodType.week:
        final range = filter.dateRange;
        final end = range.end.subtract(const Duration(days: 1));
        return '${DashboardFiltersBar._dayFmt.format(range.start)} – ${DashboardFiltersBar._dayFmt.format(end)}';
      case DashboardPeriodType.month:
        return DashboardFiltersBar._monthFmt.format(filter.anchorDate);
      case DashboardPeriodType.year:
        return DashboardFiltersBar._yearFmt.format(DateTime(filter.effectiveYear));
    }
  }

  DashboardFilter _shift(DashboardFilter f, int direction) {
    final anchor = f.anchorDate;
    switch (f.period) {
      case DashboardPeriodType.day:
        return f.copyWith(
          anchorDate: anchor.add(Duration(days: direction)),
        );
      case DashboardPeriodType.week:
        return f.copyWith(
          anchorDate: anchor.add(Duration(days: 7 * direction)),
        );
      case DashboardPeriodType.month:
        final month = anchor.month + direction;
        final year = anchor.year + ((month - 1) ~/ 12);
        final normalizedMonth = ((month - 1) % 12) + 1;
        return f.copyWith(
          anchorDate: DateTime(year, normalizedMonth, 1),
        );
      case DashboardPeriodType.year:
        return f.copyWith(year: f.effectiveYear + direction);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: filter.anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      locale: const Locale('pt', 'BR'),
    );
    if (picked == null) return;
    onChanged(
      filter.copyWith(
        anchorDate: DateTime(picked.year, picked.month, picked.day),
        year: picked.year,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ClayTokens.primary.withValues(alpha: 0.14)
          : ClayTokens.surface,
      borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? ClayTokens.primary : ClayTokens.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}
