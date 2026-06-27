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

DateTime rentalOccupancyWeekStart(DateTime anchor) {
  final d = rentalGanttDateOnly(anchor);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

RentalGanttRange rentalOccupancyRangeFor(RentalOccupancyViewMode mode, DateTime anchor) {
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
        end: DateTime(a.year, a.month + 1, 1),
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
}) {
  final available = (viewportWidth - propertyColumnWidth - 8).clamp(120.0, double.infinity);
  return switch (mode) {
    RentalOccupancyViewMode.day => available,
    RentalOccupancyViewMode.week => (available / 7).clamp(56.0, 140.0),
    RentalOccupancyViewMode.month => 30.0,
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
    RentalOccupancyViewMode.month => DateTime(a.year, a.month + delta, 1),
    RentalOccupancyViewMode.year => DateTime(a.year + delta, a.month, a.day),
  };
}

String rentalOccupancyPeriodLabel(RentalOccupancyViewMode mode, DateTime anchor) {
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
        final s = DateFormat('MMMM yyyy', 'pt_BR').format(a);
        return s[0].toUpperCase() + s.substring(1);
      }(),
    RentalOccupancyViewMode.year => DateFormat('yyyy').format(a),
  };
}

String rentalOccupancyNavTooltip(RentalOccupancyViewMode mode, int delta) {
  final word = delta < 0 ? 'Anterior' : 'Próximo';
  return switch (mode) {
    RentalOccupancyViewMode.day => '$word dia',
    RentalOccupancyViewMode.week => '$word semana',
    RentalOccupancyViewMode.month => '$word mês',
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
