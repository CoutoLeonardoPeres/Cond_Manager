import 'package:cond_manager/features/materials/domain/entities/material_supplier.dart';

class MaterialSupplierPurchaseModel {
  MaterialSupplierPurchaseModel({
    required this.id,
    required this.materialId,
    required this.providerId,
    required this.providerName,
    required this.condominiumId,
    required this.purchasedAt,
    required this.quantity,
    required this.unitCost,
    required this.purchaseTaxPercent,
    required this.totalCost,
    required this.resaleUnitPrice,
    required this.resaleTaxPercent,
    this.stockMovementId,
    this.invoiceNumber,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String materialId;
  final String providerId;
  final String providerName;
  final String condominiumId;
  final DateTime purchasedAt;
  final double quantity;
  final double unitCost;
  final double purchaseTaxPercent;
  final double totalCost;
  final double resaleUnitPrice;
  final double resaleTaxPercent;
  final String? stockMovementId;
  final String? invoiceNumber;
  final String? notes;
  final DateTime createdAt;

  static const selectQuery = '''
    *,
    supplier:providers!material_supplier_purchases_provider_id_fkey (
      id, trade_name, legal_name
    )
  ''';

  factory MaterialSupplierPurchaseModel.fromJson(Map<String, dynamic> json) {
    String providerName = '—';
    final supplier = json['supplier'];
    if (supplier is Map<String, dynamic>) {
      final trade = supplier['trade_name'] as String?;
      final legal = supplier['legal_name'] as String? ?? '';
      providerName = trade?.trim().isNotEmpty == true ? trade! : legal;
    }

    return MaterialSupplierPurchaseModel(
      id: json['id'] as String,
      materialId: json['material_id'] as String,
      providerId: json['provider_id'] as String,
      providerName: providerName,
      condominiumId: json['condominium_id'] as String,
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      quantity: _toDouble(json['quantity']),
      unitCost: _toDouble(json['unit_cost']),
      purchaseTaxPercent: _toDouble(json['purchase_tax_percent']),
      totalCost: _toDouble(json['total_cost']),
      resaleUnitPrice: _toDouble(json['resale_unit_price']),
      resaleTaxPercent: _toDouble(json['resale_tax_percent']),
      stockMovementId: json['stock_movement_id'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  MaterialSupplierPurchase toEntity() => MaterialSupplierPurchase(
        id: id,
        materialId: materialId,
        providerId: providerId,
        providerName: providerName,
        condominiumId: condominiumId,
        purchasedAt: purchasedAt,
        quantity: quantity,
        unitCost: unitCost,
        purchaseTaxPercent: purchaseTaxPercent,
        totalCost: totalCost,
        resaleUnitPrice: resaleUnitPrice,
        resaleTaxPercent: resaleTaxPercent,
        stockMovementId: stockMovementId,
        invoiceNumber: invoiceNumber,
        notes: notes,
        createdAt: createdAt,
      );

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
