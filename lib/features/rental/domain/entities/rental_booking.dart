import 'package:cond_manager/shared/domain/enums/rental_booking_channel.dart';
import 'package:cond_manager/shared/domain/enums/rental_booking_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:equatable/equatable.dart';

class RentalBooking extends Equatable {
  const RentalBooking({
    required this.id,
    required this.companyId,
    required this.propertyId,
    required this.propertyTitle,
    this.propertyListingMode,
    this.unitId,
    this.bookingNumber,
    required this.channel,
    required this.status,
    required this.guestName,
    this.guestEmail,
    this.guestPhone,
    this.guestDocumentNumber,
    this.guestPartyId,
    required this.guestsCount,
    required this.checkIn,
    required this.checkOut,
    this.nightlyRate,
    this.totalAmount,
    this.paidAmount,
    this.isFixedRent = false,
    this.monthlyRent,
    this.paymentDueDay,
    this.notes,
  });

  final String id;
  final String companyId;
  final String propertyId;
  final String propertyTitle;
  final RentalListingMode? propertyListingMode;
  final String? unitId;
  final String? bookingNumber;
  final RentalBookingChannel channel;
  final RentalBookingStatus status;
  final String guestName;
  final String? guestEmail;
  final String? guestPhone;
  final String? guestDocumentNumber;
  final String? guestPartyId;
  final int guestsCount;
  final DateTime checkIn;
  final DateTime checkOut;
  final double? nightlyRate;
  final double? totalAmount;
  final double? paidAmount;
  final bool isFixedRent;
  final double? monthlyRent;
  final int? paymentDueDay;
  final String? notes;

  int get nights => checkOut.difference(checkIn).inDays;

  @override
  List<Object?> get props => [id];
}
