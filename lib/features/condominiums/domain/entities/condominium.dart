import 'package:equatable/equatable.dart';

class Condominium extends Equatable {
  const Condominium({
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

  String get displayAddress => formattedAddress(
        street: street,
        number: number,
        complement: complement,
        neighborhood: neighborhood,
        city: city,
        state: state,
        zipCode: zipCode,
      );

  static String formattedAddress({
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    required String city,
    required String state,
    String? zipCode,
  }) {
    final parts = <String>[
      if (street != null && street!.trim().isNotEmpty) street!.trim(),
      if (number != null && number!.trim().isNotEmpty) number!.trim(),
      if (complement != null && complement!.trim().isNotEmpty) complement!.trim(),
      if (neighborhood != null && neighborhood!.trim().isNotEmpty) neighborhood!.trim(),
    ];
    final location = '$city/$state';
    if (parts.isEmpty) return zipCode?.trim().isNotEmpty == true ? '$location · CEP ${zipCode!.trim()}' : location;
    final line = parts.join(', ');
    if (zipCode != null && zipCode.trim().isNotEmpty) return '$line — $location · CEP ${zipCode.trim()}';
    return '$line — $location';
  }

  @override
  List<Object?> get props => [id, name, city, state, status];
}

class CondominiumCreateInput {
  const CondominiumCreateInput({
    required this.name,
    required this.city,
    required this.state,
    this.legalName,
    this.cnpj,
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
  });

  final String name;
  final String city;
  final String state;
  final String? legalName;
  final String? cnpj;
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
}
