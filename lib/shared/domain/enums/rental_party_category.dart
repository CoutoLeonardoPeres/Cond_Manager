enum RentalPartyCategory {
  landlord('landlord', 'Locador'),
  tenant('tenant', 'Locatário'),
  occupant('occupant', 'Inquilino'),
  guest('guest', 'Hóspede');

  const RentalPartyCategory(this.value, this.label);

  final String value;
  final String label;

  static RentalPartyCategory fromValue(String value) {
    return RentalPartyCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => RentalPartyCategory.tenant,
    );
  }

  /// Pessoas elegíveis como proprietário de imóvel.
  bool get canBePropertyOwner => this == landlord;

  /// Pessoas elegíveis como inquilino/locatário em contratos.
  bool get canBeLeaseTenant => this == tenant || this == occupant;

  /// Pessoas elegíveis em reservas (curta temporada).
  bool get canBeBookingGuest => this == guest || canBeLeaseTenant;
}
