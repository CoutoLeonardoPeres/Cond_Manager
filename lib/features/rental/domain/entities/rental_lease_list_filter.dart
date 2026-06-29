import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:equatable/equatable.dart';

class RentalLeaseListFilter extends Equatable {
  const RentalLeaseListFilter({
    this.status,
    this.month,
  });

  final RentalLeaseStatus? status;
  final DateTime? month;

  RentalLeaseListFilter copyWith({
    RentalLeaseStatus? status,
    DateTime? month,
    bool clearStatus = false,
    bool clearMonth = false,
  }) {
    return RentalLeaseListFilter(
      status: clearStatus ? null : (status ?? this.status),
      month: clearMonth ? null : (month ?? this.month),
    );
  }

  @override
  List<Object?> get props => [status, month];
}

bool rentalLeaseMatchesFilter(RentalLease lease, RentalLeaseListFilter filter) {
  if (filter.status != null && lease.status != filter.status) {
    return false;
  }
  if (filter.month != null) {
    final monthStart = DateTime(filter.month!.year, filter.month!.month);
    final monthEnd = DateTime(filter.month!.year, filter.month!.month + 1, 0);
    if (lease.startDate.isAfter(monthEnd)) return false;
    final end = lease.endDate;
    if (end != null && end.isBefore(monthStart)) return false;
  }
  return true;
}
