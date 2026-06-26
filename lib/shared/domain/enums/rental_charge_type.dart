enum RentalChargeType {
  rent('rent', 'Aluguel'),
  deposit('deposit', 'Caução'),
  fee('fee', 'Taxa'),
  utility('utility', 'Condomínio/Utilidades'),
  cleaning('cleaning', 'Limpeza'),
  fine('fine', 'Multa'),
  refund('refund', 'Reembolso'),
  other('other', 'Outro');

  const RentalChargeType(this.value, this.label);
  final String value;
  final String label;

  static RentalChargeType fromValue(String value) {
    return RentalChargeType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => RentalChargeType.other,
    );
  }
}
