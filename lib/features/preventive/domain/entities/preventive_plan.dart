import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/preventive_execution_status.dart';
import 'package:cond_manager/shared/domain/enums/preventive_frequency.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:equatable/equatable.dart';

enum PreventiveAssigneeType {
  none('none', 'Definir na OS'),
  internal('internal', 'Equipe interna'),
  provider('provider', 'Prestador');

  const PreventiveAssigneeType(this.value, this.label);
  final String value;
  final String label;
}

class PreventiveChecklistItem extends Equatable {
  const PreventiveChecklistItem({
    required this.id,
    required this.planId,
    required this.description,
    required this.isRequired,
    required this.sortOrder,
  });

  final String id;
  final String planId;
  final String description;
  final bool isRequired;
  final int sortOrder;

  @override
  List<Object?> get props => [id];
}

class PreventivePlan extends Equatable {
  const PreventivePlan({
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
    this.locationLabel,
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
    required this.checklistItems,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String condominiumId;
  final String? condominiumName;
  final String name;
  final String? description;
  final ServiceType serviceType;
  final PreventiveFrequency frequency;
  final String? equipmentId;
  final String? commonAreaId;
  final String? unitId;
  final String? locationLabel;
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
  final EntityStatus status;
  final List<PreventiveChecklistItem> checklistItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  PreventiveAssigneeType get assigneeType {
    if (providerId != null) return PreventiveAssigneeType.provider;
    if (responsibleId != null) return PreventiveAssigneeType.internal;
    return PreventiveAssigneeType.none;
  }

  String get assigneeLabel {
    if (providerName != null) return providerName!;
    if (responsibleName != null) return responsibleName!;
    return 'Sem responsável fixo';
  }

  @override
  List<Object?> get props => [id, nextDueDate];
}

class PreventiveBacklogItem extends Equatable {
  const PreventiveBacklogItem({
    required this.id,
    required this.planId,
    required this.planName,
    required this.condominiumId,
    this.condominiumName,
    required this.serviceType,
    required this.scheduledDate,
    required this.status,
    this.workOrderId,
    this.osNumber,
    this.assigneeLabel,
    required this.autoGenerateOs,
    this.leadTimeDays = 7,
  });

  final String id;
  final String planId;
  final String planName;
  final String condominiumId;
  final String? condominiumName;
  final ServiceType serviceType;
  final DateTime scheduledDate;
  final PreventiveExecutionStatus status;
  final String? workOrderId;
  final int? osNumber;
  final String? assigneeLabel;
  final bool autoGenerateOs;
  final int leadTimeDays;

  String? get osDisplayNumber =>
      osNumber != null ? 'OS-${osNumber!.toString().padLeft(5, '0')}' : null;

  bool get hasWorkOrder => workOrderId != null;

  @override
  List<Object?> get props => [id, status];
}

class PreventivePlanListFilter extends Equatable {
  const PreventivePlanListFilter({this.condominiumId, this.status});

  final String? condominiumId;
  final EntityStatus? status;

  PreventivePlanListFilter copyWith({
    String? condominiumId,
    EntityStatus? status,
    bool clearCondominium = false,
    bool clearStatus = false,
  }) {
    return PreventivePlanListFilter(
      condominiumId: clearCondominium ? null : (condominiumId ?? this.condominiumId),
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  List<Object?> get props => [condominiumId, status];
}

class PreventiveChecklistItemInput extends Equatable {
  const PreventiveChecklistItemInput({
    required this.description,
    this.isRequired = true,
    this.sortOrder = 0,
  });

  final String description;
  final bool isRequired;
  final int sortOrder;

  @override
  List<Object?> get props => [description];
}

class PreventivePlanCreateInput extends Equatable {
  const PreventivePlanCreateInput({
    required this.condominiumId,
    required this.name,
    this.description,
    required this.serviceType,
    required this.frequency,
    this.unitId,
    this.commonAreaId,
    this.responsibleId,
    this.providerId,
    required this.startDate,
    required this.leadTimeDays,
    required this.autoGenerateOs,
    this.estimatedCost = 0,
    required this.checklistItems,
  });

  final String condominiumId;
  final String name;
  final String? description;
  final ServiceType serviceType;
  final PreventiveFrequency frequency;
  final String? unitId;
  final String? commonAreaId;
  final String? responsibleId;
  final String? providerId;
  final DateTime startDate;
  final int leadTimeDays;
  final bool autoGenerateOs;
  final double estimatedCost;
  final List<PreventiveChecklistItemInput> checklistItems;

  @override
  List<Object?> get props => [condominiumId, name];
}

class PreventivePlanUpdateInput extends Equatable {
  const PreventivePlanUpdateInput({
    required this.name,
    this.description,
    required this.serviceType,
    required this.frequency,
    this.unitId,
    this.commonAreaId,
    this.responsibleId,
    this.providerId,
    required this.nextDueDate,
    required this.leadTimeDays,
    required this.autoGenerateOs,
    this.estimatedCost = 0,
    required this.status,
    required this.checklistItems,
  });

  final String name;
  final String? description;
  final ServiceType serviceType;
  final PreventiveFrequency frequency;
  final String? unitId;
  final String? commonAreaId;
  final String? responsibleId;
  final String? providerId;
  final DateTime nextDueDate;
  final int leadTimeDays;
  final bool autoGenerateOs;
  final double estimatedCost;
  final EntityStatus status;
  final List<PreventiveChecklistItemInput> checklistItems;

  @override
  List<Object?> get props => [name];
}

class PreventiveAgendaSyncResult extends Equatable {
  const PreventiveAgendaSyncResult({
    required this.executionsCreated,
    required this.workOrdersCreated,
    required this.notificationsCreated,
  });

  final int executionsCreated;
  final int workOrdersCreated;
  final int notificationsCreated;

  @override
  List<Object?> get props => [executionsCreated, workOrdersCreated];
}
