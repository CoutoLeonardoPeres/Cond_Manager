import 'package:cond_manager/shared/domain/enums/preventive_frequency.dart';

/// Utilitários de datas para planos preventivos.
class PreventiveSchedule {
  PreventiveSchedule._();

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static DateTime todayLocal() => dateOnly(DateTime.now());

  /// Primeira data de vencimento a partir do início do plano.
  static DateTime initialNextDue(DateTime startDate, PreventiveFrequency frequency) {
    return dateOnly(startDate);
  }

  /// Próximo vencimento após uma execução na data agendada.
  static DateTime advanceDue(DateTime scheduledDate, PreventiveFrequency frequency) {
    final base = dateOnly(scheduledDate);
    return switch (frequency) {
      PreventiveFrequency.daily => base.add(const Duration(days: 1)),
      PreventiveFrequency.weekly => base.add(const Duration(days: 7)),
      PreventiveFrequency.monthly => _addMonths(base, 1),
      PreventiveFrequency.quarterly => _addMonths(base, 3),
      PreventiveFrequency.semiannual => _addMonths(base, 6),
      PreventiveFrequency.annual => _addMonths(base, 12),
    };
  }

  static DateTime _addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;
    while (month > 12) {
      month -= 12;
      year++;
    }
    final day = date.day;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }

  /// Data em que o alerta/backlog deve aparecer (antecedência).
  static DateTime alertDate(DateTime nextDue, int leadTimeDays) {
    return dateOnly(nextDue).subtract(Duration(days: leadTimeDays));
  }

  static bool shouldAppearInBacklog(DateTime nextDue, int leadTimeDays, DateTime today) {
    return !alertDate(nextDue, leadTimeDays).isAfter(today);
  }

  static bool isOverdue(DateTime nextDue, DateTime today) {
    return dateOnly(nextDue).isBefore(today);
  }
}
