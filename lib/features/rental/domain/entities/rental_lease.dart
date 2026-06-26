import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:equatable/equatable.dart';

class RentalLease extends Equatable {
  const RentalLease({
    required this.id,
    required this.companyId,
    required this.propertyId,
    required this.propertyTitle,
    this.unitId,
    this.tenantName,
    this.leaseNumber,
    required this.listingMode,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.monthlyRent,
    this.depositAmount,
    this.dueDayOfMonth,
    this.notes,
    this.primaryTenantPartyId,
  });

  final String id;
  final String companyId;
  final String propertyId;
  final String propertyTitle;
  final String? unitId;
  final String? tenantName;
  final String? leaseNumber;
  final RentalListingMode listingMode;
  final RentalLeaseStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final double monthlyRent;
  final double? depositAmount;
  final int? dueDayOfMonth;
  final String? notes;
  final String? primaryTenantPartyId;

  @override
  List<Object?> get props => [id];
}
