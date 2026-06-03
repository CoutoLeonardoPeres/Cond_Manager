import 'package:cond_manager/features/providers/domain/entities/service_provider.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/provider_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';

class ServiceProviderModel {
  ServiceProviderModel({
    required this.id,
    required this.condominiumId,
    this.condominiumName,
    required this.providerType,
    required this.documentType,
    required this.documentNumber,
    required this.legalName,
    this.tradeName,
    required this.specialties,
    required this.phones,
    required this.emails,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.zipCode,
    this.rating,
    required this.ratingCount,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String condominiumId;
  final String? condominiumName;
  final String providerType;
  final String documentType;
  final String documentNumber;
  final String legalName;
  final String? tradeName;
  final List<String> specialties;
  final List<String> phones;
  final List<String> emails;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? rating;
  final int ratingCount;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const selectWithCondo = '''
    *,
    condominiums ( name )
  ''';

  factory ServiceProviderModel.fromJson(Map<String, dynamic> json) {
    final condo = json['condominiums'];
    String? condoName;
    if (condo is Map<String, dynamic>) {
      condoName = condo['name'] as String?;
    }

    return ServiceProviderModel(
      id: json['id'] as String,
      condominiumId: json['condominium_id'] as String,
      condominiumName: condoName,
      providerType: json['provider_type'] as String,
      documentType: json['document_type'] as String,
      documentNumber: json['document_number'] as String,
      legalName: json['legal_name'] as String,
      tradeName: json['trade_name'] as String?,
      specialties: parseSpecialties(json['specialties']),
      phones: _parseStringList(json['phones']),
      emails: _parseStringList(json['emails']),
      street: json['street'] as String?,
      number: json['number'] as String?,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zip_code'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int? ?? 0,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  static List<String> parseSpecialties(dynamic raw) {
    return _parseStringList(raw);
  }

  ServiceProvider toEntity() {
    return ServiceProvider(
      id: id,
      condominiumId: condominiumId,
      condominiumName: condominiumName,
      providerType: ProviderType.fromValue(providerType),
      documentType: documentType,
      documentNumber: documentNumber,
      legalName: legalName,
      tradeName: tradeName,
      specialties: specialties.map(ServiceType.fromValue).toList(),
      phones: phones,
      emails: emails,
      street: street,
      number: number,
      complement: complement,
      neighborhood: neighborhood,
      city: city,
      state: state,
      zipCode: zipCode,
      rating: rating,
      ratingCount: ratingCount,
      status: EntityStatus.fromValue(status),
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> createPayload(ServiceProviderCreateInput input) {
    return {
      'condominium_id': input.condominiumId,
      'provider_type': input.providerType.value,
      'document_type': input.documentType,
      'document_number': input.documentNumber.trim(),
      'legal_name': input.legalName.trim(),
      'trade_name': _nullableTrim(input.tradeName),
      'specialties': input.specialties.map((e) => e.value).toList(),
      'phones': input.phones.map((p) => p.trim()).where((p) => p.isNotEmpty).toList(),
      'emails': input.emails.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'street': _nullableTrim(input.street),
      'number': _nullableTrim(input.number),
      'complement': _nullableTrim(input.complement),
      'neighborhood': _nullableTrim(input.neighborhood),
      'city': _nullableTrim(input.city),
      'state': _nullableTrim(input.state),
      'zip_code': _nullableTrim(input.zipCode),
      'status': input.status.value,
      'notes': _nullableTrim(input.notes),
    };
  }

  static Map<String, dynamic> updatePayload(ServiceProviderUpdateInput input) {
    return {
      'provider_type': input.providerType.value,
      'document_type': input.documentType,
      'document_number': input.documentNumber.trim(),
      'legal_name': input.legalName.trim(),
      'trade_name': _nullableTrim(input.tradeName),
      'specialties': input.specialties.map((e) => e.value).toList(),
      'phones': input.phones.map((p) => p.trim()).where((p) => p.isNotEmpty).toList(),
      'emails': input.emails.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'street': _nullableTrim(input.street),
      'number': _nullableTrim(input.number),
      'complement': _nullableTrim(input.complement),
      'neighborhood': _nullableTrim(input.neighborhood),
      'city': _nullableTrim(input.city),
      'state': _nullableTrim(input.state),
      'zip_code': _nullableTrim(input.zipCode),
      'status': input.status.value,
      'notes': _nullableTrim(input.notes),
    };
  }

  static String? _nullableTrim(String? value) {
    final t = value?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
