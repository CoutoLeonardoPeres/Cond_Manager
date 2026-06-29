import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_expense_mapping.dart';
import 'package:cond_manager/shared/domain/enums/rental_expense_entry_type.dart';

enum RentalExpenseDueAlertKind {
  generateRequired,
  overdue,
  dueSoon,
}

class RentalExpenseDueAlert {
  const RentalExpenseDueAlert({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.dueDate,
    required this.daysFromToday,
    this.expenseId,
    this.templateId,
  });

  final RentalExpenseDueAlertKind kind;
  final String title;
  final String subtitle;
  final DateTime dueDate;
  final int daysFromToday;
  final String? expenseId;
  final String? templateId;

  int get sortOrder => switch (kind) {
        RentalExpenseDueAlertKind.overdue => 0,
        RentalExpenseDueAlertKind.generateRequired => 1,
        RentalExpenseDueAlertKind.dueSoon => 2,
      };
}

DateTime rentalExpenseDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime rentalExpenseDueDate(FinancialRecord record, {DateTime? month}) {
  if (record.dueDate != null) {
    return rentalExpenseDateOnly(record.dueDate!);
  }
  if (record.isRecurringTemplate && month != null) {
    final day = (record.recurrenceDayOfMonth ?? 1).clamp(1, 28);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(month.year, month.month, day.clamp(1, lastDay));
  }
  return rentalExpenseDateOnly(record.referenceDate);
}

bool _hasGeneratedFromTemplate(
  List<FinancialRecord> expenses,
  String templateId,
  DateTime month,
) {
  return expenses.any(
    (e) =>
        e.recurrenceTemplateId == templateId &&
        e.referenceDate.year == month.year &&
        e.referenceDate.month == month.month,
  );
}

bool _isFixedBillCandidate(FinancialRecord e) {
  if (e.isRecurringTemplate || e.isAllocationChild) return false;
  return e.rentalExpenseEntryType == RentalExpenseEntryType.fixedBill ||
      e.recurrenceTemplateId != null;
}

/// Alertas de vencimento e geração de contas fixas (janela padrão: 7 dias).
List<RentalExpenseDueAlert> computeRentalExpenseDueAlerts(
  List<FinancialRecord> expenses, {
  DateTime? anchor,
  int lookaheadDays = 7,
}) {
  final today = rentalExpenseDateOnly(anchor ?? DateTime.now());
  final month = DateTime(today.year, today.month);
  final alerts = <RentalExpenseDueAlert>[];

  for (final template in expenses) {
    if (!template.isRecurringTemplate || !template.recurrenceActive) continue;
    if (template.isAllocationChild) continue;

    if (_hasGeneratedFromTemplate(expenses, template.id, month)) continue;

    final due = rentalExpenseDueDate(template, month: month);
    final days = due.difference(today).inDays;
    if (days > lookaheadDays) continue;

    final typeLabel = rentalExpenseTypeLabel(
      entryType: template.rentalExpenseEntryType,
      billType: template.condominiumBillType,
      serviceType: template.expenseServiceType,
      materialCategoryName: template.materialCategoryName,
    );

    alerts.add(
      RentalExpenseDueAlert(
        kind: RentalExpenseDueAlertKind.generateRequired,
        title: 'Gerar: ${template.description}',
        subtitle: days < 0
            ? '$typeLabel · venceu em ${due.day.toString().padLeft(2, '0')}/${due.month.toString().padLeft(2, '0')} — gere o lançamento do mês'
            : '$typeLabel · vence em $days dia(s) (${due.day.toString().padLeft(2, '0')}/${due.month.toString().padLeft(2, '0')})',
        dueDate: due,
        daysFromToday: days,
        templateId: template.id,
      ),
    );
  }

  for (final expense in expenses) {
    if (!_isFixedBillCandidate(expense) || expense.isPaid) continue;

    final due = rentalExpenseDueDate(expense);
    final days = due.difference(today).inDays;
    if (days > lookaheadDays) continue;

    final typeLabel = rentalExpenseTypeLabel(
      entryType: expense.rentalExpenseEntryType,
      billType: expense.condominiumBillType,
      serviceType: expense.expenseServiceType,
      materialCategoryName: expense.materialCategoryName,
    );
    final scope = expense.condominiumName ?? expense.unitLabel ?? '';

    alerts.add(
      RentalExpenseDueAlert(
        kind: days < 0 ? RentalExpenseDueAlertKind.overdue : RentalExpenseDueAlertKind.dueSoon,
        title: expense.description,
        subtitle: days < 0
            ? '$typeLabel${scope.isNotEmpty ? ' · $scope' : ''} · ${days.abs()} dia(s) em atraso'
            : '$typeLabel${scope.isNotEmpty ? ' · $scope' : ''} · vence em $days dia(s)',
        dueDate: due,
        daysFromToday: days,
        expenseId: expense.id,
      ),
    );
  }

  alerts.sort((a, b) {
    final order = a.sortOrder.compareTo(b.sortOrder);
    if (order != 0) return order;
    return a.daysFromToday.compareTo(b.daysFromToday);
  });

  return alerts;
}
