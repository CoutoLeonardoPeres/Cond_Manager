import 'package:cond_manager/core/formatters/brazilian_input_format.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:equatable/equatable.dart';

class RentalBookingSearchFilter extends Equatable {
  const RentalBookingSearchFilter({
    this.name = '',
    this.cpf = '',
    this.phone = '',
    this.email = '',
  });

  final String name;
  final String cpf;
  final String phone;
  final String email;

  RentalBookingSearchFilter copyWith({
    String? name,
    String? cpf,
    String? phone,
    String? email,
  }) {
    return RentalBookingSearchFilter(
      name: name ?? this.name,
      cpf: cpf ?? this.cpf,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  bool get hasActiveFilters =>
      name.trim().isNotEmpty ||
      cpf.trim().isNotEmpty ||
      phone.trim().isNotEmpty ||
      email.trim().isNotEmpty;

  @override
  List<Object?> get props => [name, cpf, phone, email];
}

bool rentalBookingMatchesSearchFilter(
  RentalBooking booking,
  RentalBookingSearchFilter filter,
) {
  final nameQuery = filter.name.trim().toLowerCase();
  if (nameQuery.isNotEmpty && !booking.guestName.toLowerCase().contains(nameQuery)) {
    return false;
  }

  final cpfDigits = BrazilianInputFormat.digitsOnly(filter.cpf);
  if (cpfDigits.isNotEmpty) {
    final docDigits = BrazilianInputFormat.digitsOnly(booking.guestDocumentNumber);
    if (!docDigits.contains(cpfDigits)) return false;
  }

  final phoneDigits = BrazilianInputFormat.digitsOnly(filter.phone);
  if (phoneDigits.isNotEmpty) {
    final guestPhoneDigits = BrazilianInputFormat.digitsOnly(booking.guestPhone);
    if (!guestPhoneDigits.contains(phoneDigits)) return false;
  }

  final emailQuery = filter.email.trim().toLowerCase();
  if (emailQuery.isNotEmpty) {
    final guestEmail = booking.guestEmail?.trim().toLowerCase() ?? '';
    if (!guestEmail.contains(emailQuery)) return false;
  }

  return true;
}

List<RentalBooking> filterRentalBookings(
  List<RentalBooking> bookings,
  RentalBookingSearchFilter filter,
) {
  if (!filter.hasActiveFilters) return bookings;
  return bookings.where((b) => rentalBookingMatchesSearchFilter(b, filter)).toList();
}
