import 'package:cond_manager/shared/domain/enums/rental_inclusion_category.dart';
import 'package:equatable/equatable.dart';

class RentalInclusionCatalogItem extends Equatable {
  const RentalInclusionCatalogItem({
    required this.id,
    required this.companyId,
    required this.name,
    required this.category,
    this.defaultAmount,
    this.isActive = true,
  });

  final String id;
  final String companyId;
  final String name;
  final RentalInclusionCategory category;
  final double? defaultAmount;
  final bool isActive;

  @override
  List<Object?> get props => [id];
}

class RentalInclusionCatalogInput extends Equatable {
  const RentalInclusionCatalogInput({
    required this.companyId,
    required this.name,
    required this.category,
    this.defaultAmount,
  });

  final String companyId;
  final String name;
  final RentalInclusionCategory category;
  final double? defaultAmount;

  @override
  List<Object?> get props => [companyId, name, category];
}
