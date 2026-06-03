enum MaterialItemType {
  material('material', 'Material'),
  equipment('equipment', 'Equipamento');

  const MaterialItemType(this.value, this.label);
  final String value;
  final String label;

  static MaterialItemType fromValue(String value) {
    return MaterialItemType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MaterialItemType.material,
    );
  }
}
