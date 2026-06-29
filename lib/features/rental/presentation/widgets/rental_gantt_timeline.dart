import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/shared/domain/enums/rental_booking_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:equatable/equatable.dart';

/// Intervalo visível no gráfico (início inclusivo, fim exclusivo).
class RentalGanttRange extends Equatable {
  const RentalGanttRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get totalDays => end.difference(start).inDays;

  @override
  List<Object?> get props => [start, end];
}

enum RentalGanttSegmentKind { booking, lease }

class RentalGanttSegment extends Equatable {
  const RentalGanttSegment({
    required this.kind,
    required this.start,
    required this.end,
    required this.label,
    required this.id,
  });

  final RentalGanttSegmentKind kind;
  final DateTime start;
  final DateTime end;
  final String label;
  final String id;

  @override
  List<Object?> get props => [id, start, end];
}

class RentalGanttMonthHeader extends Equatable {
  const RentalGanttMonthHeader({
    required this.year,
    required this.month,
    required this.startDayIndex,
    required this.dayCount,
  });

  final int year;
  final int month;
  final int startDayIndex;
  final int dayCount;

  @override
  List<Object?> get props => [year, month, startDayIndex, dayCount];
}

DateTime rentalGanttDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int rentalGanttDayIndex(RentalGanttRange range, DateTime day) {
  return rentalGanttDateOnly(day).difference(range.start).inDays;
}

RentalGanttRange rentalGanttDefaultRange({DateTime? anchor}) {
  final now = anchor ?? DateTime.now();
  final start = DateTime(now.year - 1, now.month, 1);
  final end = DateTime(now.year + 2, now.month + 1, 1);
  return RentalGanttRange(start: start, end: end);
}

List<RentalGanttMonthHeader> rentalGanttMonthHeaders(RentalGanttRange range) {
  final headers = <RentalGanttMonthHeader>[];
  var cursor = DateTime(range.start.year, range.start.month, 1);
  while (cursor.isBefore(range.end)) {
    final monthStart = cursor.isBefore(range.start) ? range.start : cursor;
    final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
    final monthEnd = nextMonth.isBefore(range.end) ? nextMonth : range.end;
    final startIndex = monthStart.difference(range.start).inDays;
    final dayCount = monthEnd.difference(monthStart).inDays;
    if (dayCount > 0) {
      headers.add(
        RentalGanttMonthHeader(
          year: cursor.year,
          month: cursor.month,
          startDayIndex: startIndex,
          dayCount: dayCount,
        ),
      );
    }
    cursor = nextMonth;
  }
  return headers;
}

List<RentalGanttSegment> rentalGanttSegmentsForProperty({
  required String propertyId,
  required List<RentalBooking> bookings,
  required List<RentalLease> leases,
  required RentalGanttRange range,
}) {
  final segments = <RentalGanttSegment>[];

  for (final booking in bookings) {
    if (booking.propertyId != propertyId) continue;
    if (booking.status == RentalBookingStatus.cancelled) continue;
    final seg = _clipSegment(
      start: rentalGanttDateOnly(booking.checkIn),
      end: rentalGanttDateOnly(booking.checkOut),
      range: range,
    );
    if (seg == null) continue;
    segments.add(
      RentalGanttSegment(
        kind: RentalGanttSegmentKind.booking,
        start: seg.$1,
        end: seg.$2,
        label: booking.guestName,
        id: booking.id,
      ),
    );
  }

  for (final lease in leases) {
    if (lease.propertyId != propertyId) continue;
    if (lease.status != RentalLeaseStatus.active) continue;
    final leaseEnd = lease.endDate != null
        ? rentalGanttDateOnly(lease.endDate!).add(const Duration(days: 1))
        : range.end;
    final seg = _clipSegment(
      start: rentalGanttDateOnly(lease.startDate),
      end: leaseEnd,
      range: range,
    );
    if (seg == null) continue;
    segments.add(
      RentalGanttSegment(
        kind: RentalGanttSegmentKind.lease,
        start: seg.$1,
        end: seg.$2,
        label: lease.tenantName ?? 'Contrato',
        id: lease.id,
      ),
    );
  }

  segments.sort((a, b) => a.start.compareTo(b.start));
  return segments;
}

(DateTime, DateTime)? _clipSegment({
  required DateTime start,
  required DateTime end,
  required RentalGanttRange range,
}) {
  if (!end.isAfter(start)) return null;
  final clippedStart = start.isBefore(range.start) ? range.start : start;
  final clippedEnd = end.isAfter(range.end) ? range.end : end;
  if (!clippedEnd.isAfter(clippedStart)) return null;
  return (clippedStart, clippedEnd);
}

List<RentalProperty> rentalGanttSortedProperties(List<RentalProperty> properties) {
  final list = [...properties];
  list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  return list;
}

/// Imóvel ocupado em [date] por reserva (não cancelada) ou contrato ativo.
bool rentalPropertyIsOccupiedOnDate({
  required String propertyId,
  required DateTime date,
  required List<RentalBooking> bookings,
  required List<RentalLease> leases,
}) {
  final day = rentalGanttDateOnly(date);

  for (final booking in bookings) {
    if (booking.propertyId != propertyId) continue;
    if (booking.status == RentalBookingStatus.cancelled) continue;
    final start = rentalGanttDateOnly(booking.checkIn);
    final end = rentalGanttDateOnly(booking.checkOut);
    if (!day.isBefore(start) && day.isBefore(end)) return true;
  }

  for (final lease in leases) {
    if (lease.propertyId != propertyId) continue;
    if (lease.status != RentalLeaseStatus.active) continue;
    final start = rentalGanttDateOnly(lease.startDate);
    if (day.isBefore(start)) continue;
    if (lease.endDate != null && day.isAfter(rentalGanttDateOnly(lease.endDate!))) {
      continue;
    }
    return true;
  }

  return false;
}

List<RentalProperty> rentalVacantProperties({
  required List<RentalProperty> properties,
  required List<RentalBooking> bookings,
  required List<RentalLease> leases,
  DateTime? onDate,
}) {
  final day = rentalGanttDateOnly(onDate ?? DateTime.now());
  final vacant = properties.where((p) {
    if (p.status != 'active') return false;
    return !rentalPropertyIsOccupiedOnDate(
      propertyId: p.id,
      date: day,
      bookings: bookings,
      leases: leases,
    );
  }).toList();
  vacant.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  return vacant;
}
