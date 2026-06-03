import 'package:cond_manager/features/work_orders/domain/entities/work_order_material.dart';

class WorkOrderMaterialModel {
  WorkOrderMaterialModel({
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

  factory WorkOrderMaterialModel.fromJson(Map<String, dynamic> json) {
    return WorkOrderMaterialModel(
      id: json['id'] as String,
      workOrderId: json['work_order_id'] as String,
      materialId: json['material_id'] as String?,
      materialName: json['material_name'] as String,
      quantity: parseNum(json['quantity']),
      unitOfMeasure: json['unit_of_measure'] as String? ?? 'un',
      unitCost: parseNum(json['unit_cost']),
      purchaseTaxPercent: parseNum(json['purchase_tax_percent']),
      totalCost: parseNum(json['total_cost']),
      totalCostWithTax: parseNum(json['total_cost_with_tax']),
      unitResalePrice: parseNum(json['unit_resale_price']),
      resaleTaxPercent: parseNum(json['resale_tax_percent']),
      totalResale: parseNum(json['total_resale']),
      totalResaleWithTax: parseNum(json['total_resale_with_tax']),
      stockMovementId: json['stock_movement_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static double parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  WorkOrderMaterialLine toEntity() => WorkOrderMaterialLine(
        id: id,
        workOrderId: workOrderId,
        materialId: materialId,
        materialName: materialName,
        quantity: quantity,
        unitOfMeasure: unitOfMeasure,
        unitCost: unitCost,
        purchaseTaxPercent: purchaseTaxPercent,
        totalCost: totalCost,
        totalCostWithTax: totalCostWithTax,
        unitResalePrice: unitResalePrice,
        resaleTaxPercent: resaleTaxPercent,
        totalResale: totalResale,
        totalResaleWithTax: totalResaleWithTax,
        stockMovementId: stockMovementId,
        createdAt: createdAt,
      );

  static Map<String, dynamic> insertPayload({
    required String workOrderId,
    required String materialId,
    required String materialName,
    required double quantity,
    required String unitOfMeasure,
    required double unitCost,
    required double purchaseTaxPercent,
    required double totalCost,
    required double totalCostWithTax,
    required double unitResalePrice,
    required double resaleTaxPercent,
    required double totalResale,
    required double totalResaleWithTax,
    String? stockMovementId,
  }) {
    return {
      'work_order_id': workOrderId,
      'material_id': materialId,
      'material_name': materialName,
      'quantity': quantity,
      'unit_of_measure': unitOfMeasure,
      'unit_cost': unitCost,
      'purchase_tax_percent': purchaseTaxPercent,
      'total_cost': totalCost,
      'total_cost_with_tax': totalCostWithTax,
      'unit_resale_price': unitResalePrice,
      'resale_tax_percent': resaleTaxPercent,
      'total_resale': totalResale,
      'total_resale_with_tax': totalResaleWithTax,
      'stock_movement_id': stockMovementId,
    };
  }
}
