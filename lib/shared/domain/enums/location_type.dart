enum LocationType {
  unit('unit', 'Unidade'),
  commonArea('common_area', 'Área comum'),
  block('block', 'Bloco'),
  tower('tower', 'Torre'),
  equipment('equipment', 'Equipamento'),
  other('other', 'Outro');

  const LocationType(this.value, this.label);
  final String value;
  final String label;

  static LocationType fromValue(String value) {
    return LocationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LocationType.other,
    );
  }
}
