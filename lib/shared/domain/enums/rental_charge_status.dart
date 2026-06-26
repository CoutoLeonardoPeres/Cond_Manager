enum RentalChargeStatus {
  pending('pending', 'Pendente'),
  paid('paid', 'Pago'),
  overdue('overdue', 'Atrasado'),
  cancelled('cancelled', 'Cancelado'),
  refunded('refunded', 'Reembolsado');

  const RentalChargeStatus(this.value, this.label);
  final String value;
  final String label;

  static RentalChargeStatus fromValue(String value) {
    return RentalChargeStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => RentalChargeStatus.pending,
    );
  }
}
