import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:equatable/equatable.dart';

enum RentalExpenseLocationKind { condominium, property, block }

/// Destino da despesa: condomínio, imóvel de locação ou bloco/torre.
class RentalExpenseLocation extends Equatable {
  const RentalExpenseLocation.condominium()
      : kind = RentalExpenseLocationKind.condominium,
        referenceId = null,
        label = 'Condomínio';

  const RentalExpenseLocation.property({
    required String id,
    required String title,
  })  : kind = RentalExpenseLocationKind.property,
        referenceId = id,
        label = title;

  const RentalExpenseLocation.block({
    required String id,
    required String name,
  })  : kind = RentalExpenseLocationKind.block,
        referenceId = id,
        label = name;

  factory RentalExpenseLocation.fromRecord(FinancialRecord record) {
    if (record.rentalPropertyId != null) {
      return RentalExpenseLocation.property(
        id: record.rentalPropertyId!,
        title: record.rentalPropertyTitle ?? record.rentalPropertyId!,
      );
    }
    if (record.blockId != null) {
      return RentalExpenseLocation.block(
        id: record.blockId!,
        name: record.blockName ?? record.blockId!,
      );
    }
    return const RentalExpenseLocation.condominium();
  }

  final RentalExpenseLocationKind kind;
  final String? referenceId;
  final String label;

  String? get rentalPropertyId =>
      kind == RentalExpenseLocationKind.property ? referenceId : null;

  String? get blockId =>
      kind == RentalExpenseLocationKind.block ? referenceId : null;

  String get dropdownLabel => switch (kind) {
        RentalExpenseLocationKind.condominium => 'Condomínio',
        RentalExpenseLocationKind.property => 'Imóvel · $label',
        RentalExpenseLocationKind.block => 'Bloco/Torre · $label',
      };

  @override
  List<Object?> get props => [kind, referenceId];
}
