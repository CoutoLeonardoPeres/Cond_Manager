import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Granularidade do calendário de ocupação.
enum RentalOccupancyViewMode {
  day('Dia'),
  week('Semana'),
  month('Mês'),
  year('Ano');

  const RentalOccupancyViewMode(this.label);

  final String label;

  IconData get icon => switch (this) {
        RentalOccupancyViewMode.day => Icons.today_rounded,
        RentalOccupancyViewMode.week => Icons.view_week_rounded,
        RentalOccupancyViewMode.month => Icons.calendar_view_month_rounded,
        RentalOccupancyViewMode.year => Icons.date_range_rounded,
      };
}

/// Meses visíveis de uma vez na tela (modo mês).
const rentalOccupancyVisibleMonths = 2;

/// Horizonte padrão do mapa (imóveis com vaga + rolagem).
const rentalOccupancyDefaultHorizonMonths = 3;

const rentalOccupancyHorizonOptions = [3, 6, 12];

/// Modos exibidos no filtro superior da tela de ocupação (sem "Dia").
const rentalOccupancySelectableViewModes = [
  RentalOccupancyViewMode.week,
  RentalOccupancyViewMode.month,
  RentalOccupancyViewMode.year,
];

DateTime rentalOccupancyWeekStart(DateTime anchor) {
  final d = rentalGanttDateOnly(anchor);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

/// Dias dos [rentalOccupancyVisibleMonths] primeiros meses a partir de [rangeStart].
int rentalOccupancyVisibleDayCount(DateTime rangeStart) {
  final start = DateTime(rangeStart.year, rangeStart.month, 1);
  return DateTime(start.year, start.month + rentalOccupancyVisibleMonths, 1)
      .difference(start)
      .inDays;
}

RentalGanttRange rentalOccupancyRangeFor(
  RentalOccupancyViewMode mode,
  DateTime anchor, {
  int monthHorizon = rentalOccupancyDefaultHorizonMonths,
}) {
  final a = rentalGanttDateOnly(anchor);
  return switch (mode) {
    RentalOccupancyViewMode.day => RentalGanttRange(
        start: a,
        end: a.add(const Duration(days: 1)),
      ),
    RentalOccupancyViewMode.week => () {
        final start = rentalOccupancyWeekStart(a);
        return RentalGanttRange(start: start, end: start.add(const Duration(days: 7)));
      }(),
    RentalOccupancyViewMode.month => RentalGanttRange(
        start: DateTime(a.year, a.month, 1),
        end: DateTime(a.year, a.month + monthHorizon, 1),
      ),
    RentalOccupancyViewMode.year => RentalGanttRange(
        start: DateTime(a.year, 1, 1),
        end: DateTime(a.year + 1, 1, 1),
      ),
  };
}

int rentalOccupancyColumnCount(RentalOccupancyViewMode mode, RentalGanttRange range) {
  return switch (mode) {
    RentalOccupancyViewMode.day => 1,
    RentalOccupancyViewMode.week => 7,
    RentalOccupancyViewMode.month => range.totalDays,
    RentalOccupancyViewMode.year => 12,
  };
}

double rentalOccupancyColumnWidth({
  required RentalOccupancyViewMode mode,
  required double viewportWidth,
  required double propertyColumnWidth,
  RentalGanttRange? range,
}) {
  final available = (viewportWidth - propertyColumnWidth).clamp(120.0, double.infinity);
  return switch (mode) {
    RentalOccupancyViewMode.day => available,
    RentalOccupancyViewMode.week => (available / 7).clamp(56.0, 140.0),
    RentalOccupancyViewMode.month => () {
        if (range == null) return 20.0;
        final visibleDays = rentalOccupancyVisibleDayCount(range.start);
        return available / visibleDays;
      }(),
    RentalOccupancyViewMode.year => (available / 12).clamp(52.0, 96.0),
  };
}

DateTime rentalOccupancyStepAnchor(
  RentalOccupancyViewMode mode,
  DateTime anchor,
  int delta,
) {
  final a = rentalGanttDateOnly(anchor);
  return switch (mode) {
    RentalOccupancyViewMode.day => a.add(Duration(days: delta)),
    RentalOccupancyViewMode.week => a.add(Duration(days: 7 * delta)),
    RentalOccupancyViewMode.month => DateTime(a.year, a.month + delta * rentalOccupancyVisibleMonths, 1),
    RentalOccupancyViewMode.year => DateTime(a.year + delta, a.month, a.day),
  };
}

String rentalOccupancyPeriodLabel(
  RentalOccupancyViewMode mode,
  DateTime anchor, {
  int monthHorizon = rentalOccupancyDefaultHorizonMonths,
}) {
  final a = rentalGanttDateOnly(anchor);
  return switch (mode) {
    RentalOccupancyViewMode.day => () {
        final s = DateFormat('EEEE, d MMMM yyyy', 'pt_BR').format(a);
        return s[0].toUpperCase() + s.substring(1);
      }(),
    RentalOccupancyViewMode.week => () {
        final start = rentalOccupancyWeekStart(a);
        final end = start.add(const Duration(days: 6));
        final fmt = DateFormat('d MMM', 'pt_BR');
        final year = DateFormat('yyyy').format(a);
        if (start.year == end.year) {
          return '${fmt.format(start)} – ${fmt.format(end)} $year';
        }
        return '${fmt.format(start)} ${start.year} – ${fmt.format(end)} ${end.year}';
      }(),
    RentalOccupancyViewMode.month => () {
        final start = DateTime(a.year, a.month, 1);
        final end = DateTime(a.year, a.month + monthHorizon, 1)
            .subtract(const Duration(days: 1));
        final startFmt = DateFormat('MMMM yyyy', 'pt_BR').format(start);
        final endFmt = DateFormat('MMMM yyyy', 'pt_BR').format(end);
        final s = startFmt[0].toUpperCase() + startFmt.substring(1);
        final e = endFmt[0].toUpperCase() + endFmt.substring(1);
        return '$s – $e';
      }(),
    RentalOccupancyViewMode.year => DateFormat('yyyy').format(a),
  };
}

String rentalOccupancyNavTooltip(RentalOccupancyViewMode mode, int delta) {
  final word = delta < 0 ? 'Anterior' : 'Próximo';
  return switch (mode) {
    RentalOccupancyViewMode.day => '$word dia',
    RentalOccupancyViewMode.week => '$word semana',
    RentalOccupancyViewMode.month => '$word $rentalOccupancyVisibleMonths meses',
    RentalOccupancyViewMode.year => '$word ano',
  };
}

(int startCol, int endColExclusive) rentalOccupancyYearSegmentColumns({
  required RentalGanttRange range,
  required DateTime segmentStart,
  required DateTime segmentEndExclusive,
}) {
  final year = range.start.year;
  final startCol = segmentStart.year < year ? 0 : segmentStart.month - 1;
  final lastOccupied = segmentEndExclusive.subtract(const Duration(days: 1));
  final endCol = lastOccupied.year > year ? 12 : lastOccupied.month;
  return (startCol, endCol.clamp(startCol + 1, 12));
}
