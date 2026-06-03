import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum DashboardPeriodType {
  day('Dia'),
  week('Semana'),
  month('Mês'),
  year('Ano');

  const DashboardPeriodType(this.label);
  final String label;
}

/// Intervalo [start, end) em horário local.
class DashboardDateRange {
  const DashboardDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool containsDateTime(DateTime value) {
    final local = value.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }

  bool containsDate(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(end.year, end.month, end.day);
    return !day.isBefore(rangeStart) && day.isBefore(rangeEnd);
  }
}

class DashboardFilter extends Equatable {
  const DashboardFilter({
    this.condominiumId,
    this.period = DashboardPeriodType.year,
    required this.anchorDate,
    this.year,
  });

  final String? condominiumId;
  final DashboardPeriodType period;
  final DateTime anchorDate;
  final int? year;

  factory DashboardFilter.initial() {
    final now = DateTime.now();
    return DashboardFilter(
      anchorDate: DateTime(now.year, now.month, now.day),
      year: now.year,
    );
  }

  DashboardFilter copyWith({
    String? condominiumId,
    DashboardPeriodType? period,
    DateTime? anchorDate,
    int? year,
    bool clearCondominium = false,
  }) {
    return DashboardFilter(
      condominiumId: clearCondominium ? null : (condominiumId ?? this.condominiumId),
      period: period ?? this.period,
      anchorDate: anchorDate ?? this.anchorDate,
      year: year ?? this.year,
    );
  }

  int get effectiveYear => year ?? anchorDate.year;

  DashboardDateRange get dateRange {
    final anchor = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);

    switch (period) {
      case DashboardPeriodType.day:
        return DashboardDateRange(
          start: anchor,
          end: anchor.add(const Duration(days: 1)),
        );
      case DashboardPeriodType.week:
        final start = anchor.subtract(Duration(days: anchor.weekday - 1));
        return DashboardDateRange(
          start: start,
          end: start.add(const Duration(days: 7)),
        );
      case DashboardPeriodType.month:
        final start = DateTime(anchor.year, anchor.month, 1);
        final end = anchor.month == 12
            ? DateTime(anchor.year + 1, 1, 1)
            : DateTime(anchor.year, anchor.month + 1, 1);
        return DashboardDateRange(start: start, end: end);
      case DashboardPeriodType.year:
        final y = effectiveYear;
        return DashboardDateRange(
          start: DateTime(y, 1, 1),
          end: DateTime(y + 1, 1, 1),
        );
    }
  }

  String periodDescription({String? condominiumName}) {
    final condo = condominiumName ?? (condominiumId == null ? 'Todos os condomínios' : 'Condomínio');
    final fmt = DateFormat('dd/MM/yyyy');
    final monthFmt = DateFormat('MMMM yyyy', 'pt_BR');

    switch (period) {
      case DashboardPeriodType.day:
        return '${fmt.format(anchorDate)} · $condo';
      case DashboardPeriodType.week:
        final range = dateRange;
        final endInclusive = range.end.subtract(const Duration(days: 1));
        return '${fmt.format(range.start)} – ${fmt.format(endInclusive)} · $condo';
      case DashboardPeriodType.month:
        return '${monthFmt.format(anchorDate)} · $condo';
      case DashboardPeriodType.year:
        return 'Ano $effectiveYear · $condo';
    }
  }

  @override
  List<Object?> get props => [condominiumId, period, anchorDate, year];
}
