import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:equatable/equatable.dart';

class MaterialSupplierLink extends Equatable {
  const MaterialSupplierLink({
    required this.providerId,
    required this.displayName,
    this.isPrimary = false,
  });

  final String providerId;
  final String displayName;
  final bool isPrimary;

  @override
  List<Object?> get props => [providerId, isPrimary];
}

class MaterialSupplierListItem extends Equatable {
  const MaterialSupplierListItem({
    required this.id,
    required this.condominiumId,
    required this.displayName,
    required this.documentNumber,
    required this.specialties,
    required this.status,
    required this.materialCount,
    required this.materialNames,
  });

  final String id;
  final String condominiumId;
  final String displayName;
  final String documentNumber;
  final List<ServiceType> specialties;
  final EntityStatus status;
  final int materialCount;
  final List<String> materialNames;

  String get specialtiesLabel =>
      specialties.isEmpty ? '—' : specialties.map((s) => s.label).join(', ');

  String get materialsPreview {
    if (materialNames.isEmpty) return 'Nenhum material vinculado';
    if (materialNames.length <= 2) return materialNames.join(', ');
    return '${materialNames.take(2).join(', ')} +${materialNames.length - 2}';
  }

  @override
  List<Object?> get props => [id];
}

class MaterialSupplierDetail extends Equatable {
  const MaterialSupplierDetail({
    required this.id,
    required this.condominiumId,
    this.condominiumName,
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
    required this.materialIds,
  });

  final String id;
  final String condominiumId;
  final String? condominiumName;
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
  final List<String> materialIds;

  String get displayName =>
      tradeName?.trim().isNotEmpty == true ? tradeName!.trim() : legalName;

  @override
  List<Object?> get props => [id];
}

class MaterialSupplierListFilter extends Equatable {
  const MaterialSupplierListFilter({
    this.condominiumId,
    this.serviceType,
    this.status,
  });

  final String? condominiumId;
  final ServiceType? serviceType;
  final EntityStatus? status;

  MaterialSupplierListFilter copyWith({
    String? condominiumId,
    ServiceType? serviceType,
    EntityStatus? status,
    bool clearCondominium = false,
    bool clearServiceType = false,
    bool clearStatus = false,
  }) {
    return MaterialSupplierListFilter(
      condominiumId: clearCondominium ? null : (condominiumId ?? this.condominiumId),
      serviceType: clearServiceType ? null : (serviceType ?? this.serviceType),
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  List<Object?> get props => [condominiumId, serviceType, status];
}

class MaterialSupplierSaveInput extends Equatable {
  const MaterialSupplierSaveInput({
    required this.condominiumId,
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
    required this.materialIds,
  });

  final String condominiumId;
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
  final List<String> materialIds;

  @override
  List<Object?> get props => [condominiumId, documentNumber];
}
