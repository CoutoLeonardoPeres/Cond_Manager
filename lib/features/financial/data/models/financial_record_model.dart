import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/shared/domain/enums/condominium_bill_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_category.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:cond_manager/shared/domain/enums/rental_expense_entry_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';

class FinancialRecordModel {
  FinancialRecordModel({
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
  });

  final String id;
  final String scope;
  final String? condominiumId;
  final String? condominiumName;
  final String recordType;
  final String category;
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
  final String? unitId;
  final String? unitLabel;
  final String? blockId;
  final String? blockName;
  final String? rentalPropertyId;
  final String? rentalPropertyTitle;
  final String? rentalExpenseEntryType;
  final String? condominiumBillType;
  final String? expenseServiceType;
  final String? materialCategoryId;
  final String? materialCategoryName;
  final bool isRecurringTemplate;
  final String? recurrenceTemplateId;
  final int? recurrenceDayOfMonth;
  final bool recurrenceActive;
  final String? allocationParentId;

  static const selectQuery = '''
    *,
    condominiums ( name ),
    materials ( name ),
    providers ( trade_name, legal_name ),
    work_orders ( os_number ),
    units ( identifier ),
    blocks ( name ),
    rental_properties ( title ),
    material_categories ( name )
  ''';

  factory FinancialRecordModel.fromJson(Map<String, dynamic> json) {
    String? condoName;
    final condo = json['condominiums'];
    if (condo is Map<String, dynamic>) condoName = condo['name'] as String?;

    String? materialName;
    final mat = json['materials'];
    if (mat is Map<String, dynamic>) materialName = mat['name'] as String?;

    String? providerName;
    final prov = json['providers'];
    if (prov is Map<String, dynamic>) {
      final trade = prov['trade_name'] as String?;
      providerName = trade?.trim().isNotEmpty == true
          ? trade
          : prov['legal_name'] as String?;
    }

    int? osNumber;
    final wo = json['work_orders'];
    if (wo is Map<String, dynamic>) osNumber = wo['os_number'] as int?;

    String? unitLabel;
    final unit = json['units'];
    if (unit is Map<String, dynamic>) {
      unitLabel = unit['identifier'] as String?;
    }

    String? blockName;
    final block = json['blocks'];
    if (block is Map<String, dynamic>) {
      blockName = block['name'] as String?;
    }

    String? rentalPropertyTitle;
    final rentalProperty = json['rental_properties'];
    if (rentalProperty is Map<String, dynamic>) {
      rentalPropertyTitle = rentalProperty['title'] as String?;
    }

    String? materialCategoryName;
    final matCat = json['material_categories'];
    if (matCat is Map<String, dynamic>) materialCategoryName = matCat['name'] as String?;

    return FinancialRecordModel(
      id: json['id'] as String,
      scope: json['scope'] as String? ?? FinancialScope.condominium.value,
      condominiumId: json['condominium_id'] as String?,
      condominiumName: condoName,
      recordType: json['record_type'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      amount: parseNum(json['amount']),
      taxAmount: parseNum(json['tax_amount']),
      laborHours: json['labor_hours'] != null ? parseNum(json['labor_hours']) : null,
      hourlyRate: json['hourly_rate'] != null ? parseNum(json['hourly_rate']) : null,
      materialId: json['material_id'] as String?,
      materialName: materialName,
      referenceDate: DateTime.parse(json['reference_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      workOrderId: json['work_order_id'] as String?,
      workOrderNumber: osNumber,
      providerId: json['provider_id'] as String?,
      providerName: providerName,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      unitId: json['unit_id'] as String?,
      unitLabel: unitLabel,
      blockId: json['block_id'] as String?,
      blockName: blockName,
      rentalPropertyId: json['rental_property_id'] as String?,
      rentalPropertyTitle: rentalPropertyTitle,
      rentalExpenseEntryType: json['rental_expense_entry_type'] as String?,
      condominiumBillType: json['condominium_bill_type'] as String?,
      expenseServiceType: json['expense_service_type'] as String?,
      materialCategoryId: json['material_category_id'] as String?,
      materialCategoryName: materialCategoryName,
      isRecurringTemplate: json['is_recurring_template'] as bool? ?? false,
      recurrenceTemplateId: json['recurrence_template_id'] as String?,
      recurrenceDayOfMonth: json['recurrence_day_of_month'] as int?,
      recurrenceActive: json['recurrence_active'] as bool? ?? true,
      allocationParentId: json['allocation_parent_id'] as String?,
    );
  }

  static double parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  FinancialRecord toEntity() => FinancialRecord(
        id: id,
        scope: FinancialScope.fromValue(scope),
        condominiumId: condominiumId,
        condominiumName: condominiumName,
        recordType: FinancialRecordType.fromValue(recordType),
        category: FinancialCategory.fromValue(category),
        description: description,
        amount: amount,
        taxAmount: taxAmount,
        laborHours: laborHours,
        hourlyRate: hourlyRate,
        materialId: materialId,
        materialName: materialName,
        referenceDate: referenceDate,
        dueDate: dueDate,
        paidAt: paidAt,
        workOrderId: workOrderId,
        workOrderNumber: workOrderNumber,
        providerId: providerId,
        providerName: providerName,
        notes: notes,
        unitId: unitId,
        unitLabel: unitLabel,
        blockId: blockId,
        blockName: blockName,
        rentalPropertyId: rentalPropertyId,
        rentalPropertyTitle: rentalPropertyTitle,
        rentalExpenseEntryType: rentalExpenseEntryType != null
            ? RentalExpenseEntryType.fromValue(rentalExpenseEntryType!)
            : null,
        condominiumBillType: condominiumBillType != null
            ? CondominiumBillType.fromValue(condominiumBillType!)
            : null,
        expenseServiceType: expenseServiceType != null
            ? ServiceType.fromValue(expenseServiceType!)
            : null,
        materialCategoryId: materialCategoryId,
        materialCategoryName: materialCategoryName,
        isRecurringTemplate: isRecurringTemplate,
        recurrenceTemplateId: recurrenceTemplateId,
        recurrenceDayOfMonth: recurrenceDayOfMonth,
        recurrenceActive: recurrenceActive,
        allocationParentId: allocationParentId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static Map<String, dynamic> createPayload(
    FinancialRecordCreateInput input, {
    required String createdBy,
  }) {
    return {
      'scope': input.scope.value,
      'condominium_id': input.scope == FinancialScope.condominium
          ? input.condominiumId
          : null,
      'record_type': input.recordType.value,
      'category': input.category.value,
      'description': input.description.trim(),
      'amount': input.amount,
      'tax_amount': input.taxAmount,
      'labor_hours': input.laborHours,
      'hourly_rate': input.hourlyRate,
      'material_id': input.materialId,
      'reference_date': _dateStr(input.referenceDate),
      'due_date': input.dueDate != null ? _dateStr(input.dueDate!) : null,
      'paid_at': input.paidAt?.toUtc().toIso8601String(),
      'work_order_id': input.workOrderId,
      'provider_id': input.providerId,
      'notes': _trim(input.notes),
      'created_by': createdBy,
      ..._rentalExpensePayload(input),
    };
  }

  static Map<String, dynamic> updatePayload(FinancialRecordUpdateInput input) {
    return {
      'record_type': input.recordType.value,
      'category': input.category.value,
      'description': input.description.trim(),
      'amount': input.amount,
      'tax_amount': input.taxAmount,
      'labor_hours': input.laborHours,
      'hourly_rate': input.hourlyRate,
      'material_id': input.materialId,
      'reference_date': _dateStr(input.referenceDate),
      'due_date': input.dueDate != null ? _dateStr(input.dueDate!) : null,
      'paid_at': input.paidAt?.toUtc().toIso8601String(),
      'work_order_id': input.workOrderId,
      'provider_id': input.providerId,
      'notes': _trim(input.notes),
      ..._rentalExpenseUpdatePayload(input),
    };
  }

  static Map<String, dynamic> _rentalExpensePayload(FinancialRecordCreateInput input) {
    if (input.rentalExpenseEntryType == null) return const {};
    return {
      'unit_id': input.unitId,
      'block_id': input.blockId,
      'rental_property_id': input.rentalPropertyId,
      'rental_expense_entry_type': input.rentalExpenseEntryType!.value,
      if (input.condominiumBillType != null)
        'condominium_bill_type': input.condominiumBillType!.value,
      if (input.expenseServiceType != null)
        'expense_service_type': input.expenseServiceType!.value,
      if (input.materialCategoryId != null) 'material_category_id': input.materialCategoryId,
      'is_recurring_template': input.isRecurringTemplate,
      if (input.recurrenceDayOfMonth != null)
        'recurrence_day_of_month': input.recurrenceDayOfMonth,
      'recurrence_active': input.recurrenceActive,
      if (input.allocationParentId != null) 'allocation_parent_id': input.allocationParentId,
    };
  }

  static Map<String, dynamic> _rentalExpenseUpdatePayload(FinancialRecordUpdateInput input) {
    if (input.rentalExpenseEntryType == null) return const {};
    return {
      'unit_id': input.unitId,
      'block_id': input.blockId,
      'rental_property_id': input.rentalPropertyId,
      'rental_expense_entry_type': input.rentalExpenseEntryType!.value,
      if (input.condominiumBillType != null)
        'condominium_bill_type': input.condominiumBillType!.value,
      if (input.expenseServiceType != null)
        'expense_service_type': input.expenseServiceType!.value,
      if (input.materialCategoryId != null) 'material_category_id': input.materialCategoryId,
      'is_recurring_template': input.isRecurringTemplate,
      if (input.recurrenceDayOfMonth != null)
        'recurrence_day_of_month': input.recurrenceDayOfMonth,
      'recurrence_active': input.recurrenceActive,
      if (input.allocationParentId != null) 'allocation_parent_id': input.allocationParentId,
    };
  }

  static String _dateStr(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    return x.toIso8601String().split('T').first;
  }

  static String? _trim(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
