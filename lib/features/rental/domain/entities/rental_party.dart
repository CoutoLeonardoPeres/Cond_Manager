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

  @override
  List<Object?> get props => [id];
}
