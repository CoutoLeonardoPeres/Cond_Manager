import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:equatable/equatable.dart';

enum RentalExpenseAllocationMethod {
  equal('equal', 'Partes iguais'),
  byArea('by_area', 'Por metragem (m²)');

  const RentalExpenseAllocationMethod(this.value, this.label);
  final String value;
  final String label;
}

/// Escopo para carregar destinos de rateio (unidades do condomínio ou imóveis).
class RentalExpenseAllocationScope extends Equatable {
  const RentalExpenseAllocationScope({
    required this.condominiumId,
    this.blockId,
  });

  final String condominiumId;
  final String? blockId;

  @override
  List<Object?> get props => [condominiumId, blockId];
}

/// Destino de rateio: unidade estrutural do condomínio ou imóvel de locação.
class RentalExpenseAllocationTarget extends Equatable {
  const RentalExpenseAllocationTarget({
    required this.id,
    required this.label,
    this.areaSqm,
    this.unitId,
    this.rentalPropertyId,
  }) : assert(unitId != null || rentalPropertyId != null);

  factory RentalExpenseAllocationTarget.fromUnit(UnitOption unit) {
    return RentalExpenseAllocationTarget(
      id: unit.id,
      label: unit.label,
      areaSqm: unit.areaSqm,
      unitId: unit.id,
    );
  }

  factory RentalExpenseAllocationTarget.fromProperty(RentalProperty property) {
    return RentalExpenseAllocationTarget(
      id: property.id,
      label: property.title,
      areaSqm: property.areaSqm,
      rentalPropertyId: property.id,
    );
  }

  final String id;
  final String label;
  final double? areaSqm;
  final String? unitId;
  final String? rentalPropertyId;

  @override
  List<Object?> get props => [id];
}

/// Calcula valor por unidade; última unidade absorve centavos de arredondamento.
Map<String, double> computeUnitAllocationShares({
  required double totalAmount,
  required List<({String unitId, double weight})> units,
}) {
  if (units.isEmpty) return {};
  final totalWeight = units.fold<double>(0, (s, u) => s + u.weight);
  if (totalWeight <= 0) return {};

  final shares = <String, double>{};
  var allocated = 0.0;

  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    if (i == units.length - 1) {
      shares[u.unitId] = double.parse((totalAmount - allocated).toStringAsFixed(2));
    } else {
      final share = double.parse(((totalAmount * u.weight) / totalWeight).toStringAsFixed(2));
      shares[u.unitId] = share;
      allocated += share;
    }
  }

  return shares;
}
