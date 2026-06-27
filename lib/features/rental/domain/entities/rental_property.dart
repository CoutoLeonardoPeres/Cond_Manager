import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/domain/enums/rental_property_type.dart';
import 'package:equatable/equatable.dart';

class RentalProperty extends Equatable {
  const RentalProperty({
    required this.id,
    required this.companyId,
    this.condominiumId,
    this.condominiumName,
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
  });

  final String id;
  final String companyId;
  final String? condominiumId;
  final String? condominiumName;
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

  String get locationLabel {
    final parts = [addressNeighborhood, addressCity, addressState]
        .where((p) => p != null && p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  @override
  List<Object?> get props => [id];
}

class RentalPropertyListFilter extends Equatable {
  const RentalPropertyListFilter({
    this.propertyType,
    this.listingMode,
    this.search,
  });

  final RentalPropertyType? propertyType;
  final RentalListingMode? listingMode;
  final String? search;

  RentalPropertyListFilter copyWith({
    RentalPropertyType? propertyType,
    RentalListingMode? listingMode,
    String? search,
    bool clearType = false,
    bool clearMode = false,
  }) {
    return RentalPropertyListFilter(
      propertyType: clearType ? null : (propertyType ?? this.propertyType),
      listingMode: clearMode ? null : (listingMode ?? this.listingMode),
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [propertyType, listingMode, search];
}
