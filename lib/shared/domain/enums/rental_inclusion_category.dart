enum RentalInclusionCategory {
  condominiumFee('condominium_fee', 'Condomínio'),
  water('water', 'Água'),
  electricity('electricity', 'Luz / energia'),
  internet('internet', 'Internet'),
  gas('gas', 'Gás'),
  television('television', 'Televisor'),
  appliance('appliance', 'Eletrodoméstico'),
  furniture('furniture', 'Mobiliário'),
  other('other', 'Outro');

  const RentalInclusionCategory(this.value, this.label);

  final String value;
  final String label;

  static RentalInclusionCategory fromValue(String value) {
    return RentalInclusionCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => RentalInclusionCategory.other,
    );
  }

  bool get isUtility =>
      this == condominiumFee ||
      this == water ||
      this == electricity ||
      this == internet ||
      this == gas;

  bool get showsTvFields => this == television;

  bool get showsCustomName =>
      this == appliance || this == furniture || this == other;

  bool get showsChairCount => this == furniture;
}
