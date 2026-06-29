enum RentalExpenseAllocationMethod {
  equal('equal', 'Partes iguais'),
  byArea('by_area', 'Por metragem (m²)');

  const RentalExpenseAllocationMethod(this.value, this.label);
  final String value;
  final String label;
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
