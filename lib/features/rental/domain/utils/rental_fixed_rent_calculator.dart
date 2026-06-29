import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';

/// Cálculo de aluguel fixo proporcional até o próximo vencimento.
class RentalFixedRentCalculator {
  RentalFixedRentCalculator._();

  static int clampDueDay(int day) => day.clamp(1, 28);

  /// Próxima data de vencimento estritamente após [fromDate].
  static DateTime nextDueDate(DateTime fromDate, int dueDayOfMonth) {
    final day = clampDueDay(dueDayOfMonth);
    final from = rentalGanttDateOnly(fromDate);
    var candidate = DateTime(from.year, from.month, day);
    if (!candidate.isAfter(from)) {
      candidate = DateTime(from.year, from.month + 1, day);
    }
    return candidate;
  }

  /// Dias entre check-in e o próximo vencimento.
  static int daysUntilNextDue(DateTime checkIn, int dueDayOfMonth) {
    final from = rentalGanttDateOnly(checkIn);
    return nextDueDate(from, dueDayOfMonth).difference(from).inDays;
  }

  /// Valor proporcional do check-in até o próximo vencimento.
  static double proportionalAmount({
    required DateTime checkIn,
    required int dueDayOfMonth,
    required double monthlyRent,
  }) {
    if (monthlyRent <= 0) return 0;

    final from = rentalGanttDateOnly(checkIn);
    final nextDue = nextDueDate(from, dueDayOfMonth);
    if (!nextDue.isAfter(from)) return monthlyRent;

    var total = 0.0;
    var cursor = from;
    while (cursor.isBefore(nextDue)) {
      final monthDays = DateTime(cursor.year, cursor.month + 1, 0).day;
      final nextMonthStart = DateTime(cursor.year, cursor.month + 1, 1);
      final segmentEnd = nextDue.isBefore(nextMonthStart) ? nextDue : nextMonthStart;
      final segmentDays = segmentEnd.difference(cursor).inDays;
      if (segmentDays > 0) {
        total += monthlyRent * segmentDays / monthDays;
      }
      cursor = segmentEnd;
    }

    return double.parse(total.toStringAsFixed(2));
  }
}
