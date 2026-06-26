import 'package:cond_manager/shared/domain/enums/location_type.dart';
import 'package:cond_manager/shared/domain/enums/priority_level.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/domain/enums/ticket_status.dart';
import 'package:equatable/equatable.dart';

class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.condominiumId,
    required this.ticketNumber,
    required this.requesterId,
    required this.locationType,
    required this.serviceType,
    required this.priority,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.unitId,
    this.commonAreaId,
    this.blockId,
    this.locationDescription,
    this.assignedTo,
    this.workOrderId,
    this.resolvedAt,
    this.analysisStartedAt,
    this.problemAcceptedAt,
    this.condominiumName,
    this.requesterName,
    this.assigneeName,
    this.rentalPropertyId,
    this.rentalPropertyTitle,
  });

  final String id;
  final String condominiumId;
  final int ticketNumber;
  final String requesterId;
  final LocationType locationType;
  final String? unitId;
  final String? commonAreaId;
  final String? blockId;
  final String? locationDescription;
  final ServiceType serviceType;
  final PriorityLevel priority;
  final String title;
  final String description;
  final TicketStatus status;
  final String? assignedTo;
  final String? workOrderId;
  final DateTime? resolvedAt;
  final DateTime? analysisStartedAt;
  final DateTime? problemAcceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? condominiumName;
  final String? requesterName;
  final String? assigneeName;
  final String? rentalPropertyId;
  final String? rentalPropertyTitle;

  String get displayNumber => 'CH-${ticketNumber.toString().padLeft(5, '0')}';

  bool get needsProblemAcceptance =>
      status == TicketStatus.inAnalysis && problemAcceptedAt == null;

  bool get canLinkWorkOrder =>
      problemAcceptedAt != null && workOrderId == null && !status.isTerminal;

  @override
  List<Object?> get props => [id, ticketNumber, status, updatedAt];
}

class TicketCreateInput extends Equatable {
  const TicketCreateInput({
    required this.condominiumId,
    required this.locationType,
    required this.serviceType,
    required this.priority,
    required this.title,
    required this.description,
    this.unitId,
    this.commonAreaId,
    this.locationDescription,
    this.rentalPropertyId,
  });

  final String condominiumId;
  final LocationType locationType;
  final String? unitId;
  final String? commonAreaId;
  final String? locationDescription;
  final String? rentalPropertyId;
  final ServiceType serviceType;
  final PriorityLevel priority;
  final String title;
  final String description;

  @override
  List<Object?> get props => [condominiumId, title];
}

class TicketInteraction extends Equatable {
  const TicketInteraction({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.message,
    required this.isInternal,
    required this.createdAt,
    this.authorName,
  });

  final String id;
  final String ticketId;
  final String authorId;
  final String message;
  final bool isInternal;
  final DateTime createdAt;
  final String? authorName;

  @override
  List<Object?> get props => [id, createdAt];
}

class TicketAttachment extends Equatable {
  const TicketAttachment({
    required this.id,
    required this.ticketId,
    required this.fileUrl,
    required this.filePath,
    required this.fileName,
    this.mimeType,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String fileUrl;
  final String filePath;
  final String fileName;
  final String? mimeType;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id];
}

class TicketListFilter extends Equatable {
  const TicketListFilter({
    this.condominiumId,
    this.status,
    this.priority,
  });

  final String? condominiumId;
  final TicketStatus? status;
  final PriorityLevel? priority;

  TicketListFilter copyWith({
    String? condominiumId,
    TicketStatus? status,
    PriorityLevel? priority,
    bool clearCondominium = false,
    bool clearStatus = false,
    bool clearPriority = false,
  }) {
    return TicketListFilter(
      condominiumId: clearCondominium ? null : (condominiumId ?? this.condominiumId),
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
    );
  }

  @override
  List<Object?> get props => [condominiumId, status, priority];
}

class UnitOption extends Equatable {
  const UnitOption({required this.id, required this.label});

  final String id;
  final String label;

  @override
  List<Object?> get props => [id];
}

class CommonAreaOption extends Equatable {
  const CommonAreaOption({required this.id, required this.label});

  final String id;
  final String label;

  @override
  List<Object?> get props => [id];
}

class PendingTicketFile extends Equatable {
  const PendingTicketFile({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final List<int> bytes;
  final String fileName;
  final String mimeType;

  @override
  List<Object?> get props => [fileName];
}
