import 'package:cond_manager/shared/domain/enums/location_type.dart';
import 'package:cond_manager/shared/domain/enums/priority_level.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/domain/enums/work_order_status.dart';
import 'package:equatable/equatable.dart';

enum WorkOrderAssigneeType {
  none('none', 'Definir depois'),
  internal('internal', 'Funcionário interno'),
  provider('provider', 'Prestador de serviço');

  const WorkOrderAssigneeType(this.value, this.label);
  final String value;
  final String label;
}

class WorkOrder extends Equatable {
  const WorkOrder({
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
  final ServiceType serviceType;
  final PriorityLevel priority;
  final WorkOrderStatus status;
  final LocationType locationType;
  final String? unitId;
  final String? commonAreaId;
  final String? locationDescription;
  final String? requesterId;
  final String? internalResponsibleId;
  final String? providerId;
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

  String get displayNumber => 'OS-${osNumber.toString().padLeft(5, '0')}';

  String get assigneeLabel {
    if (internalResponsibleName != null) {
      return 'Interno: $internalResponsibleName';
    }
    if (providerName != null) return 'Prestador: $providerName';
    return 'Sem responsável';
  }

  @override
  List<Object?> get props => [id, osNumber, status, updatedAt];
}

class WorkOrderCreateInput extends Equatable {
  const WorkOrderCreateInput({
    required this.condominiumId,
    required this.title,
    required this.serviceType,
    required this.priority,
    required this.locationType,
    this.ticketId,
    this.description,
    this.internalResponsibleId,
    this.providerId,
    this.locationDescription,
    this.unitId,
    this.commonAreaId,
    this.dueDate,
    this.requesterId,
    this.rentalPropertyId,
  });

  final String condominiumId;
  final String? ticketId;
  final String title;
  final String? description;
  final ServiceType serviceType;
  final PriorityLevel priority;
  final LocationType locationType;
  final String? unitId;
  final String? commonAreaId;
  final String? locationDescription;
  final String? internalResponsibleId;
  final String? providerId;
  final DateTime? dueDate;
  final String? requesterId;
  final String? rentalPropertyId;

  @override
  List<Object?> get props => [condominiumId, title, ticketId];
}

class WorkOrderListFilter extends Equatable {
  const WorkOrderListFilter({
    this.condominiumId,
    this.status,
    this.rentalPropertyId,
    this.rentalExpensesOnly = false,
  });

  final String? condominiumId;
  final WorkOrderStatus? status;
  final String? rentalPropertyId;
  final bool rentalExpensesOnly;

  WorkOrderListFilter copyWith({
    String? condominiumId,
    WorkOrderStatus? status,
    String? rentalPropertyId,
    bool? rentalExpensesOnly,
    bool clearCondominium = false,
    bool clearStatus = false,
    bool clearRentalProperty = false,
  }) {
    return WorkOrderListFilter(
      condominiumId: clearCondominium ? null : (condominiumId ?? this.condominiumId),
      status: clearStatus ? null : (status ?? this.status),
      rentalPropertyId:
          clearRentalProperty ? null : (rentalPropertyId ?? this.rentalPropertyId),
      rentalExpensesOnly: rentalExpensesOnly ?? this.rentalExpensesOnly,
    );
  }

  @override
  List<Object?> get props => [condominiumId, status, rentalPropertyId, rentalExpensesOnly];
}

class WorkOrderHeaderUpdateInput extends Equatable {
  const WorkOrderHeaderUpdateInput({
    required this.title,
    required this.serviceType,
    required this.priority,
    this.description,
    this.rentalPropertyId,
  });

  final String title;
  final String? description;
  final ServiceType serviceType;
  final PriorityLevel priority;
  final String? rentalPropertyId;

  @override
  List<Object?> get props => [title, serviceType, priority, rentalPropertyId];
}

class InternalStaffOption extends Equatable {
  const InternalStaffOption({
    required this.profileId,
    required this.fullName,
    required this.roleLabel,
  });

  final String profileId;
  final String fullName;
  final String roleLabel;

  @override
  List<Object?> get props => [profileId];
}

class TicketLinkOption extends Equatable {
  const TicketLinkOption({
    required this.id,
    required this.label,
    this.displayNumber,
  });

  final String id;
  final String label;
  final String? displayNumber;

  @override
  List<Object?> get props => [id];
}
