import 'package:cond_manager/features/materials/domain/entities/material_supplier.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';

class MaterialSupplierModel {
  static List<MaterialSupplierLink> parseLinks(dynamic raw) {
    if (raw is! List) return const [];
    final links = <MaterialSupplierLink>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final prov = item['supplier'] ?? item['providers'];
      if (prov is! Map<String, dynamic>) continue;
      final id = prov['id'] as String?;
      if (id == null) continue;
      final trade = prov['trade_name'] as String?;
      final legal = prov['legal_name'] as String? ?? '';
      final label = trade?.trim().isNotEmpty == true ? trade! : legal;
      links.add(
        MaterialSupplierLink(
          providerId: id,
          displayName: label,
          isPrimary: item['is_primary'] as bool? ?? false,
          lastPurchaseAt: item['last_purchase_at'] != null
              ? DateTime.parse(item['last_purchase_at'] as String)
              : null,
          lastUnitCost: _toDoubleOrNull(item['last_unit_cost']),
          lastPurchaseQuantity: _toDoubleOrNull(item['last_purchase_quantity']),
          lastResaleUnitPrice: _toDoubleOrNull(item['last_resale_unit_price']),
        ),
      );
    }
    links.sort((a, b) {
      if (a.isPrimary == b.isPrimary) return a.displayName.compareTo(b.displayName);
      return a.isPrimary ? -1 : 1;
    });
    return links;
  }

  static MaterialSupplierListItem listItemFromProviderJson(Map<String, dynamic> json) {
    final trade = json['trade_name'] as String?;
    final legal = json['legal_name'] as String? ?? '';
    final display = trade?.trim().isNotEmpty == true ? trade! : legal;

    final names = <String>[];
    final links = json['material_supplier_links'];
    if (links is List) {
      for (final link in links) {
        if (link is! Map<String, dynamic>) continue;
        final mat = link['materials'];
        if (mat is Map<String, dynamic>) {
          final name = mat['name'] as String?;
          if (name != null) names.add(name);
        }
      }
    }

    return MaterialSupplierListItem(
      id: json['id'] as String,
      condominiumId: json['condominium_id'] as String,
      displayName: display,
      documentNumber: json['document_number'] as String,
      specialties: _parseSpecialties(json['specialties']),
      status: EntityStatus.fromValue(json['status'] as String),
      materialCount: names.length,
      materialNames: names,
    );
  }

  static MaterialSupplierDetail detailFromJson(Map<String, dynamic> json) {
    final condo = json['condominiums'];
    String? condoName;
    if (condo is Map<String, dynamic>) condoName = condo['name'] as String?;

    final materialIds = <String>[];
    final links = json['material_supplier_links'];
    if (links is List) {
      for (final link in links) {
        if (link is Map<String, dynamic>) {
          final mid = link['material_id'] as String?;
          if (mid != null) materialIds.add(mid);
        }
      }
    }

    return MaterialSupplierDetail(
      id: json['id'] as String,
      condominiumId: json['condominium_id'] as String,
      condominiumName: condoName,
      documentType: json['document_type'] as String,
      documentNumber: json['document_number'] as String,
      legalName: json['legal_name'] as String,
      tradeName: json['trade_name'] as String?,
      specialties: _parseSpecialties(json['specialties']),
      phones: _parseStringList(json['phones']),
      emails: _parseStringList(json['emails']),
      street: json['street'] as String?,
      number: json['number'] as String?,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zip_code'] as String?,
      status: EntityStatus.fromValue(json['status'] as String),
      notes: json['notes'] as String?,
      materialIds: materialIds,
    );
  }

  static Map<String, dynamic> createProviderPayload(MaterialSupplierSaveInput input) {
    return {
      'condominium_id': input.condominiumId,
      'provider_type': 'supplier',
      'document_type': input.documentType,
      'document_number': input.documentNumber.trim(),
      'legal_name': input.legalName.trim(),
      'trade_name': _trimOrNull(input.tradeName),
      'specialties': input.specialties.map((e) => e.value).toList(),
      'phones': input.phones.where((p) => p.trim().isNotEmpty).toList(),
      'emails': input.emails.where((e) => e.trim().isNotEmpty).toList(),
      'street': _trimOrNull(input.street),
      'number': _trimOrNull(input.number),
      'complement': _trimOrNull(input.complement),
      'neighborhood': _trimOrNull(input.neighborhood),
      'city': _trimOrNull(input.city),
      'state': _trimOrNull(input.state),
      'zip_code': _trimOrNull(input.zipCode),
      'status': input.status.value,
      'notes': _trimOrNull(input.notes),
    };
  }

  static Map<String, dynamic> updateProviderPayload(MaterialSupplierSaveInput input) {
    return {
      'document_type': input.documentType,
      'document_number': input.documentNumber.trim(),
      'legal_name': input.legalName.trim(),
      'trade_name': _trimOrNull(input.tradeName),
      'specialties': input.specialties.map((e) => e.value).toList(),
      'phones': input.phones.where((p) => p.trim().isNotEmpty).toList(),
      'emails': input.emails.where((e) => e.trim().isNotEmpty).toList(),
      'street': _trimOrNull(input.street),
      'number': _trimOrNull(input.number),
      'complement': _trimOrNull(input.complement),
      'neighborhood': _trimOrNull(input.neighborhood),
      'city': _trimOrNull(input.city),
      'state': _trimOrNull(input.state),
      'zip_code': _trimOrNull(input.zipCode),
      'status': input.status.value,
      'notes': _trimOrNull(input.notes),
    };
  }

  static const supplierSelect = '''
    *,
    condominiums ( name ),
    material_supplier_links (
      material_id,
      materials ( name )
    )
  ''';

  static const supplierDetailSelect = '''
    *,
    condominiums ( name ),
    material_supplier_links ( material_id )
  ''';

  static List<ServiceType> _parseSpecialties(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => ServiceType.fromValue(e.toString())).toList();
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  static String? _trimOrNull(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
