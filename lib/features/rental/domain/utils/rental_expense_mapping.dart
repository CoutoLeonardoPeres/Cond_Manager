import 'package:cond_manager/shared/domain/enums/condominium_bill_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_category.dart';
import 'package:cond_manager/shared/domain/enums/rental_expense_entry_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';

/// Mapeia tipos de despesa do módulo locação para categoria financeira.
FinancialCategory financialCategoryForRentalExpense({
  required RentalExpenseEntryType entryType,
  CondominiumBillType? billType,
}) {
  return switch (entryType) {
    RentalExpenseEntryType.material => FinancialCategory.materials,
    RentalExpenseEntryType.service => FinancialCategory.contractedServices,
    RentalExpenseEntryType.fixedBill => switch (billType) {
        CondominiumBillType.proLabore ||
        CondominiumBillType.syndic ||
        CondominiumBillType.administrator =>
          FinancialCategory.personnel,
        CondominiumBillType.officeSupplies => FinancialCategory.materials,
        CondominiumBillType.improvements => FinancialCategory.overhead,
        _ => FinancialCategory.overhead,
      },
  };
}

String rentalExpenseTypeLabel({
  required RentalExpenseEntryType? entryType,
  CondominiumBillType? billType,
  ServiceType? serviceType,
  String? materialCategoryName,
}) {
  if (entryType == null) return '—';
  return switch (entryType) {
    RentalExpenseEntryType.fixedBill => billType?.label ?? 'Conta fixa',
    RentalExpenseEntryType.service => serviceType?.label ?? 'Serviço',
    RentalExpenseEntryType.material => materialCategoryName ?? 'Material',
  };
}

String rentalExpenseScopeLabel({String? unitLabel, String? condominiumName}) {
  if (unitLabel != null && unitLabel.isNotEmpty) return 'Unidade $unitLabel';
  if (condominiumName != null && condominiumName.isNotEmpty) {
    return 'Condomínio ($condominiumName)';
  }
  return 'Condomínio';
}
