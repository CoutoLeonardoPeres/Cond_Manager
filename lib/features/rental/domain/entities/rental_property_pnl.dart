import 'package:equatable/equatable.dart';

class RentalPropertyPnl extends Equatable {
  const RentalPropertyPnl({
    required this.propertyId,
    required this.propertyTitle,
    this.condominiumName,
    required this.rentalRevenue,
    required this.maintenanceCost,
    required this.ticketCount,
    required this.workOrderCount,
  });

  final String propertyId;
  final String propertyTitle;
  final String? condominiumName;
  final double rentalRevenue;
  final double maintenanceCost;
  final int ticketCount;
  final int workOrderCount;

  double get netIncome => rentalRevenue - maintenanceCost;

  @override
  List<Object?> get props => [propertyId, rentalRevenue, maintenanceCost];
}
