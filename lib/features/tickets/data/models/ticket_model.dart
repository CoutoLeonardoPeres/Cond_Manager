import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/shared/domain/enums/location_type.dart';
import 'package:cond_manager/shared/domain/enums/priority_level.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/domain/enums/ticket_status.dart';

class TicketModel {
  TicketModel({
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
  });

  final String id;
  final String condominiumId;
  final int ticketNumber;
  final String requesterId;
  final String locationType;
  final String? unitId;
  final String? commonAreaId;
  final String? blockId;
  final String? locationDescription;
  final String serviceType;
  final String priority;
  final String title;
  final String description;
  final String status;
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

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final condos = json['condominiums'];
    final requester = json['requester'];
    final assignee = json['assignee'];

    return TicketModel(
      id: json['id'] as String,
      condominiumId: json['condominium_id'] as String,
      ticketNumber: json['ticket_number'] as int,
      requesterId: json['requester_id'] as String,
      locationType: json['location_type'] as String,
      unitId: json['unit_id'] as String?,
      commonAreaId: json['common_area_id'] as String?,
      blockId: json['block_id'] as String?,
      locationDescription: json['location_description'] as String?,
      serviceType: json['service_type'] as String,
      priority: json['priority'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      assignedTo: json['assigned_to'] as String?,
      workOrderId: json['work_order_id'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      analysisStartedAt: json['analysis_started_at'] != null
          ? DateTime.parse(json['analysis_started_at'] as String)
          : null,
      problemAcceptedAt: json['problem_accepted_at'] != null
          ? DateTime.parse(json['problem_accepted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      condominiumName: condos is Map ? condos['name'] as String? : null,
      requesterName: requester is Map ? requester['full_name'] as String? : null,
      assigneeName: assignee is Map ? assignee['full_name'] as String? : null,
    );
  }

  Ticket toEntity() => Ticket(
        id: id,
        condominiumId: condominiumId,
        ticketNumber: ticketNumber,
        requesterId: requesterId,
        locationType: LocationType.fromValue(locationType),
        unitId: unitId,
        commonAreaId: commonAreaId,
        blockId: blockId,
        locationDescription: locationDescription,
        serviceType: ServiceType.fromValue(serviceType),
        priority: PriorityLevel.fromValue(priority),
        title: title,
        description: description,
        status: TicketStatus.fromValue(status),
        assignedTo: assignedTo,
        workOrderId: workOrderId,
        resolvedAt: resolvedAt,
        analysisStartedAt: analysisStartedAt,
        problemAcceptedAt: problemAcceptedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        condominiumName: condominiumName,
        requesterName: requesterName,
        assigneeName: assigneeName,
      );

  static Map<String, dynamic> createPayload(
    TicketCreateInput input, {
    required String requesterId,
  }) {
    final map = <String, dynamic>{
      'condominium_id': input.condominiumId,
      'requester_id': requesterId,
      'location_type': input.locationType.value,
      'service_type': input.serviceType.value,
      'priority': input.priority.value,
      'title': input.title.trim(),
      'description': input.description.trim(),
    };
    if (input.unitId != null) map['unit_id'] = input.unitId;
    if (input.commonAreaId != null) map['common_area_id'] = input.commonAreaId;
    if (input.rentalPropertyId != null) map['rental_property_id'] = input.rentalPropertyId;
    final loc = input.locationDescription?.trim();
    if (loc != null && loc.isNotEmpty) map['location_description'] = loc;
    return map;
  }
}

class TicketInteractionModel {
  TicketInteractionModel({
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

  factory TicketInteractionModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    return TicketInteractionModel(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      authorId: json['author_id'] as String,
      message: json['message'] as String,
      isInternal: json['is_internal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: author is Map ? author['full_name'] as String? : null,
    );
  }

  TicketInteraction toEntity() => TicketInteraction(
        id: id,
        ticketId: ticketId,
        authorId: authorId,
        message: message,
        isInternal: isInternal,
        createdAt: createdAt,
        authorName: authorName,
      );
}

class TicketAttachmentModel {
  TicketAttachmentModel({
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

  factory TicketAttachmentModel.fromJson(Map<String, dynamic> json) {
    return TicketAttachmentModel(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      fileUrl: json['file_url'] as String,
      filePath: json['file_path'] as String,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  TicketAttachment toEntity() => TicketAttachment(
        id: id,
        ticketId: ticketId,
        fileUrl: fileUrl,
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
        createdAt: createdAt,
      );
}
