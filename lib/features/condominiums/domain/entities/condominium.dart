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

class CondominiumListFilter extends Equatable {
  const CondominiumListFilter({
    this.search = '',
    this.state,
    this.city,
  });

  final String search;
  final String? state;
  final String? city;

  CondominiumListFilter copyWith({
    String? search,
    String? state,
    String? city,
    bool clearState = false,
    bool clearCity = false,
  }) {
    return CondominiumListFilter(
      search: search ?? this.search,
      state: clearState ? null : (state ?? this.state),
      city: clearCity ? null : (city ?? this.city),
    );
  }

  bool get hasActiveFilters =>
      search.trim().isNotEmpty || state != null || city != null;

  @override
  List<Object?> get props => [search, state, city];
}

bool condominiumMatchesListFilter(Condominium condominium, CondominiumListFilter filter) {
  final query = filter.search.trim().toLowerCase();
  if (query.isNotEmpty) {
    final nameMatch = condominium.name.toLowerCase().contains(query);
    final legalMatch = condominium.legalName?.toLowerCase().contains(query) ?? false;
    if (!nameMatch && !legalMatch) return false;
  }
  if (filter.state != null &&
      condominium.state.trim().toLowerCase() != filter.state!.trim().toLowerCase()) {
    return false;
  }
  if (filter.city != null &&
      condominium.city.trim().toLowerCase() != filter.city!.trim().toLowerCase()) {
    return false;
  }
  return true;
}

List<Condominium> filterCondominiums(List<Condominium> condominiums, CondominiumListFilter filter) {
  return condominiums.where((c) => condominiumMatchesListFilter(c, filter)).toList();
}
