import 'package:cond_manager/shared/domain/enums/financial_category.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
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
  final DateTime createdAt;
  final DateTime updatedAt;

  double get totalWithTax => amount + taxAmount;

  bool get isPaid => paidAt != null;

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
  });

  final FinancialScope scope;
  final String? condominiumId;
  final FinancialRecordType? recordType;
  final FinancialCategory? category;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool? paidOnly;

  FinancialListFilter copyWith({
    FinancialScope? scope,
    String? condominiumId,
    FinancialRecordType? recordType,
    FinancialCategory? category,
    DateTime? fromDate,
    DateTime? toDate,
    bool? paidOnly,
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
    );
  }

  @override
  List<Object?> get props => [scope, condominiumId, recordType, category, fromDate, toDate];
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
  });

  final FinancialScope scope;
  final String? condominiumId;
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

  @override
  List<Object?> get props => [description];
}
