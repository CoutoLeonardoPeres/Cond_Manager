import 'package:cond_manager/features/materials/domain/entities/material_supplier.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/material_item_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/domain/enums/stock_movement_type.dart';
import 'package:cond_manager/shared/utils/material_pricing.dart';
import 'package:equatable/equatable.dart';

class Material extends Equatable {
  const Material({
    required this.id,
    required this.condominiumId,
    this.condominiumName,
    this.categoryId,
    this.categoryName,
    this.providerId,
    this.providerName,
    this.supplierLinks = const [],
    required this.name,
    this.sku,
    required this.itemType,
    required this.isStorable,
    required this.unitOfMeasure,
    required this.unitCost,
    required this.purchaseTaxPercent,
    required this.resaleUnitPrice,
    required this.resaleTaxPercent,
    required this.applicableServices,
    required this.minStock,
    required this.currentStock,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String condominiumId;
  final String? condominiumName;
  final String? categoryId;
  final String? categoryName;
  final String? providerId;
  final String? providerName;
  final List<MaterialSupplierLink> supplierLinks;
  final String name;
  final String? sku;
  final MaterialItemType itemType;
  final bool isStorable;
  final String unitOfMeasure;
  final double unitCost;
  final double purchaseTaxPercent;
  final double resaleUnitPrice;
  final double resaleTaxPercent;
  final List<ServiceType> applicableServices;
  final double minStock;
  final double currentStock;
  final String? description;
  final EntityStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get unitCostWithTax =>
      MaterialPricing.withTax(unitCost, purchaseTaxPercent);

  double get resaleUnitPriceWithTax =>
      MaterialPricing.withTax(resaleUnitPrice, resaleTaxPercent);

  double get stockValueAtCost => currentStock * unitCostWithTax;

  double get stockValueAtResale => currentStock * resaleUnitPriceWithTax;

  double? get unitMarginPercent => MaterialPricing.marginPercent(
        resaleUnitPriceWithTax,
        unitCostWithTax,
      );

  bool get isLowStock =>
      isStorable && status == EntityStatus.active && currentStock <= minStock;

  String get applicableServicesLabel =>
      applicableServices.isEmpty
          ? 'Todos os serviços'
          : applicableServices.map((s) => s.label).join(', ');

  String? get suppliersLabel {
    if (supplierLinks.isNotEmpty) {
      return supplierLinks.map((l) => l.displayName).join(', ');
    }
    return providerName;
  }

  @override
  List<Object?> get props => [id];
}

class MaterialCategory extends Equatable {
  const MaterialCategory({
    required this.id,
    required this.condominiumId,
    required this.name,
    this.description,
  });

  final String id;
  final String condominiumId;
  final String name;
  final String? description;

  @override
  List<Object?> get props => [id];
}

class StockMovement extends Equatable {
  const StockMovement({
    required this.id,
    required this.materialId,
    required this.condominiumId,
    required this.movementType,
    required this.quantity,
    this.unitCost,
    this.totalCost,
    this.referenceType,
    this.referenceId,
    this.notes,
    this.performedByName,
    required this.createdAt,
  });

  final String id;
  final String materialId;
  final String condominiumId;
  final StockMovementType movementType;
  final double quantity;
  final double? unitCost;
  final double? totalCost;
  final String? referenceType;
  final String? referenceId;
  final String? notes;
  final String? performedByName;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id];
}

class MaterialListFilter extends Equatable {
  const MaterialListFilter({
    this.condominiumId,
    this.categoryId,
    this.serviceType,
    this.itemType,
    this.lowStockOnly = false,
    this.status,
  });

  final String? condominiumId;
  final String? categoryId;
  final ServiceType? serviceType;
  final MaterialItemType? itemType;
  final bool lowStockOnly;
  final EntityStatus? status;

  MaterialListFilter copyWith({
    String? condominiumId,
    String? categoryId,
    ServiceType? serviceType,
    MaterialItemType? itemType,
    bool? lowStockOnly,
    EntityStatus? status,
    bool clearCondominium = false,
    bool clearCategory = false,
    bool clearServiceType = false,
    bool clearItemType = false,
    bool clearStatus = false,
  }) {
    return MaterialListFilter(
      condominiumId: clearCondominium ? null : (condominiumId ?? this.condominiumId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      serviceType: clearServiceType ? null : (serviceType ?? this.serviceType),
      itemType: clearItemType ? null : (itemType ?? this.itemType),
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  List<Object?> get props => [condominiumId, categoryId, serviceType, itemType, lowStockOnly, status];
}

class MaterialBalanceSummary extends Equatable {
  const MaterialBalanceSummary({
    required this.itemCount,
    required this.lowStockCount,
    required this.totalStockCost,
    required this.totalStockResale,
    required this.estimatedMargin,
  });

  final int itemCount;
  final int lowStockCount;
  final double totalStockCost;
  final double totalStockResale;
  final double estimatedMargin;

  @override
  List<Object?> get props => [itemCount, totalStockCost];
}

class MaterialCreateInput extends Equatable {
  const MaterialCreateInput({
    required this.condominiumId,
    this.categoryId,
    this.providerId,
    required this.name,
    this.sku,
    required this.itemType,
    required this.isStorable,
    required this.unitOfMeasure,
    required this.unitCost,
    required this.purchaseTaxPercent,
    required this.resaleUnitPrice,
    required this.resaleTaxPercent,
    required this.applicableServices,
    required this.minStock,
    this.description,
    this.status = EntityStatus.active,
  });

  final String condominiumId;
  final String? categoryId;
  final String? providerId;
  final String name;
  final String? sku;
  final MaterialItemType itemType;
  final bool isStorable;
  final String unitOfMeasure;
  final double unitCost;
  final double purchaseTaxPercent;
  final double resaleUnitPrice;
  final double resaleTaxPercent;
  final List<ServiceType> applicableServices;
  final double minStock;
  final String? description;
  final EntityStatus status;

  @override
  List<Object?> get props => [condominiumId, name];
}

class MaterialUpdateInput extends Equatable {
  const MaterialUpdateInput({
    this.categoryId,
    this.providerId,
    required this.name,
    this.sku,
    required this.itemType,
    required this.isStorable,
    required this.unitOfMeasure,
    required this.unitCost,
    required this.purchaseTaxPercent,
    required this.resaleUnitPrice,
    required this.resaleTaxPercent,
    required this.applicableServices,
    required this.minStock,
    this.description,
    required this.status,
  });

  final String? categoryId;
  final String? providerId;
  final String name;
  final String? sku;
  final MaterialItemType itemType;
  final bool isStorable;
  final String unitOfMeasure;
  final double unitCost;
  final double purchaseTaxPercent;
  final double resaleUnitPrice;
  final double resaleTaxPercent;
  final List<ServiceType> applicableServices;
  final double minStock;
  final String? description;
  final EntityStatus status;

  @override
  List<Object?> get props => [name];
}

class StockMovementInput extends Equatable {
  const StockMovementInput({
    required this.materialId,
    required this.condominiumId,
    required this.movementType,
    required this.quantity,
    this.unitCost,
    this.notes,
    this.referenceType,
    this.referenceId,
  });

  final String materialId;
  final String condominiumId;
  final StockMovementType movementType;
  final double quantity;
  final double? unitCost;
  final String? notes;
  final String? referenceType;
  final String? referenceId;

  @override
  List<Object?> get props => [materialId, movementType];
}

class ProviderPickerForMaterial extends Equatable {
  const ProviderPickerForMaterial({required this.id, required this.label});

  final String id;
  final String label;

  @override
  List<Object?> get props => [id];
}
