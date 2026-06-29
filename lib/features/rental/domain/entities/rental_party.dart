import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';
import 'package:equatable/equatable.dart';

class RentalParty extends Equatable {
  const RentalParty({
    required this.id,
    required this.companyId,
    required this.fullName,
    required this.category,
    this.email,
    this.phone,
    this.documentNumber,
    this.notes,
    required this.status,
    this.isRentalRestricted = false,
    this.restrictionReason,
    this.restrictedAt,
    this.addressStreet,
    this.addressNumber,
    this.addressComplement,
    this.addressNeighborhood,
    this.addressCity,
    this.addressState,
    this.addressZip,
    this.intakeMetadata,
    this.nationality,
    this.rgNumber,
    this.rgIssuer,
    this.profession,
    this.maritalStatus,
  });

  final String id;
  final String companyId;
  final String fullName;
  final RentalPartyCategory category;
  final String? email;
  final String? phone;
  final String? documentNumber;
  final String? notes;
  final String status;
  final bool isRentalRestricted;
  final String? restrictionReason;
  final DateTime? restrictedAt;
  final String? addressStreet;
  final String? addressNumber;
  final String? addressComplement;
  final String? addressNeighborhood;
  final String? addressCity;
  final String? addressState;
  final String? addressZip;
  final Map<String, dynamic>? intakeMetadata;
  final String? nationality;
  final String? rgNumber;
  final String? rgIssuer;
  final String? profession;
  final String? maritalStatus;

  @override
  List<Object?> get props => [id];
}
