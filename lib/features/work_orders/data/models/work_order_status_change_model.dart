import 'package:cond_manager/features/tickets/domain/entities/status_change_log.dart';
import 'package:cond_manager/shared/domain/enums/work_order_status.dart';

class WorkOrderStatusChangeModel {
  WorkOrderStatusChangeModel({
    required this.id,
    required this.fromStatus,
    required this.toStatus,
    required this.createdAt,
    this.notes,
    this.changedByName,
  });

  final String id;
  final String? fromStatus;
  final String toStatus;
  final String? notes;
  final DateTime createdAt;
  final String? changedByName;

  factory WorkOrderStatusChangeModel.fromJson(Map<String, dynamic> json) {
    final author = json['changer'];
    return WorkOrderStatusChangeModel(
      id: json['id'] as String,
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      changedByName: author is Map ? author['full_name'] as String? : null,
    );
  }

  StatusChangeLog toEntity() => StatusChangeLog(
        id: id,
        fromStatus: fromStatus != null
            ? WorkOrderStatus.fromValue(fromStatus!).label
            : null,
        toStatus: WorkOrderStatus.fromValue(toStatus).label,
        changedByName: changedByName ?? 'Usuário',
        notes: notes,
        createdAt: createdAt,
      );
}
