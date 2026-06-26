enum RentalBookingChannel {
  direct('direct', 'Direto'),
  airbnb('airbnb', 'Airbnb'),
  bookingCom('booking_com', 'Booking.com'),
  expedia('expedia', 'Expedia'),
  decolar('decolar', 'Decolar'),
  whatsapp('whatsapp', 'WhatsApp'),
  agency('agency', 'Imobiliária'),
  other('other', 'Outro');

  const RentalBookingChannel(this.value, this.label);
  final String value;
  final String label;

  static RentalBookingChannel fromValue(String value) {
    return RentalBookingChannel.values.firstWhere(
      (c) => c.value == value,
      orElse: () => RentalBookingChannel.other,
    );
  }
}
