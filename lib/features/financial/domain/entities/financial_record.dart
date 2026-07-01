import 'package:cond_manager/shared/domain/enums/condominium_bill_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_category.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:cond_manager/shared/domain/enums/rental_expense_entry_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:equatable/equatable.dart';

class FinancialRecord extends Equatable {
  const FinancialRecord({
    required this.id,
    required this.scope,
    this.condominiumId,
    this.condominiumName,
    required this.recordType,
    required this.category,
    required this.description,
    required this.amount,
    required this.taxAmount,
    this.laborHours,
    this.hourlyRate,
    this.materialId,
    this.materialName,
    required this.referenceDate,
    this.dueDate,
    this.paidAt,
    this.workOrderId,
    this.workOrderNumber,
    this.providerId,
    this.providerName,
    this.notes,
    this.unitId,
    this.unitLabel,
    this.blockId,
    this.blockName,
    this.rentalPropertyId,
    this.rentalPropertyTitle,
    this.rentalExpenseEntryType,
    this.condominiumBillType,
    this.expenseServiceType,
    this.materialCategoryId,
    this.materialCategoryName,
    this.isRecurringTemplate = false,
    this.recurrenceTemplateId,
    this.recurrenceDayOfMonth,
    this.recurrenceActive = true,
    this.allocationParentId,
    this.rentalChargeId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final FinancialScope scope;
  final String? condominiumId;
  final String? condominiumName;
  final FinancialRecordType recordType;
  final FinancialCategory category;
  final String description;
  final double amount;
  final double taxAmount;
  final double? laborHours;
  final double? hourlyRate;
  final String? materialId;
  final String? materialName;
  final DateTime referenceDate;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? workOrderId;
  final int? workOrderNumber;
  final String? providerId;
  final String? providerName;
  final String? notes;
  final String? unitId;
  final String? unitLabel;
  final String? blockId;
  final String? blockName;
  final String? rentalPropertyId;
  final String? rentalPropertyTitle;
  final RentalExpenseEntryType? rentalExpenseEntryType;
  final CondominiumBillType? condominiumBillType;
  final ServiceType? expenseServiceType;
  final String? materialCategoryId;
  final String? materialCategoryName;
  final bool isRecurringTemplate;
  final String? recurrenceTemplateId;
  final int? recurrenceDayOfMonth;
  final bool recurrenceActive;
  final String? allocationParentId;
  final String? rentalChargeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get totalWithTax => amount + taxAmount;

  bool get isPaid => paidAt != null;

  bool get isRentalModuleExpense => rentalExpenseEntryType != null;

  bool get isRentalModuleIncome => rentalChargeId != null;

  bool get isAllocationChild => allocationParentId != null;

  /// Lançamento do módulo manutenção (exclui despesas, receitas e rateios de locação).
  bool get belongsToMaintenanceModule =>
      !isRentalModuleExpense && !isRentalModuleIncome && !isAllocationChild;

  String? get workOrderDisplay =>
      workOrderNumber != null ? 'OS-${workOrderNumber!.toString().padLeft(5, '0')}' : null;

  @override
  List<Object?> get props => [id];
}

class FinancialListFilter extends Equatable {
  const FinancialListFilter({
    required this.scope,
    this.condominiumId,
    this.recordType,
    this.category,
    this.fromDate,
    this.toDate,
    this.paidOnly,
    this.excludeRentalModule = false,
  });

  final FinancialScope scope;
  final String? condominiumId;
  final FinancialRecordType? recordType;
  final FinancialCategory? category;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool? paidOnly;
  /// Quando true, omite lançamentos do módulo locação (despesas, receitas de cobrança e rateios).
  final bool excludeRentalModule;

  FinancialListFilter copyWith({
    FinancialScope? scope,
    String? condominiumId,
    FinancialRecordType? recordType,
    FinancialCategory? category,
    DateTime? fromDate,
    DateTime? toDate,
    bool? paidOnly,
    bool? excludeRentalModule,
    bool clearCondominium = false,
    bool clearRecordType = false,
    bool clearCategory = false,
    bool clearDates = false,
  }) {
    return FinancialListFilter(
      scope: scope ?? this.scope,
      condominiumId: clearCondominium ? null : (condominiumId ?? this.condominiumId),
      recordType: clearRecordType ? null : (recordType ?? this.recordType),
      category: clearCategory ? null : (category ?? this.category),
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
      paidOnly: paidOnly ?? this.paidOnly,
      excludeRentalModule: excludeRentalModule ?? this.excludeRentalModule,
    );
  }

  FinancialListFilter withReferenceMonth(DateTime? month) {
    if (month == null) return copyWith(clearDates: true);
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);
    return copyWith(fromDate: from, toDate: to);
  }

  DateTime? get referenceMonth =>
      fromDate == null ? null : DateTime(fromDate!.year, fromDate!.month, 1);

  @override
  List<Object?> get props =>
      [scope, condominiumId, recordType, category, fromDate, toDate, paidOnly, excludeRentalModule];
}

class FinancialCategoryBreakdown extends Equatable {
  const FinancialCategoryBreakdown({
    required this.category,
    required this.expenses,
    required this.income,
  });

  final FinancialCategory category;
  final double expenses;
  final double income;

  double get net => income - expenses;

  @override
  List<Object?> get props => [category];
}

class FinancialReportSummary extends Equatable {
  const FinancialReportSummary({
    required this.scope,
    this.condominiumId,
    this.condominiumName,
    required this.totalExpenses,
    required this.totalIncome,
    required this.totalTaxes,
    required this.totalLabor,
    required this.totalMaterials,
    required this.totalFreight,
    required this.totalContractedServices,
    required this.totalPersonnel,
    required this.recordCount,
    required this.byCategory,
  });

  final FinancialScope scope;
  final String? condominiumId;
  final String? condominiumName;
  final double totalExpenses;
  final double totalIncome;
  final double totalTaxes;
  final double totalLabor;
  final double totalMaterials;
  final double totalFreight;
  final double totalContractedServices;
  final double totalPersonnel;
  final int recordCount;
  final List<FinancialCategoryBreakdown> byCategory;

  double get balance => totalIncome - totalExpenses;

  @override
  List<Object?> get props => [scope, totalExpenses, totalIncome];
}

class FinancialRecordCreateInput extends Equatable {
  const FinancialRecordCreateInput({
    required this.scope,
    this.condominiumId,
    this.managementCompanyId,
    required this.recordType,
    required this.category,
    required this.description,
    required this.amount,
    this.taxAmount = 0,
    this.laborHours,
    this.hourlyRate,
    this.materialId,
    required this.referenceDate,
    this.dueDate,
    this.paidAt,
    this.workOrderId,
    this.providerId,
    this.notes,
    this.unitId,
    this.blockId,
    this.rentalPropertyId,
    this.rentalExpenseEntryType,
    this.condominiumBillType,
    this.expenseServiceType,
    this.materialCategoryId,
    this.isRecurringTemplate = false,
    this.recurrenceDayOfMonth,
    this.recurrenceActive = true,
    this.allocationParentId,
  });

  final FinancialScope scope;
  final String? condominiumId;
  final String? managementCompanyId;
  final FinancialRecordType recordType;
  final FinancialCategory category;
  final String description;
  final double amount;
  final double taxAmount;
  final double? laborHours;
  final double? hourlyRate;
  final String? materialId;
  final DateTime referenceDate;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? workOrderId;
  final String? providerId;
  final String? notes;
  final String? unitId;
  final String? blockId;
  final String? rentalPropertyId;
  final RentalExpenseEntryType? rentalExpenseEntryType;
  final CondominiumBillType? condominiumBillType;
  final ServiceType? expenseServiceType;
  final String? materialCategoryId;
  final bool isRecurringTemplate;
  final int? recurrenceDayOfMonth;
  final bool recurrenceActive;
  final String? allocationParentId;

  @override
  List<Object?> get props => [scope, description, amount];
}

class FinancialRecordUpdateInput extends Equatable {
  const FinancialRecordUpdateInput({
    required this.recordType,
    required this.category,
    required this.description,
    required this.amount,
    this.taxAmount = 0,
    this.laborHours,
    this.hourlyRate,
    this.materialId,
    required this.referenceDate,
    this.dueDate,
    this.paidAt,
    this.workOrderId,
    this.providerId,
    this.notes,
    this.unitId,
    this.blockId,
    this.rentalPropertyId,
    this.rentalExpenseEntryType,
    this.condominiumBillType,
    this.expenseServiceType,
    this.materialCategoryId,
    this.isRecurringTemplate = false,
    this.recurrenceDayOfMonth,
    this.recurrenceActive = true,
    this.allocationParentId,
  });

  final FinancialRecordType recordType;
  final FinancialCategory category;
  final String description;
  final double amount;
  final double taxAmount;
  final double? laborHours;
  final double? hourlyRate;
  final String? materialId;
  final DateTime referenceDate;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? workOrderId;
  final String? providerId;
  final String? notes;
  final String? unitId;
  final String? blockId;
  final String? rentalPropertyId;
  final RentalExpenseEntryType? rentalExpenseEntryType;
  final CondominiumBillType? condominiumBillType;
  final ServiceType? expenseServiceType;
  final String? materialCategoryId;
  final bool isRecurringTemplate;
  final int? recurrenceDayOfMonth;
  final bool recurrenceActive;
  final String? allocationParentId;

  @override
  List<Object?> get props => [description];
}
