enum RentalListingMode {
  longTerm('long_term', 'Longo prazo'),
  shortTerm('short_term', 'Curta temporada'),
  seasonal('seasonal', 'Sazonal'),
  daily('daily', 'Diária'),
  corporate('corporate', 'Corporativo'),
  vacationRental('vacation_rental', 'Temporada/Férias');

  const RentalListingMode(this.value, this.label);
  final String value;
  final String label;

  static RentalListingMode fromValue(String value) {
    return RentalListingMode.values.firstWhere(
      (m) => m.value == value,
      orElse: () => RentalListingMode.longTerm,
    );
  }
}
