import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/provider_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:equatable/equatable.dart';

class ServiceProvider extends Equatable {
  const ServiceProvider({
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
    this.ratingCount = 0,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String condominiumId;
  final String? condominiumName;
  final ProviderType providerType;
  final String documentType;
  final String documentNumber;
  final String legalName;
  final String? tradeName;
  final List<ServiceType> specialties;
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
  final EntityStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName =>
      tradeName?.trim().isNotEmpty == true ? tradeName!.trim() : legalName;

  String get specialtiesLabel =>
      specialties.map((s) => s.label).join(', ');

  @override
  List<Object?> get props => [id];
}

class ServiceProviderListFilter extends Equatable {
  const ServiceProviderListFilter({
    this.condominiumId,
    this.serviceType,
    this.status,
  });

  final String? condominiumId;
  final ServiceType? serviceType;
  final EntityStatus? status;

  ServiceProviderListFilter copyWith({
    String? condominiumId,
    ServiceType? serviceType,
    EntityStatus? status,
    bool clearCondominium = false,
    bool clearServiceType = false,
    bool clearStatus = false,
  }) {
    return ServiceProviderListFilter(
      condominiumId: clearCondominium ? null : (condominiumId ?? this.condominiumId),
      serviceType: clearServiceType ? null : (serviceType ?? this.serviceType),
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  List<Object?> get props => [condominiumId, serviceType, status];
}

class ServiceProviderCreateInput extends Equatable {
  const ServiceProviderCreateInput({
    required this.condominiumId,
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
    this.status = EntityStatus.active,
    this.notes,
  });

  final String condominiumId;
  final ProviderType providerType;
  final String documentType;
  final String documentNumber;
  final String legalName;
  final String? tradeName;
  final List<ServiceType> specialties;
  final List<String> phones;
  final List<String> emails;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? zipCode;
  final EntityStatus status;
  final String? notes;

  @override
  List<Object?> get props => [condominiumId, documentNumber];
}

class ServiceProviderUpdateInput extends Equatable {
  const ServiceProviderUpdateInput({
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
    required this.status,
    this.notes,
  });

  final ProviderType providerType;
  final String documentType;
  final String documentNumber;
  final String legalName;
  final String? tradeName;
  final List<ServiceType> specialties;
  final List<String> phones;
  final List<String> emails;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? zipCode;
  final EntityStatus status;
  final String? notes;

  @override
  List<Object?> get props => [documentNumber];
}

/// Opção resumida para dropdowns (ex.: ordem de serviço).
class ProviderPickerOption extends Equatable {
  const ProviderPickerOption({
    required this.id,
    required this.label,
    required this.providerType,
    required this.specialties,
  });

  final String id;
  final String label;
  final String providerType;
  final List<ServiceType> specialties;

  @override
  List<Object?> get props => [id];
}

class ProviderPickerQuery extends Equatable {
  const ProviderPickerQuery({
    required this.condominiumId,
    this.serviceType,
  });

  final String condominiumId;
  final ServiceType? serviceType;

  @override
  List<Object?> get props => [condominiumId, serviceType];
}
