import 'package:cond_manager/shared/domain/enums/labor_source.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:equatable/equatable.dart';

class WorkOrderLaborLine extends Equatable {
  const WorkOrderLaborLine({
    required this.id,
    required this.workOrderId,
    required this.laborSource,
    required this.serviceType,
    required this.workerName,
    required this.workerCount,
    required this.hours,
    required this.hourlyRate,
    required this.travelCost,
    required this.laborSubtotal,
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
  final LaborSource laborSource;
  final ServiceType serviceType;
  final String workerName;
  final int workerCount;
  final double hours;
  final double hourlyRate;
  final double travelCost;
  final double laborSubtotal;
  final double totalCost;
  final String? providerId;
  final String? providerName;
  final String? profileId;
  final String? profileName;
  final String? notes;
  final DateTime createdAt;

  double get totalManHours => workerCount * hours;

  String get sourceLabel => laborSource.label;

  String get summary =>
      '${serviceType.label} · $workerCount prof. · ${totalManHours.toStringAsFixed(1)} h-HH';

  @override
  List<Object?> get props => [id];
}

class WorkOrderLaborTotals extends Equatable {
  const WorkOrderLaborTotals({
    required this.lines,
    required this.totalManHours,
    required this.totalLaborSubtotal,
    required this.totalTravel,
    required this.grandTotal,
    required this.thirdPartyTotal,
    required this.internalTotal,
  });

  final List<WorkOrderLaborLine> lines;
  final double totalManHours;
  final double totalLaborSubtotal;
  final double totalTravel;
  final double grandTotal;
  final double thirdPartyTotal;
  final double internalTotal;

  @override
  List<Object?> get props => [grandTotal, lines.length];
}

class AddWorkOrderLaborInput extends Equatable {
  const AddWorkOrderLaborInput({
    required this.workOrderId,
    required this.condominiumId,
    required this.laborSource,
    required this.serviceType,
    required this.workerName,
    required this.workerCount,
    required this.hours,
    required this.hourlyRate,
    this.travelCost = 0,
    this.providerId,
    this.profileId,
    this.notes,
  });

  final String workOrderId;
  final String condominiumId;
  final LaborSource laborSource;
  final ServiceType serviceType;
  final String workerName;
  final int workerCount;
  final double hours;
  final double hourlyRate;
  final double travelCost;
  final String? providerId;
  final String? profileId;
  final String? notes;

  @override
  List<Object?> get props => [workOrderId, serviceType, workerName];
}
