import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inclusion_catalog_item.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_inclusion.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_photo.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_pnl.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_contract_enums.dart';

abstract class RentalRepository {
  Future<Result<List<RentalProperty>>> listProperties(RentalPropertyListFilter filter);

  Future<Result<RentalProperty>> getProperty(String id);

  Future<Result<RentalProperty>> createProperty(RentalPropertyInput input);

  Future<Result<RentalProperty>> updateProperty(String id, RentalPropertyInput input);

  Future<Result<void>> deleteProperty(String id);

  Future<Result<List<RentalPropertyInclusion>>> listPropertyInclusions(String propertyId);

  Future<Result<void>> replacePropertyInclusions(
    String propertyId,
    String companyId,
    List<RentalPropertyInclusionInput> items,
  );

  Future<Result<List<RentalInclusionCatalogItem>>> listInclusionCatalog(String companyId);

  Future<Result<RentalInclusionCatalogItem>> createInclusionCatalogItem(
    RentalInclusionCatalogInput input,
  );

  Future<Result<List<RentalPropertyPhoto>>> listPropertyPhotos(String propertyId);

  Future<Result<void>> uploadPropertyPhotos({
    required String propertyId,
    required String companyId,
    required List<PendingRentalPropertyPhoto> files,
    int sortOffset = 0,
  });

  Future<Result<void>> deletePropertyPhotos(List<String> photoIds);

  Future<Result<List<RentalParty>>> listParties();

  Future<Result<RentalParty>> getParty(String id);

  Future<Result<RentalParty>> createParty(RentalPartyInput input);

  Future<Result<RentalParty>> updateParty(String id, RentalPartyInput input);

  Future<Result<RentalParty?>> findPartyByDocumentOrPhone({
    required String companyId,
    String? documentNumber,
    String? phone,
    String? excludePartyId,
  });

  Future<Result<List<RentalLease>>> listLeases();

  Future<Result<RentalLease>> getLease(String id);

  Future<Result<RentalLease>> createLease(RentalLeaseInput input);

  Future<Result<RentalLease>> updateLease(String id, RentalLeaseInput input);

  Future<Result<RentalLease>> terminateLease(String id, TerminateLeaseInput input);

  Future<Result<List<RentalBooking>>> listBookings({
    DateTime? from,
    DateTime? to,
    String? propertyId,
  });

  Future<Result<RentalBooking>> getBooking(String id);

  Future<Result<RentalBooking>> createBooking(RentalBookingInput input);

  Future<Result<RentalBooking>> updateBooking(String id, RentalBookingInput input);

  /// Gera cobranças de aluguel pendentes para o mês quando a data de vencimento é atingida.
  Future<Result<int>> generateMonthlyCharges({DateTime? asOf});

  Future<Result<List<RentalCharge>>> listCharges(RentalChargeListFilter filter);

  Future<Result<RentalCharge>> getCharge(String id);

  Future<Result<RentalCharge>> createCharge(RentalChargeInput input);

  Future<Result<RentalCharge>> updateCharge(String id, RentalChargeInput input);

  Future<Result<RentalCharge>> markChargePaid(
    String chargeId, {
    required RentalPaymentMethod paymentMethod,
    required double paidAmount,
    required DateTime paidAt,
    bool syncFinancial = true,
  });

  Future<Result<String>> syncChargeToFinancial(String chargeId);

  Future<Result<List<RentalPropertyPnl>>> propertyPnlReport({
    DateTime? from,
    DateTime? to,
  });
}
