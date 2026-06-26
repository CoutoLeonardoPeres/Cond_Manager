import 'package:cond_manager/features/work_orders/domain/entities/work_order_labor.dart';
import 'package:cond_manager/shared/domain/enums/labor_source.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';

class WorkOrderLaborModel {
  WorkOrderLaborModel({
    required this.id,
    required this.workOrderId,
    required this.laborSource,
    required this.serviceType,
    required this.workerName,
    required this.workerCount,
    required this.hours,
    required this.hourlyRate,
    required this.travelCost,
    required this.totalCost,
    this.providerId,
    this.providerName,
    this.profileId,
    this.profileName,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String workOrderId;
  final String laborSource;
  final String serviceType;
  final String workerName;
  final int workerCount;
  final double hours;
  final double hourlyRate;
  final double travelCost;
  final double totalCost;
  final String? providerId;
  final String? providerName;
  final String? profileId;
  final String? profileName;
  final String? notes;
  final DateTime createdAt;

  static const selectQuery = '''
    *,
    provider:providers ( trade_name, legal_name )
  ''';

  factory WorkOrderLaborModel.fromJson(Map<String, dynamic> json) {
    String? providerName;
    final prov = json['provider'];
    if (prov is Map<String, dynamic>) {
      final trade = prov['trade_name'] as String?;
      providerName = trade?.trim().isNotEmpty == true
          ? trade
          : prov['legal_name'] as String?;
    }

    String? profileName;
    final profile = json['profile'];
    if (profile is Map<String, dynamic>) {
      profileName = profile['full_name'] as String?;
    }

    return WorkOrderLaborModel(
      id: json['id'] as String,
      workOrderId: json['work_order_id'] as String,
      laborSource: json['labor_source'] as String? ?? LaborSource.thirdParty.value,
      serviceType: json['service_type'] as String? ?? ServiceType.other.value,
      workerName: json['worker_name'] as String,
      workerCount: json['worker_count'] as int? ?? 1,
      hours: parseNum(json['hours']),
      hourlyRate: parseNum(json['hourly_rate']),
      travelCost: parseNum(json['travel_cost']),
      totalCost: parseNum(json['total_cost']),
      providerId: json['provider_id'] as String?,
      providerName: providerName,
      profileId: json['profile_id'] as String?,
      profileName: profileName,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  WorkOrderLaborLine toEntity() {
    final laborSubtotal = workerCount * hours * hourlyRate;
    return WorkOrderLaborLine(
      id: id,
      workOrderId: workOrderId,
      laborSource: LaborSource.fromValue(laborSource),
      serviceType: ServiceType.fromValue(serviceType),
      workerName: workerName,
      workerCount: workerCount,
      hours: hours,
      hourlyRate: hourlyRate,
      travelCost: travelCost,
      laborSubtotal: laborSubtotal,
      totalCost: totalCost,
      providerId: providerId,
      providerName: providerName,
      profileId: profileId,
      profileName: profileName,
      notes: notes,
      createdAt: createdAt,
    );
  }

  static Map<String, dynamic> insertPayload(AddWorkOrderLaborInput input) {
    return {
      'work_order_id': input.workOrderId,
      'labor_source': input.laborSource.value,
      'service_type': input.serviceType.value,
      'worker_name': input.workerName.trim(),
      'worker_count': input.workerCount,
      'hours': input.hours,
      'hourly_rate': input.hourlyRate,
      'travel_cost': input.travelCost,
      'provider_id': input.laborSource == LaborSource.thirdParty ? input.providerId : null,
      'profile_id': input.laborSource == LaborSource.internalTeam ? input.profileId : null,
      'notes': _trim(input.notes),
    };
  }

  static double parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static String? _trim(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
