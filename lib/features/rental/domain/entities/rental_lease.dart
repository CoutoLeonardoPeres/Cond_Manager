import 'package:cond_manager/shared/domain/enums/rental_lease_contract_enums.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:equatable/equatable.dart';

/// Termos contratuais complementares (garantia, reajuste, pagamento, testemunhas…).
class RentalLeaseContractTerms extends Equatable {
  const RentalLeaseContractTerms({
    this.guaranteeType,
    this.guaranteeOtherDescription,
    this.adjustmentIndex,
    this.adjustmentPeriodMonths,
    this.paymentMethod,
    this.pixKey,
    this.bankName,
    this.bankAgency,
    this.bankAccount,
    this.bankAccountType,
    this.bankHolder,
    this.bankHolderDocument,
    this.lateFeePercent,
    this.interestPercent,
    this.terminationPenaltyMonths,
    this.inspectionObjectionDays,
    this.keyDeliveryMethod,
    this.maxOccupants,
    this.allowsPets,
    this.petsDescription,
    this.cancellationPolicy,
    this.seasonTotalAmount,
    this.tenantCharges,
    this.landlordCharges,
    this.witness1Name,
    this.witness1Cpf,
    this.witness2Name,
    this.witness2Cpf,
  });

  final RentalGuaranteeType? guaranteeType;
  final String? guaranteeOtherDescription;
  final RentalAdjustmentIndex? adjustmentIndex;
  final int? adjustmentPeriodMonths;
  final RentalPaymentMethod? paymentMethod;
  final String? pixKey;
  final String? bankName;
  final String? bankAgency;
  final String? bankAccount;
  final String? bankAccountType;
  final String? bankHolder;
  final String? bankHolderDocument;
  final double? lateFeePercent;
  final double? interestPercent;
  final int? terminationPenaltyMonths;
  final int? inspectionObjectionDays;
  final String? keyDeliveryMethod;
  final int? maxOccupants;
  final bool? allowsPets;
  final String? petsDescription;
  final RentalCancellationPolicy? cancellationPolicy;
  final double? seasonTotalAmount;
  final String? tenantCharges;
  final String? landlordCharges;
  final String? witness1Name;
  final String? witness1Cpf;
  final String? witness2Name;
  final String? witness2Cpf;

  static const empty = RentalLeaseContractTerms();

  @override
  List<Object?> get props => [guaranteeType, adjustmentIndex, paymentMethod];
}

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
    this.terminationReason,
    this.contractTerms = RentalLeaseContractTerms.empty,
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
  final String? terminationReason;
  final RentalLeaseContractTerms contractTerms;

  @override
  List<Object?> get props => [id];
}
