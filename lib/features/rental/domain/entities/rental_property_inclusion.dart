import 'package:cond_manager/shared/domain/enums/rental_inclusion_category.dart';
import 'package:equatable/equatable.dart';

class RentalPropertyInclusion extends Equatable {
  const RentalPropertyInclusion({
    required this.id,
    required this.companyId,
    required this.propertyId,
    required this.category,
    this.catalogItemId,
    this.customName,
    this.amount,
    required this.includedInRent,
    this.quantity,
    this.sizeLabel,
    this.model,
    this.chairCount,
    this.notes,
    this.sortOrder = 0,
  });

  final String id;
  final String companyId;
  final String propertyId;
  final RentalInclusionCategory category;
  final String? catalogItemId;
  final String? customName;
  final double? amount;
  final bool includedInRent;
  final int? quantity;
  final String? sizeLabel;
  final String? model;
  final int? chairCount;
  final String? notes;
  final int sortOrder;

  String get displayName {
    if (customName != null && customName!.trim().isNotEmpty) {
      return customName!.trim();
    }
    return category.label;
  }

  bool get isUtilityCategory => category.isUtility;

  @override
  List<Object?> get props => [id];
}

class RentalPropertyInclusionInput extends Equatable {
  const RentalPropertyInclusionInput({
    this.id,
    required this.category,
    this.catalogItemId,
    this.customName,
    this.amount,
    this.includedInRent = false,
    this.quantity,
    this.sizeLabel,
    this.model,
    this.chairCount,
    this.notes,
    this.sortOrder = 0,
  });

  final String? id;
  final RentalInclusionCategory category;
  final String? catalogItemId;
  final String? customName;
  final double? amount;
  final bool includedInRent;
  final int? quantity;
  final String? sizeLabel;
  final String? model;
  final int? chairCount;
  final String? notes;
  final int sortOrder;

  factory RentalPropertyInclusionInput.fromEntity(RentalPropertyInclusion e) =>
      RentalPropertyInclusionInput(
        id: e.id,
        category: e.category,
        catalogItemId: e.catalogItemId,
        customName: e.customName,
        amount: e.amount,
        includedInRent: e.includedInRent,
        quantity: e.quantity,
        sizeLabel: e.sizeLabel,
        model: e.model,
        chairCount: e.chairCount,
        notes: e.notes,
        sortOrder: e.sortOrder,
      );

  RentalPropertyInclusionInput copyWith({
    String? id,
    RentalInclusionCategory? category,
    String? catalogItemId,
    String? customName,
    double? amount,
    bool? includedInRent,
    int? quantity,
    String? sizeLabel,
    String? model,
    int? chairCount,
    String? notes,
    int? sortOrder,
    bool clearCatalogItemId = false,
    bool clearCustomName = false,
    bool clearAmount = false,
    bool clearQuantity = false,
    bool clearSizeLabel = false,
    bool clearModel = false,
    bool clearChairCount = false,
    bool clearNotes = false,
  }) {
    return RentalPropertyInclusionInput(
      id: id ?? this.id,
      category: category ?? this.category,
      catalogItemId: clearCatalogItemId ? null : (catalogItemId ?? this.catalogItemId),
      customName: clearCustomName ? null : (customName ?? this.customName),
      amount: clearAmount ? null : (amount ?? this.amount),
      includedInRent: includedInRent ?? this.includedInRent,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      sizeLabel: clearSizeLabel ? null : (sizeLabel ?? this.sizeLabel),
      model: clearModel ? null : (model ?? this.model),
      chairCount: clearChairCount ? null : (chairCount ?? this.chairCount),
      notes: clearNotes ? null : (notes ?? this.notes),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [category, sortOrder];

  String get displayName {
    if (customName != null && customName!.trim().isNotEmpty) {
      return customName!.trim();
    }
    return category.label;
  }

  bool get isFromCatalog => catalogItemId != null;

  bool get isUtilityCategory => category.isUtility;

  bool get descriptionEditable => !isUtilityCategory;
}
