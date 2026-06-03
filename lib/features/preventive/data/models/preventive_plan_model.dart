import 'package:cond_manager/features/preventive/domain/entities/preventive_plan.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/preventive_frequency.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';

class PreventivePlanModel {
  PreventivePlanModel({
    required this.id,
    required this.condominiumId,
    this.condominiumName,
    required this.name,
    this.description,
    required this.serviceType,
    required this.frequency,
    this.equipmentId,
    this.commonAreaId,
    this.unitId,
    this.responsibleId,
    this.responsibleName,
    this.providerId,
    this.providerName,
    required this.startDate,
    required this.nextDueDate,
    this.lastExecutedAt,
    required this.leadTimeDays,
    required this.autoGenerateOs,
    required this.estimatedCost,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.checklistItems = const [],
  });

  final String id;
  final String condominiumId;
  final String? condominiumName;
  final String name;
  final String? description;
  final String serviceType;
  final String frequency;
  final String? equipmentId;
  final String? commonAreaId;
  final String? unitId;
  final String? responsibleId;
  final String? responsibleName;
  final String? providerId;
  final String? providerName;
  final DateTime startDate;
  final DateTime nextDueDate;
  final DateTime? lastExecutedAt;
  final int leadTimeDays;
  final bool autoGenerateOs;
  final double estimatedCost;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PreventiveChecklistItem> checklistItems;

  static const planSelect = '''
    *,
    condominiums ( name ),
    responsible:profiles!preventive_plans_responsible_id_fkey ( full_name ),
    provider:providers ( trade_name, legal_name )
  ''';

  factory PreventivePlanModel.fromJson(
    Map<String, dynamic> json, {
    List<PreventiveChecklistItem> checklist = const [],
  }) {
    String? condoName;
    final condo = json['condominiums'];
    if (condo is Map<String, dynamic>) condoName = condo['name'] as String?;

    String? responsibleName;
    final resp = json['responsible'];
    if (resp is Map<String, dynamic>) responsibleName = resp['full_name'] as String?;

    String? providerName;
    final prov = json['provider'];
    if (prov is Map<String, dynamic>) {
      final trade = prov['trade_name'] as String?;
      providerName = trade?.trim().isNotEmpty == true
          ? trade
          : prov['legal_name'] as String?;
    }

    return PreventivePlanModel(
      id: json['id'] as String,
      condominiumId: json['condominium_id'] as String,
      condominiumName: condoName,
      name: json['name'] as String,
      description: json['description'] as String?,
      serviceType: json['service_type'] as String,
      frequency: json['frequency'] as String,
      equipmentId: json['equipment_id'] as String?,
      commonAreaId: json['common_area_id'] as String?,
      unitId: json['unit_id'] as String?,
      responsibleId: json['responsible_id'] as String?,
      responsibleName: responsibleName,
      providerId: json['provider_id'] as String?,
      providerName: providerName,
      startDate: DateTime.parse(json['start_date'] as String),
      nextDueDate: DateTime.parse(json['next_due_date'] as String),
      lastExecutedAt: json['last_executed_at'] != null
          ? DateTime.parse(json['last_executed_at'] as String)
          : null,
      leadTimeDays: json['lead_time_days'] as int? ?? 7,
      autoGenerateOs: json['auto_generate_os'] as bool? ?? true,
      estimatedCost: _num(json['estimated_cost']),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      checklistItems: checklist,
    );
  }

  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  PreventivePlan toEntity({String? locationLabel}) => PreventivePlan(
        id: id,
        condominiumId: condominiumId,
        condominiumName: condominiumName,
        name: name,
        description: description,
        serviceType: ServiceType.fromValue(serviceType),
        frequency: PreventiveFrequency.fromValue(frequency),
        equipmentId: equipmentId,
        commonAreaId: commonAreaId,
        unitId: unitId,
        locationLabel: locationLabel,
        responsibleId: responsibleId,
        responsibleName: responsibleName,
        providerId: providerId,
        providerName: providerName,
        startDate: startDate,
        nextDueDate: nextDueDate,
        lastExecutedAt: lastExecutedAt,
        leadTimeDays: leadTimeDays,
        autoGenerateOs: autoGenerateOs,
        estimatedCost: estimatedCost,
        status: EntityStatus.fromValue(status),
        checklistItems: checklistItems,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static Map<String, dynamic> createPayload(
    PreventivePlanCreateInput input, {
    required String createdBy,
    required DateTime nextDueDate,
  }) {
    return {
      'condominium_id': input.condominiumId,
      'name': input.name.trim(),
      'description': _trim(input.description),
      'service_type': input.serviceType.value,
      'frequency': input.frequency.value,
      'unit_id': input.unitId,
      'common_area_id': input.commonAreaId,
      'responsible_id': input.responsibleId,
      'provider_id': input.providerId,
      'start_date': _dateStr(input.startDate),
      'next_due_date': _dateStr(nextDueDate),
      'lead_time_days': input.leadTimeDays,
      'auto_generate_os': input.autoGenerateOs,
      'estimated_cost': input.estimatedCost,
      'created_by': createdBy,
    };
  }

  static Map<String, dynamic> updatePayload(PreventivePlanUpdateInput input) {
    return {
      'name': input.name.trim(),
      'description': _trim(input.description),
      'service_type': input.serviceType.value,
      'frequency': input.frequency.value,
      'unit_id': input.unitId,
      'common_area_id': input.commonAreaId,
      'responsible_id': input.responsibleId,
      'provider_id': input.providerId,
      'next_due_date': _dateStr(input.nextDueDate),
      'lead_time_days': input.leadTimeDays,
      'auto_generate_os': input.autoGenerateOs,
      'estimated_cost': input.estimatedCost,
      'status': input.status.value,
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

class PreventiveChecklistItemModel {
  static PreventiveChecklistItem fromJson(Map<String, dynamic> json) {
    return PreventiveChecklistItem(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      description: json['description'] as String,
      isRequired: json['is_required'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
