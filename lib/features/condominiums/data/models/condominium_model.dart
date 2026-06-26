import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';

class CondominiumModel {
  const CondominiumModel({
    required this.id,
    required this.name,
    this.legalName,
    this.cnpj,
    required this.city,
    required this.state,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.zipCode,
    this.syndicName,
    this.syndicPhone,
    this.syndicEmail,
    this.managerCompany,
    this.managerCnpj,
    this.managerContactName,
    this.managerPhone,
    this.managerEmail,
    this.managerStreet,
    this.managerNumber,
    this.managerComplement,
    this.managerNeighborhood,
    this.managerCity,
    this.managerState,
    this.managerZipCode,
    this.status = 'active',
    this.createdAt,
  });

  final String id;
  final String name;
  final String? legalName;
  final String? cnpj;
  final String city;
  final String state;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? zipCode;
  final String? syndicName;
  final String? syndicPhone;
  final String? syndicEmail;
  final String? managerCompany;
  final String? managerCnpj;
  final String? managerContactName;
  final String? managerPhone;
  final String? managerEmail;
  final String? managerStreet;
  final String? managerNumber;
  final String? managerComplement;
  final String? managerNeighborhood;
  final String? managerCity;
  final String? managerState;
  final String? managerZipCode;
  final String status;
  final DateTime? createdAt;

  factory CondominiumModel.fromJson(Map<String, dynamic> json) {
    return CondominiumModel(
      id: json['id'] as String,
      name: json['name'] as String,
      legalName: json['legal_name'] as String?,
      cnpj: json['cnpj'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      street: json['street'] as String?,
      number: json['number'] as String?,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String?,
      zipCode: json['zip_code'] as String?,
      syndicName: json['syndic_name'] as String?,
      syndicPhone: json['syndic_phone'] as String?,
      syndicEmail: json['syndic_email'] as String?,
      managerCompany: json['manager_company'] as String?,
      managerCnpj: json['manager_cnpj'] as String?,
      managerContactName: json['manager_contact_name'] as String?,
      managerPhone: json['manager_phone'] as String?,
      managerEmail: json['manager_email'] as String?,
      managerStreet: json['manager_street'] as String?,
      managerNumber: json['manager_number'] as String?,
      managerComplement: json['manager_complement'] as String?,
      managerNeighborhood: json['manager_neighborhood'] as String?,
      managerCity: json['manager_city'] as String?,
      managerState: json['manager_state'] as String?,
      managerZipCode: json['manager_zip_code'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson({String? createdBy, String? managementCompanyId}) {
    String? t(String? v) {
      final s = v?.trim();
      return s != null && s.isNotEmpty ? s : null;
    }

    return {
      'name': name,
      if (t(legalName) != null) 'legal_name': t(legalName),
      if (t(cnpj) != null) 'cnpj': t(cnpj),
      'city': city,
      'state': state,
      if (t(street) != null) 'street': t(street),
      if (t(number) != null) 'number': t(number),
      if (t(complement) != null) 'complement': t(complement),
      if (t(neighborhood) != null) 'neighborhood': t(neighborhood),
      if (t(zipCode) != null) 'zip_code': t(zipCode),
      if (t(syndicName) != null) 'syndic_name': t(syndicName),
      if (t(syndicPhone) != null) 'syndic_phone': t(syndicPhone),
      if (t(syndicEmail) != null) 'syndic_email': t(syndicEmail),
      if (t(managerCompany) != null) 'manager_company': t(managerCompany),
      if (t(managerCnpj) != null) 'manager_cnpj': t(managerCnpj),
      if (t(managerContactName) != null) 'manager_contact_name': t(managerContactName),
      if (t(managerPhone) != null) 'manager_phone': t(managerPhone),
      if (t(managerEmail) != null) 'manager_email': t(managerEmail),
      if (t(managerStreet) != null) 'manager_street': t(managerStreet),
      if (t(managerNumber) != null) 'manager_number': t(managerNumber),
      if (t(managerComplement) != null) 'manager_complement': t(managerComplement),
      if (t(managerNeighborhood) != null) 'manager_neighborhood': t(managerNeighborhood),
      if (t(managerCity) != null) 'manager_city': t(managerCity),
      if (t(managerState) != null) 'manager_state': t(managerState),
      if (t(managerZipCode) != null) 'manager_zip_code': t(managerZipCode),
      if (createdBy != null) 'created_by': createdBy,
      if (managementCompanyId != null) 'management_company_id': managementCompanyId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    String? t(String? v) {
      final s = v?.trim();
      return s != null && s.isNotEmpty ? s : null;
    }

    return {
      'name': name.trim(),
      'legal_name': t(legalName),
      'cnpj': t(cnpj),
      'city': city.trim(),
      'state': state.trim().toUpperCase(),
      'street': t(street),
      'number': t(number),
      'complement': t(complement),
      'neighborhood': t(neighborhood),
      'zip_code': t(zipCode),
      'syndic_name': t(syndicName),
      'syndic_phone': t(syndicPhone),
      'syndic_email': t(syndicEmail),
      'manager_company': t(managerCompany),
      'manager_cnpj': t(managerCnpj),
      'manager_contact_name': t(managerContactName),
      'manager_phone': t(managerPhone),
      'manager_email': t(managerEmail),
      'manager_street': t(managerStreet),
      'manager_number': t(managerNumber),
      'manager_complement': t(managerComplement),
      'manager_neighborhood': t(managerNeighborhood),
      'manager_city': t(managerCity),
      'manager_state': t(managerState),
      'manager_zip_code': t(managerZipCode),
    };
  }

  Condominium toEntity() => Condominium(
        id: id,
        name: name,
        legalName: legalName,
        cnpj: cnpj,
        city: city,
        state: state,
        street: street,
        number: number,
        complement: complement,
        neighborhood: neighborhood,
        zipCode: zipCode,
        syndicName: syndicName,
        syndicPhone: syndicPhone,
        syndicEmail: syndicEmail,
        managerCompany: managerCompany,
        managerCnpj: managerCnpj,
        managerContactName: managerContactName,
        managerPhone: managerPhone,
        managerEmail: managerEmail,
        managerStreet: managerStreet,
        managerNumber: managerNumber,
        managerComplement: managerComplement,
        managerNeighborhood: managerNeighborhood,
        managerCity: managerCity,
        managerState: managerState,
        managerZipCode: managerZipCode,
        status: status,
        createdAt: createdAt,
      );

  static CondominiumModel fromCreateInput(CondominiumCreateInput input) {
    return CondominiumModel(
      id: '',
      name: input.name.trim(),
      legalName: input.legalName,
      cnpj: input.cnpj,
      city: input.city.trim(),
      state: input.state.trim().toUpperCase(),
      street: input.street,
      number: input.number,
      complement: input.complement,
      neighborhood: input.neighborhood,
      zipCode: input.zipCode,
      syndicName: input.syndicName,
      syndicPhone: input.syndicPhone,
      syndicEmail: input.syndicEmail,
      managerCompany: input.managerCompany,
      managerCnpj: input.managerCnpj,
      managerContactName: input.managerContactName,
      managerPhone: input.managerPhone,
      managerEmail: input.managerEmail,
      managerStreet: input.managerStreet,
      managerNumber: input.managerNumber,
      managerComplement: input.managerComplement,
      managerNeighborhood: input.managerNeighborhood,
      managerCity: input.managerCity,
      managerState: input.managerState,
      managerZipCode: input.managerZipCode,
    );
  }
}
