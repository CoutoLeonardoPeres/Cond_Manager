import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/shared/domain/enums/rental_expense_entry_type.dart';

/// Despesas do mês que podem ser ajustadas em lote (não são modelos).
List<FinancialRecord> rentalExpensesAdjustableForMonth(
  List<FinancialRecord> expenses,
  DateTime month,
) {
  return expenses.where((e) {
    if (e.isRecurringTemplate) return false;
    final ref = e.referenceDate;
    if (ref.year != month.year || ref.month != month.month) return false;
    return e.rentalExpenseEntryType == RentalExpenseEntryType.fixedBill ||
        e.recurrenceTemplateId != null;
  }).toList()
    ..sort((a, b) => a.description.compareTo(b.description));
}
