enum RentalLeaseStatus {
  draft('draft', 'Rascunho'),
  active('active', 'Ativo'),
  expired('expired', 'Expirado'),
  terminated('terminated', 'Encerrado'),
  suspended('suspended', 'Suspenso');

  const RentalLeaseStatus(this.value, this.label);
  final String value;
  final String label;

  static RentalLeaseStatus fromValue(String value) {
    return RentalLeaseStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => RentalLeaseStatus.draft,
    );
  }
}
