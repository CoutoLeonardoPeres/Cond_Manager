import 'package:equatable/equatable.dart';

class StatusChangeLog extends Equatable {
  const StatusChangeLog({
    required this.id,
    required this.fromStatus,
    required this.toStatus,
    required this.changedByName,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String? fromStatus;
  final String toStatus;
  final String changedByName;
  final String? notes;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, createdAt];
}
