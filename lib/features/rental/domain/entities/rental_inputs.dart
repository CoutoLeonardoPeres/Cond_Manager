import 'package:cond_manager/shared/domain/enums/rental_booking_channel.dart';
import 'package:cond_manager/shared/domain/enums/rental_booking_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_type.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/domain/enums/rental_property_type.dart';
import 'package:equatable/equatable.dart';

class RentalCharge extends Equatable {
  const RentalCharge({
    required this.id,
    required this.companyId,
    this.leaseId,
    this.bookingId,
    this.partyId,
    this.partyName,
    this.propertyTitle,
    required this.chargeType,
    required this.status,
    required this.description,
    required this.amount,
    this.dueDate,
    this.paidAt,
    this.financialRecordId,
    this.notes,
  });

  final String id;
  final String companyId;
  final String? leaseId;
  final String? bookingId;
  final String? partyId;
  final String? partyName;
  final String? propertyTitle;
  final RentalChargeType chargeType;
  final RentalChargeStatus status;
  final String description;
  final double amount;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? financialRecordId;
  final String? notes;

  bool get isPaid => status == RentalChargeStatus.paid;

  @override
  List<Object?> get props => [id];
}

class RentalChargeListFilter extends Equatable {
  const RentalChargeListFilter({this.status, this.chargeType});

  final RentalChargeStatus? status;
  final RentalChargeType? chargeType;

  RentalChargeListFilter copyWith({
    RentalChargeStatus? status,
    RentalChargeType? chargeType,
    bool clearStatus = false,
    bool clearType = false,
  }) {
    return RentalChargeListFilter(
      status: clearStatus ? null : (status ?? this.status),
      chargeType: clearType ? null : (chargeType ?? this.chargeType),
    );
  }

  @override
  List<Object?> get props => [status, chargeType];
}

class RentalPropertyInput extends Equatable {
  const RentalPropertyInput({
    required this.companyId,
    required this.title,
    required this.propertyType,
    required this.listingMode,
    this.code,
    this.description,
    this.condominiumId,
    this.ownerPartyId,
    this.addressStreet,
    this.addressNumber,
    this.addressNeighborhood,
    this.addressCity,
    this.addressState,
    this.addressZip,
    this.areaSqm,
    this.bedrooms,
    this.bathrooms,
    this.maxGuests,
    this.baseRentAmount,
    this.baseDailyRate,
    this.depositAmount,
    this.status = 'active',
  });

  final String companyId;
  final String title;
  final RentalPropertyType propertyType;
  final RentalListingMode listingMode;
  final String? code;
  final String? description;
  final String? condominiumId;
  final String? ownerPartyId;
  final String? addressStreet;
  final String? addressNumber;
  final String? addressNeighborhood;
  final String? addressCity;
  final String? addressState;
  final String? addressZip;
  final double? areaSqm;
  final int? bedrooms;
  final int? bathrooms;
  final int? maxGuests;
  final double? baseRentAmount;
  final double? baseDailyRate;
  final double? depositAmount;
  final String status;

  @override
  List<Object?> get props => [title, companyId];
}

class RentalPartyInput extends Equatable {
  const RentalPartyInput({
    required this.companyId,
    required this.fullName,
    this.email,
    this.phone,
    this.documentNumber,
    this.notes,
    this.status = 'active',
  });

  final String companyId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? documentNumber;
  final String? notes;
  final String status;

  @override
  List<Object?> get props => [fullName, companyId];
}

class RentalLeaseInput extends Equatable {
  const RentalLeaseInput({
    required this.companyId,
    required this.propertyId,
    required this.startDate,
    required this.monthlyRent,
    required this.listingMode,
    required this.status,
    this.unitId,
    this.primaryTenantPartyId,
    this.leaseNumber,
    this.endDate,
    this.depositAmount,
    this.dueDayOfMonth,
    this.notes,
  });

  final String companyId;
  final String propertyId;
  final String? unitId;
  final String? primaryTenantPartyId;
  final String? leaseNumber;
  final RentalListingMode listingMode;
  final RentalLeaseStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final double monthlyRent;
  final double? depositAmount;
  final int? dueDayOfMonth;
  final String? notes;

  @override
  List<Object?> get props => [propertyId, startDate];
}

class RentalBookingInput extends Equatable {
  const RentalBookingInput({
    required this.companyId,
    required this.propertyId,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.channel,
    required this.status,
    this.unitId,
    this.guestPartyId,
    this.guestEmail,
    this.guestPhone,
    this.guestsCount = 1,
    this.nightlyRate,
    this.totalAmount,
    this.notes,
  });

  final String companyId;
  final String propertyId;
  final String? unitId;
  final String? guestPartyId;
  final String guestName;
  final String? guestEmail;
  final String? guestPhone;
  final int guestsCount;
  final RentalBookingChannel channel;
  final RentalBookingStatus status;
  final DateTime checkIn;
  final DateTime checkOut;
  final double? nightlyRate;
  final double? totalAmount;
  final String? notes;

  @override
  List<Object?> get props => [propertyId, checkIn, checkOut];
}

class RentalChargeInput extends Equatable {
  const RentalChargeInput({
    required this.companyId,
    required this.description,
    required this.amount,
    required this.chargeType,
    required this.status,
    this.leaseId,
    this.bookingId,
    this.partyId,
    this.dueDate,
    this.notes,
  });

  final String companyId;
  final String? leaseId;
  final String? bookingId;
  final String? partyId;
  final RentalChargeType chargeType;
  final RentalChargeStatus status;
  final String description;
  final double amount;
  final DateTime? dueDate;
  final String? notes;

  @override
  List<Object?> get props => [description, amount];
}

class CompanyModuleRow extends Equatable {
  const CompanyModuleRow({
    required this.companyId,
    required this.companyName,
    required this.maintenanceEnabled,
    required this.rentalEnabled,
  });

  final String companyId;
  final String companyName;
  final bool maintenanceEnabled;
  final bool rentalEnabled;

  @override
  List<Object?> get props => [companyId];
}
