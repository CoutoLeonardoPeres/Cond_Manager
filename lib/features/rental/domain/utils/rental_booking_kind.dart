import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';

/// Reservas de hospedagem curta (diária, temporada, etc.).
/// Exclui aluguel fixo de longo prazo — esses contratos ficam em [rental_leases].
bool rentalBookingIsShortStay(RentalBooking booking) {
  if (booking.isFixedRent) return false;

  final mode = booking.propertyListingMode;
  if (mode == RentalListingMode.longTerm || mode == RentalListingMode.corporate) {
    return false;
  }

  return true;
}

List<RentalBooking> filterShortStayRentalBookings(List<RentalBooking> bookings) =>
    bookings.where(rentalBookingIsShortStay).toList();
