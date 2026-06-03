import 'package:cond_manager/features/materials/data/models/material_supplier_model.dart';
import 'package:cond_manager/features/materials/domain/entities/material.dart';
import 'package:cond_manager/features/materials/domain/entities/material_supplier.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/material_item_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/domain/enums/stock_movement_type.dart';

class MaterialModel {
  MaterialModel({
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
  final String itemType;
  final bool isStorable;
  final String unitOfMeasure;
  final double unitCost;
  final double purchaseTaxPercent;
  final double resaleUnitPrice;
  final double resaleTaxPercent;
  final List<String> applicableServices;
  final double minStock;
  final double currentStock;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const materialSelect = '''
    *,
    condominiums ( name ),
    material_categories ( name ),
    primary_provider:providers!materials_provider_id_fkey ( trade_name, legal_name ),
    material_supplier_links (
      is_primary,
      supplier:providers!material_supplier_links_provider_id_fkey ( id, trade_name, legal_name )
    )
  ''';

  static const movementSelect = '''
    *,
    performer:profiles!stock_movements_performed_by_fkey ( full_name )
  ''';

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    String? condoName;
    final condo = json['condominiums'];
    if (condo is Map<String, dynamic>) condoName = condo['name'] as String?;

    String? catName;
    final cat = json['material_categories'];
    if (cat is Map<String, dynamic>) catName = cat['name'] as String?;

    String? providerName;
    final prov = json['primary_provider'] ?? json['providers'];
    if (prov is Map<String, dynamic>) {
      final trade = prov['trade_name'] as String?;
      providerName = trade?.trim().isNotEmpty == true
          ? trade
          : prov['legal_name'] as String?;
    }

    return MaterialModel(
      id: json['id'] as String,
      condominiumId: json['condominium_id'] as String,
      condominiumName: condoName,
      categoryId: json['category_id'] as String?,
      categoryName: catName,
      providerId: json['provider_id'] as String?,
      providerName: providerName,
      supplierLinks: MaterialSupplierModel.parseLinks(json['material_supplier_links']),
      name: json['name'] as String,
      sku: json['sku'] as String?,
      itemType: json['item_type'] as String? ?? 'material',
      isStorable: json['is_storable'] as bool? ?? true,
      unitOfMeasure: json['unit_of_measure'] as String? ?? 'un',
      unitCost: _toDouble(json['unit_cost']),
      purchaseTaxPercent: _toDouble(json['purchase_tax_percent']),
      resaleUnitPrice: _toDouble(json['resale_unit_price']),
      resaleTaxPercent: _toDouble(json['resale_tax_percent']),
      applicableServices: _parseServices(json['applicable_services']),
      minStock: _toDouble(json['min_stock']),
      currentStock: _toDouble(json['current_stock']),
      description: json['description'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static List<String> _parseServices(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  Material toEntity() {
    return Material(
      id: id,
      condominiumId: condominiumId,
      condominiumName: condominiumName,
      categoryId: categoryId,
      categoryName: categoryName,
      providerId: providerId,
      providerName: providerName,
      supplierLinks: supplierLinks,
      name: name,
      sku: sku,
      itemType: MaterialItemType.fromValue(itemType),
      isStorable: isStorable,
      unitOfMeasure: unitOfMeasure,
      unitCost: unitCost,
      purchaseTaxPercent: purchaseTaxPercent,
      resaleUnitPrice: resaleUnitPrice,
      resaleTaxPercent: resaleTaxPercent,
      applicableServices:
          applicableServices.map(ServiceType.fromValue).toList(),
      minStock: minStock,
      currentStock: currentStock,
      description: description,
      status: EntityStatus.fromValue(status),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> createPayload(MaterialCreateInput input) {
    return {
      'condominium_id': input.condominiumId,
      'category_id': input.categoryId,
      'provider_id': input.providerId,
      'name': input.name.trim(),
      'sku': _nullableTrim(input.sku),
      'item_type': input.itemType.value,
      'is_storable': input.isStorable,
      'unit_of_measure': input.unitOfMeasure.trim(),
      'unit_cost': input.unitCost,
      'purchase_tax_percent': input.purchaseTaxPercent,
      'resale_unit_price': input.resaleUnitPrice,
      'resale_tax_percent': input.resaleTaxPercent,
      'applicable_services': input.applicableServices.map((e) => e.value).toList(),
      'min_stock': input.isStorable ? input.minStock : 0,
      'current_stock': 0,
      'description': _nullableTrim(input.description),
      'status': input.status.value,
    };
  }

  static Map<String, dynamic> updatePayload(MaterialUpdateInput input) {
    return {
      'category_id': input.categoryId,
      'provider_id': input.providerId,
      'name': input.name.trim(),
      'sku': _nullableTrim(input.sku),
      'item_type': input.itemType.value,
      'is_storable': input.isStorable,
      'unit_of_measure': input.unitOfMeasure.trim(),
      'unit_cost': input.unitCost,
      'purchase_tax_percent': input.purchaseTaxPercent,
      'resale_unit_price': input.resaleUnitPrice,
      'resale_tax_percent': input.resaleTaxPercent,
      'applicable_services': input.applicableServices.map((e) => e.value).toList(),
      'min_stock': input.isStorable ? input.minStock : 0,
      'description': _nullableTrim(input.description),
      'status': input.status.value,
    };
  }

  static String? _nullableTrim(String? value) {
    final t = value?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}

class MaterialCategoryModel {
  MaterialCategoryModel({
    required this.id,
    required this.condominiumId,
    required this.name,
    this.description,
  });

  final String id;
  final String condominiumId;
  final String name;
  final String? description;

  factory MaterialCategoryModel.fromJson(Map<String, dynamic> json) {
    return MaterialCategoryModel(
      id: json['id'] as String,
      condominiumId: json['condominium_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  MaterialCategory toEntity() => MaterialCategory(
        id: id,
        condominiumId: condominiumId,
        name: name,
        description: description,
      );
}

class StockMovementModel {
  StockMovementModel({
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
  final String movementType;
  final double quantity;
  final double? unitCost;
  final double? totalCost;
  final String? referenceType;
  final String? referenceId;
  final String? notes;
  final String? performedByName;
  final DateTime createdAt;

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    String? performerName;
    final performer = json['performer'];
    if (performer is Map<String, dynamic>) {
      performerName = performer['full_name'] as String?;
    }

    return StockMovementModel(
      id: json['id'] as String,
      materialId: json['material_id'] as String,
      condominiumId: json['condominium_id'] as String,
      movementType: json['movement_type'] as String,
      quantity: MaterialModel._toDouble(json['quantity']),
      unitCost: json['unit_cost'] != null
          ? MaterialModel._toDouble(json['unit_cost'])
          : null,
      totalCost: json['total_cost'] != null
          ? MaterialModel._toDouble(json['total_cost'])
          : null,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      notes: json['notes'] as String?,
      performedByName: performerName,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  StockMovement toEntity() => StockMovement(
        id: id,
        materialId: materialId,
        condominiumId: condominiumId,
        movementType: StockMovementType.fromValue(movementType),
        quantity: quantity,
        unitCost: unitCost,
        totalCost: totalCost,
        referenceType: referenceType,
        referenceId: referenceId,
        notes: notes,
        performedByName: performedByName,
        createdAt: createdAt,
      );
}
