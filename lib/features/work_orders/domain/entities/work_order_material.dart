import 'package:equatable/equatable.dart';

class WorkOrderMaterialLine extends Equatable {
  const WorkOrderMaterialLine({
    required this.id,
    required this.workOrderId,
    this.materialId,
    required this.materialName,
    required this.quantity,
    required this.unitOfMeasure,
    required this.unitCost,
    required this.purchaseTaxPercent,
    required this.totalCost,
    required this.totalCostWithTax,
    required this.unitResalePrice,
    required this.resaleTaxPercent,
    required this.totalResale,
    required this.totalResaleWithTax,
    this.stockMovementId,
    required this.createdAt,
  });

  final String id;
  final String workOrderId;
  final String? materialId;
  final String materialName;
  final double quantity;
  final String unitOfMeasure;
  final double unitCost;
  final double purchaseTaxPercent;
  final double totalCost;
  final double totalCostWithTax;
  final double unitResalePrice;
  final double resaleTaxPercent;
  final double totalResale;
  final double totalResaleWithTax;
  final String? stockMovementId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id];
}

class WorkOrderMaterialsTotals extends Equatable {
  const WorkOrderMaterialsTotals({
    required this.lines,
    required this.totalCost,
    required this.totalCostWithTax,
    required this.totalResale,
    required this.totalResaleWithTax,
    required this.marginWithTax,
  });

  final List<WorkOrderMaterialLine> lines;
  final double totalCost;
  final double totalCostWithTax;
  final double totalResale;
  final double totalResaleWithTax;
  final double marginWithTax;

  @override
  List<Object?> get props => [totalCostWithTax, totalResaleWithTax];
}

class AddWorkOrderMaterialInput extends Equatable {
  const AddWorkOrderMaterialInput({
    required this.workOrderId,
    required this.condominiumId,
    required this.materialId,
    required this.quantity,
  });

  final String workOrderId;
  final String condominiumId;
  final String materialId;
  final double quantity;

  @override
  List<Object?> get props => [workOrderId, materialId];
}
