import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/shared/domain/enums/financial_category.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';

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

  static const selectQuery = '''
    *,
    condominiums ( name ),
    materials ( name ),
    providers ( trade_name, legal_name ),
    work_orders ( os_number )
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
