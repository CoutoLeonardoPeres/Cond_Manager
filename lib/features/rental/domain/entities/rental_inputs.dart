import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/shared/domain/enums/rental_booking_channel.dart';
import 'package:cond_manager/shared/domain/enums/rental_booking_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_type.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_contract_enums.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';
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
    this.paidPaymentMethod,
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
  final RentalPaymentMethod? paidPaymentMethod;
  final String? notes;

  bool get isPaid => status == RentalChargeStatus.paid;

  bool get isOverdue {
    if (isPaid ||
        status == RentalChargeStatus.cancelled ||
        status == RentalChargeStatus.refunded) {
      return false;
    }
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  String get displayStatusLabel {
    if (isPaid) return RentalChargeStatus.paid.label;
    if (isOverdue) return RentalChargeStatus.overdue.label;
    return status.label;
  }

  bool get canConfirmPayment =>
      !isPaid &&
      status != RentalChargeStatus.cancelled &&
      status != RentalChargeStatus.refunded;

  /// Coluna do quadro de cobranças (null = cancelada/reembolsada).
  RentalChargeBoardColumn? get boardColumn {
    if (isPaid) return RentalChargeBoardColumn.paid;
    if (isOverdue) return RentalChargeBoardColumn.overdue;
    if (canConfirmPayment) return RentalChargeBoardColumn.newCharges;
    return null;
  }

  @override
  List<Object?> get props => [id];
}

/// Colunas do quadro na tela de cobranças.
enum RentalChargeBoardColumn {
  newCharges('Novas'),
  overdue('Atrasadas'),
  paid('Pagas');

  const RentalChargeBoardColumn(this.label);
  final String label;
}

/// Dados confirmados no modal de pagamento da cobrança.
class RentalChargePaymentConfirmation {
  const RentalChargePaymentConfirmation({
    required this.paymentMethod,
    required this.paidAmount,
    required this.paidAt,
  });

  final RentalPaymentMethod paymentMethod;
  final double paidAmount;
  final DateTime paidAt;
}

class RentalChargeListFilter extends Equatable {
  const RentalChargeListFilter({
    this.status,
    this.chargeType,
    this.bookingId,
    this.quickFilter = RentalChargeQuickFilter.all,
    this.month,
  });

  final RentalChargeStatus? status;
  final RentalChargeType? chargeType;
  final String? bookingId;
  final RentalChargeQuickFilter quickFilter;
  final DateTime? month;

  RentalChargeListFilter copyWith({
    RentalChargeStatus? status,
    RentalChargeType? chargeType,
    String? bookingId,
    RentalChargeQuickFilter? quickFilter,
    DateTime? month,
    bool clearStatus = false,
    bool clearType = false,
    bool clearBookingId = false,
    bool clearMonth = false,
  }) {
    return RentalChargeListFilter(
      status: clearStatus ? null : (status ?? this.status),
      chargeType: clearType ? null : (chargeType ?? this.chargeType),
      bookingId: clearBookingId ? null : (bookingId ?? this.bookingId),
      quickFilter: quickFilter ?? this.quickFilter,
      month: clearMonth ? null : (month ?? this.month),
    );
  }

  @override
  List<Object?> get props => [status, chargeType, bookingId, quickFilter, month];
}

/// Filtro rápido de cobranças na listagem.
enum RentalChargeQuickFilter {
  all('Todas'),
  overdue('Atrasadas'),
  newCharges('Novas'),
  paid('Pagas');

  const RentalChargeQuickFilter(this.label);
  final String label;
}

bool rentalChargeMatchesFilter(RentalCharge charge, RentalChargeListFilter filter) {
  if (filter.chargeType != null && charge.chargeType != filter.chargeType) {
    return false;
  }
  if (filter.bookingId != null && charge.bookingId != filter.bookingId) {
    return false;
  }
  if (filter.month != null) {
    final due = charge.dueDate;
    if (due == null) return false;
    if (due.year != filter.month!.year || due.month != filter.month!.month) {
      return false;
    }
  }
  switch (filter.quickFilter) {
    case RentalChargeQuickFilter.all:
      break;
    case RentalChargeQuickFilter.overdue:
      if (!charge.isOverdue) return false;
    case RentalChargeQuickFilter.newCharges:
      if (!charge.canConfirmPayment || charge.isOverdue) return false;
    case RentalChargeQuickFilter.paid:
      if (!charge.isPaid) return false;
  }
  return true;
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
    this.addressBuilding,
    this.addressBlock,
    this.addressApartment,
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
    this.registryMatricula,
    this.registryCartorio,
    this.iptuInscription,
    this.municipalInscription,
    this.isFurnished,
    this.acceptsPets,
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
  final String? addressBuilding;
  final String? addressBlock;
  final String? addressApartment;
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
  final String? registryMatricula;
  final String? registryCartorio;
  final String? iptuInscription;
  final String? municipalInscription;
  final bool? isFurnished;
  final bool? acceptsPets;

  @override
  List<Object?> get props => [title, companyId];
}

class RentalPartyInput extends Equatable {
  const RentalPartyInput({
    required this.companyId,
    required this.fullName,
    required this.category,
    this.email,
    this.phone,
    this.documentNumber,
    this.notes,
    this.status = 'active',
    this.isRentalRestricted,
    this.restrictionReason,
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

  final String companyId;
  final String fullName;
  final RentalPartyCategory category;
  final String? email;
  final String? phone;
  final String? documentNumber;
  final String? notes;
  final String status;
  final bool? isRentalRestricted;
  final String? restrictionReason;
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
  List<Object?> get props => [fullName, companyId, category];
}

class TerminateLeaseInput extends Equatable {
  const TerminateLeaseInput({
    required this.endDate,
    this.terminationReason,
    this.applyTenantRestriction = false,
    this.restrictionReason,
  });

  final DateTime endDate;
  final String? terminationReason;
  final bool applyTenantRestriction;
  final String? restrictionReason;

  @override
  List<Object?> get props => [endDate, applyTenantRestriction];
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
    this.contractTerms = RentalLeaseContractTerms.empty,
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
  final RentalLeaseContractTerms contractTerms;

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
    this.isFixedRent = false,
    this.monthlyRent,
    this.paymentDueDay,
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
  final bool isFixedRent;
  final double? monthlyRent;
  final int? paymentDueDay;
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
