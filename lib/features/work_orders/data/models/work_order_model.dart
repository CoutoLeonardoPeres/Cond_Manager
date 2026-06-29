import 'package:cond_manager/features/work_orders/data/models/work_order_material_model.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/shared/domain/enums/location_type.dart';
import 'package:cond_manager/shared/domain/enums/priority_level.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/domain/enums/work_order_status.dart';

class WorkOrderModel {
  WorkOrderModel({
    required this.id,
    required this.condominiumId,
    required this.osNumber,
    required this.title,
    required this.serviceType,
    required this.priority,
    required this.status,
    required this.locationType,
    required this.createdAt,
    required this.updatedAt,
    this.ticketId,
    this.description,
    this.requesterId,
    this.internalResponsibleId,
    this.providerId,
    this.unitId,
    this.commonAreaId,
    this.locationDescription,
    this.dueDate,
    this.startedAt,
    this.completedAt,
    this.condominiumName,
    this.ticketNumber,
    this.ticketTitle,
    this.internalResponsibleName,
    this.providerName,
    this.createdByName,
    this.rentalPropertyId,
    this.rentalPropertyTitle,
    this.actualCost,
  });

  final String id;
  final String condominiumId;
  final int osNumber;
  final String? ticketId;
  final String title;
  final String? description;
  final String serviceType;
  final String priority;
  final String status;
  final String locationType;
  final String? requesterId;
  final String? internalResponsibleId;
  final String? providerId;
  final String? unitId;
  final String? commonAreaId;
  final String? locationDescription;
  final DateTime? dueDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? condominiumName;
  final int? ticketNumber;
  final String? ticketTitle;
  final String? internalResponsibleName;
  final String? providerName;
  final String? createdByName;
  final String? rentalPropertyId;
  final String? rentalPropertyTitle;
  final double? actualCost;

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    final condos = json['condominiums'];
    final ticket = json['ticket'] ?? json['tickets'];
    final internal = json['internal'];
    final provider = json['provider'];
    final creator = json['creator'];
    final rentalProperty = json['rental_property'] ?? json['rental_properties'];

    return WorkOrderModel(
      id: json['id'] as String,
      condominiumId: json['condominium_id'] as String,
      osNumber: json['os_number'] as int,
      ticketId: json['ticket_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      serviceType: json['service_type'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      locationType: json['location_type'] as String,
      requesterId: json['requester_id'] as String?,
      internalResponsibleId: json['internal_responsible_id'] as String?,
      providerId: json['provider_id'] as String?,
      unitId: json['unit_id'] as String?,
      commonAreaId: json['common_area_id'] as String?,
      locationDescription: json['location_description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      condominiumName: condos is Map ? condos['name'] as String? : null,
      ticketNumber: ticket is Map ? ticket['ticket_number'] as int? : null,
      ticketTitle: ticket is Map ? ticket['title'] as String? : null,
      internalResponsibleName:
          internal is Map ? internal['full_name'] as String? : null,
      providerName: provider is Map
          ? (provider['trade_name'] as String? ?? provider['legal_name'] as String?)
          : null,
      createdByName: creator is Map ? creator['full_name'] as String? : null,
      rentalPropertyId: json['rental_property_id'] as String?,
      rentalPropertyTitle: rentalProperty is Map ? rentalProperty['title'] as String? : null,
      actualCost: json['actual_cost'] != null
          ? WorkOrderMaterialModel.parseNum(json['actual_cost'])
          : null,
    );
  }

  WorkOrder toEntity() => WorkOrder(
        id: id,
        condominiumId: condominiumId,
        osNumber: osNumber,
        ticketId: ticketId,
        title: title,
        description: description,
        serviceType: ServiceType.fromValue(serviceType),
        priority: PriorityLevel.fromValue(priority),
        status: WorkOrderStatus.fromValue(status),
        locationType: LocationType.fromValue(locationType),
        requesterId: requesterId,
        internalResponsibleId: internalResponsibleId,
        providerId: providerId,
        unitId: unitId,
        commonAreaId: commonAreaId,
        locationDescription: locationDescription,
        dueDate: dueDate,
        startedAt: startedAt,
        completedAt: completedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        condominiumName: condominiumName,
        ticketNumber: ticketNumber,
        ticketTitle: ticketTitle,
        internalResponsibleName: internalResponsibleName,
        providerName: providerName,
        createdByName: createdByName,
        rentalPropertyId: rentalPropertyId,
        rentalPropertyTitle: rentalPropertyTitle,
        actualCost: actualCost,
      );

  static Map<String, dynamic> createPayload(
    WorkOrderCreateInput input, {
    required String createdBy,
    String? requesterId,
  }) {
    final map = <String, dynamic>{
      'condominium_id': input.condominiumId,
      'title': input.title.trim(),
      'service_type': input.serviceType.value,
      'priority': input.priority.value,
      'location_type': input.locationType.value,
      'created_by': createdBy,
      'requester_id': input.requesterId ?? requesterId ?? createdBy,
    };
    if (input.ticketId != null) map['ticket_id'] = input.ticketId;
    final desc = input.description?.trim();
    if (desc != null && desc.isNotEmpty) map['description'] = desc;
    if (input.internalResponsibleId != null) {
      map['internal_responsible_id'] = input.internalResponsibleId;
    }
    if (input.providerId != null) map['provider_id'] = input.providerId;
    if (input.unitId != null) map['unit_id'] = input.unitId;
    if (input.commonAreaId != null) map['common_area_id'] = input.commonAreaId;
    if (input.rentalPropertyId != null) map['rental_property_id'] = input.rentalPropertyId;
    final loc = input.locationDescription?.trim();
    if (loc != null && loc.isNotEmpty) map['location_description'] = loc;
    if (input.dueDate != null) {
      map['due_date'] = input.dueDate!.toUtc().toIso8601String();
    }
    return map;
  }

  static Map<String, dynamic> headerUpdatePayload(WorkOrderHeaderUpdateInput input) {
    final map = <String, dynamic>{
      'title': input.title.trim(),
      'service_type': input.serviceType.value,
      'priority': input.priority.value,
    };
    final desc = input.description?.trim();
    if (desc != null && desc.isNotEmpty) {
      map['description'] = desc;
    } else {
      map['description'] = null;
    }
    if (input.rentalPropertyId != null) {
      map['rental_property_id'] = input.rentalPropertyId;
    }
    return map;
  }
}
