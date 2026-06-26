enum LocationType {
  unit('unit', 'Unidade'),
  apartment('apartment', 'Apartamento'),
  commonArea('common_area', 'Área comum'),
  block('block', 'Bloco'),
  tower('tower', 'Torre'),
  equipment('equipment', 'Equipamento'),
  other('other', 'Outro');

  const LocationType(this.value, this.label);
  final String value;
  final String label;

  /// Exige seleção de unidade cadastrada (unidade ou apartamento).
  bool get requiresUnit => this == LocationType.unit || this == LocationType.apartment;

  static LocationType fromValue(String value) {
    return LocationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LocationType.other,
    );
  }
}
