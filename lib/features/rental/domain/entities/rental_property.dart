import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/domain/enums/rental_property_type.dart';
import 'package:equatable/equatable.dart';

class RentalProperty extends Equatable {
  const RentalProperty({
    required this.id,
    required this.companyId,
    this.condominiumId,
    this.condominiumName,
    this.condominiumCity,
    this.condominiumState,
    this.ownerPartyId,
    this.ownerName,
    required this.propertyType,
    required this.listingMode,
    this.code,
    required this.title,
    this.description,
    this.addressCity,
    this.addressState,
    this.addressNeighborhood,
    this.addressStreet,
    this.addressNumber,
    this.addressBuilding,
    this.addressBlock,
    this.addressApartment,
    this.addressZip,
    this.areaSqm,
    this.bedrooms,
    this.bathrooms,
    this.maxGuests,
    this.baseRentAmount,
    this.baseDailyRate,
    this.depositAmount,
    required this.status,
    this.registryMatricula,
    this.registryCartorio,
    this.iptuInscription,
    this.municipalInscription,
    this.isFurnished,
    this.acceptsPets,
  });

  final String id;
  final String companyId;
  final String? condominiumId;
  final String? condominiumName;
  final String? condominiumCity;
  final String? condominiumState;
  final String? ownerPartyId;
  final String? ownerName;
  final RentalPropertyType propertyType;
  final RentalListingMode listingMode;
  final String? code;
  final String title;
  final String? description;
  final String? addressCity;
  final String? addressState;
  final String? addressNeighborhood;
  final String? addressStreet;
  final String? addressNumber;
  final String? addressBuilding;
  final String? addressBlock;
  final String? addressApartment;
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

  String get locationLabel {
    final parts = [addressNeighborhood, effectiveAddressCity, effectiveAddressState]
        .where((p) => p != null && p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  /// Cidade para filtros e exibição (imóvel ou condomínio vinculado).
  String? get effectiveAddressCity {
    final city = addressCity?.trim();
    if (city != null && city.isNotEmpty) return city;
    final condoCity = condominiumCity?.trim();
    return (condoCity != null && condoCity.isNotEmpty) ? condoCity : null;
  }

  /// Estado para filtros e exibição (imóvel ou condomínio vinculado).
  String? get effectiveAddressState {
    final state = addressState?.trim();
    if (state != null && state.isNotEmpty) return state;
    final condoState = condominiumState?.trim();
    return (condoState != null && condoState.isNotEmpty) ? condoState : null;
  }

  @override
  List<Object?> get props => [id];
}

bool rentalPropertyMatchesFilter(RentalProperty property, RentalPropertyListFilter filter) {
  if (filter.propertyType != null && property.propertyType != filter.propertyType) {
    return false;
  }
  if (filter.listingMode != null && property.listingMode != filter.listingMode) {
    return false;
  }
  if (filter.search?.trim().isNotEmpty == true) {
    final q = filter.search!.trim().toLowerCase();
    if (!property.title.toLowerCase().contains(q) &&
        !(property.code?.toLowerCase().contains(q) ?? false)) {
      return false;
    }
  }
  if (filter.addressState != null) {
    final state = property.effectiveAddressState?.toLowerCase();
    if (state != filter.addressState!.trim().toLowerCase()) return false;
  }
  if (filter.addressCity != null) {
    final city = property.effectiveAddressCity?.toLowerCase();
    if (city != filter.addressCity!.trim().toLowerCase()) return false;
  }
  if (filter.condominiumId != null && property.condominiumId != filter.condominiumId) {
    return false;
  }
  return true;
}

class RentalPropertyListFilter extends Equatable {
  const RentalPropertyListFilter({
    this.propertyType,
    this.listingMode,
    this.search,
    this.addressState,
    this.addressCity,
    this.condominiumId,
  });

  final RentalPropertyType? propertyType;
  final RentalListingMode? listingMode;
  final String? search;
  final String? addressState;
  final String? addressCity;
  final String? condominiumId;

  RentalPropertyListFilter copyWith({
    RentalPropertyType? propertyType,
    RentalListingMode? listingMode,
    String? search,
    String? addressState,
    String? addressCity,
    String? condominiumId,
    bool clearType = false,
    bool clearMode = false,
    bool clearState = false,
    bool clearCity = false,
    bool clearCondominium = false,
  }) {
    return RentalPropertyListFilter(
      propertyType: clearType ? null : (propertyType ?? this.propertyType),
      listingMode: clearMode ? null : (listingMode ?? this.listingMode),
      search: search ?? this.search,
      addressState: clearState ? null : (addressState ?? this.addressState),
      addressCity: clearCity ? null : (addressCity ?? this.addressCity),
      condominiumId: clearCondominium ? null : (condominiumId ?? this.condominiumId),
    );
  }

  @override
  List<Object?> get props =>
      [propertyType, listingMode, search, addressState, addressCity, condominiumId];
}
