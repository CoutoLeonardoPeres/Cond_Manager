enum RentalBookingStatus {
  inquiry('inquiry', 'Consulta'),
  reserved('reserved', 'Reservado'),
  confirmed('confirmed', 'Confirmado'),
  checkedIn('checked_in', 'Check-in'),
  checkedOut('checked_out', 'Check-out'),
  cancelled('cancelled', 'Cancelado'),
  noShow('no_show', 'No-show');

  const RentalBookingStatus(this.value, this.label);
  final String value;
  final String label;

  static RentalBookingStatus fromValue(String value) {
    return RentalBookingStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => RentalBookingStatus.inquiry,
    );
  }
}
