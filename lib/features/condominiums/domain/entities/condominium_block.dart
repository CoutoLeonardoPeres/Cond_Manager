import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:equatable/equatable.dart';

class CondominiumBlock extends Equatable {
  const CondominiumBlock({
    required this.id,
    required this.condominiumId,
    required this.name,
    required this.sortOrder,
    required this.status,
  });

  final String id;
  final String condominiumId;
  final String name;
  final int sortOrder;
  final EntityStatus status;

  @override
  List<Object?> get props => [id, condominiumId, name, sortOrder, status];
}

class CondominiumBlockInput {
  const CondominiumBlockInput({
    required this.name,
    this.sortOrder = 0,
  });

  final String name;
  final int sortOrder;
}
