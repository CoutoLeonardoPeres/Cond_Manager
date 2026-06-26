import 'package:equatable/equatable.dart';

class RentalParty extends Equatable {
  const RentalParty({
    required this.id,
    required this.companyId,
    required this.fullName,
    this.email,
    this.phone,
    this.documentNumber,
    this.notes,
    required this.status,
  });

  final String id;
  final String companyId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? documentNumber;
  final String? notes;
  final String status;

  @override
  List<Object?> get props => [id];
}
