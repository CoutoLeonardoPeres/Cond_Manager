import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';
import 'package:cond_manager/shared/domain/enums/financial_category.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:equatable/equatable.dart';

class MonthlyFinancialPoint extends Equatable {
  const MonthlyFinancialPoint({
    required this.month,
    required this.income,
    required this.expenses,
  });

  final int month;
  final double income;
  final double expenses;

  double get balance => income - expenses;

  @override
  List<Object?> get props => [month, income, expenses];
}

class PropertyOccupancyPoint extends Equatable {
  const PropertyOccupancyPoint({
    required this.propertyId,
    required this.label,
    required this.occupancyRate,
  });

  final String propertyId;
  final String label;
  final double occupancyRate;

  @override
  List<Object?> get props => [propertyId, occupancyRate];
}

class UnitProfitabilityPoint extends Equatable {
  const UnitProfitabilityPoint({
    required this.key,
    required this.label,
    required this.revenue,
    required this.maintenanceCost,
  });

  final String key;
  final String label;
  final double revenue;
  final double maintenanceCost;

  double get netProfit => revenue - maintenanceCost;

  double get marginPercent => revenue > 0 ? (netProfit / revenue) * 100 : 0;

  @override
  List<Object?> get props => [key, revenue, maintenanceCost];
}

class DashboardFinancialMetrics extends Equatable {
  const DashboardFinancialMetrics({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.annualIncome,
    required this.annualExpenses,
    required this.monthlyTrend,
    required this.previousYearMonthlyExpenses,
    required this.occupancyRate,
    required this.occupiedProperties,
    required this.totalActiveProperties,
    required this.monthlyOccupancyTrend,
    required this.occupancyByProperty,
    required this.unitProfitability,
    required this.overallProfitMargin,
    required this.hasRentalModule,
  });

  final double monthlyIncome;
  final double monthlyExpenses;
  final double annualIncome;
  final double annualExpenses;
  final List<MonthlyFinancialPoint> monthlyTrend;
  final List<double> previousYearMonthlyExpenses;
  final double? occupancyRate;
  final int? occupiedProperties;
  final int? totalActiveProperties;
  final List<double> monthlyOccupancyTrend;
  final List<PropertyOccupancyPoint> occupancyByProperty;
  final List<UnitProfitabilityPoint> unitProfitability;
  final double overallProfitMargin;
  final bool hasRentalModule;

  double get monthlyBalance => monthlyIncome - monthlyExpenses;
  double get annualBalance => annualIncome - annualExpenses;

  @override
  List<Object?> get props => [monthlyIncome, annualIncome, occupancyRate];
}

bool isMaintenanceOrRepairExpense(FinancialRecord record) {
  if (!record.belongsToMaintenanceModule) return false;
  if (record.recordType != FinancialRecordType.expense) return false;
  if (record.workOrderId != null) return true;
  return switch (record.category) {
    FinancialCategory.materials ||
    FinancialCategory.laborHour ||
    FinancialCategory.contractedServices ||
    FinancialCategory.personnel ||
    FinancialCategory.freight ||
    FinancialCategory.tax ||
    FinancialCategory.overhead =>
      true,
    _ => false,
  };
}

String unitKeyForRecord(FinancialRecord record) {
  if (record.unitId != null) return 'unit:${record.unitId}';
  if (record.rentalPropertyId != null) return 'property:${record.rentalPropertyId}';
  if (record.blockId != null && record.unitLabel != null) {
    return 'block:${record.blockId}:${record.unitLabel}';
  }
  if (record.unitLabel != null) return 'label:${record.unitLabel}';
  return 'unassigned';
}

String unitLabelForRecord(FinancialRecord record) {
  final parts = <String>[
    if (record.blockName != null && record.blockName!.isNotEmpty) record.blockName!,
    if (record.unitLabel != null && record.unitLabel!.isNotEmpty) record.unitLabel!,
    if (record.rentalPropertyTitle != null && record.rentalPropertyTitle!.isNotEmpty)
      record.rentalPropertyTitle!,
  ];
  if (parts.isNotEmpty) return parts.join(' · ');
  return 'Sem unidade';
}

bool _recordInMonth(FinancialRecord record, int year, int month) {
  final d = record.referenceDate;
  return d.year == year && d.month == month;
}

bool _recordInYear(FinancialRecord record, int year) => record.referenceDate.year == year;

double _recordAmount(FinancialRecord record) => record.totalWithTax;

DashboardFinancialMetrics computeDashboardFinancialMetrics({
  required List<FinancialRecord> condoRecords,
  required List<FinancialRecord> companyRecords,
  required int year,
  required int focusMonth,
  String? condominiumId,
  List<RentalProperty> properties = const [],
  List<RentalBooking> bookings = const [],
  List<RentalLease> leases = const [],
  List<RentalCharge> paidCharges = const [],
  bool hasRentalModule = false,
}) {
  final records = [...condoRecords, ...companyRecords].where((r) {
    if (r.isRecurringTemplate) return false;
    if (r.isAllocationChild) return false;
    if (!hasRentalModule && !r.belongsToMaintenanceModule) return false;
    if (condominiumId != null && r.condominiumId != null && r.condominiumId != condominiumId) {
      return false;
    }
    return true;
  }).toList();

  double sumIncome(Iterable<FinancialRecord> list) => list
      .where((r) => r.recordType == FinancialRecordType.income)
      .fold(0.0, (s, r) => s + _recordAmount(r));

  double sumExpenses(Iterable<FinancialRecord> list) => list
      .where((r) => r.recordType == FinancialRecordType.expense)
      .fold(0.0, (s, r) => s + _recordAmount(r));

  final yearRecords = records.where((r) => _recordInYear(r, year)).toList();
  final monthRecords =
      yearRecords.where((r) => _recordInMonth(r, year, focusMonth)).toList();

  final monthlyTrend = List.generate(12, (i) {
    final m = i + 1;
    final bucket = yearRecords.where((r) => _recordInMonth(r, year, m));
    return MonthlyFinancialPoint(
      month: m,
      income: sumIncome(bucket),
      expenses: sumExpenses(bucket),
    );
  });

  final previousYearMonthlyExpenses = List.generate(12, (i) {
    final m = i + 1;
    return records
        .where(
          (r) =>
              r.recordType == FinancialRecordType.expense &&
              _recordInMonth(r, year - 1, m),
        )
        .fold(0.0, (s, r) => s + _recordAmount(r));
  });

  final activeProperties = properties
      .where((p) {
        if (p.status != 'active') return false;
        if (condominiumId != null && p.condominiumId != condominiumId) return false;
        return true;
      })
      .toList();

  double? occupancyRate;
  int? occupiedCount;
  final monthlyOccupancyTrend = <double>[];
  final occupancyByProperty = <PropertyOccupancyPoint>[];

  if (hasRentalModule && activeProperties.isNotEmpty) {
    final today = rentalGanttDateOnly(DateTime.now());
    occupiedCount = activeProperties
        .where(
          (p) => rentalPropertyIsOccupiedOnDate(
            propertyId: p.id,
            date: today,
            bookings: bookings,
            leases: leases,
          ),
        )
        .length;
    occupancyRate = (occupiedCount / activeProperties.length) * 100;

    for (var m = 1; m <= 12; m++) {
      final daysInMonth = DateTime(year, m + 1, 0).day;
      var occupiedDays = 0;
      for (var day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, m, day);
        for (final p in activeProperties) {
          if (rentalPropertyIsOccupiedOnDate(
            propertyId: p.id,
            date: date,
            bookings: bookings,
            leases: leases,
          )) {
            occupiedDays++;
          }
        }
      }
      final capacity = activeProperties.length * daysInMonth;
      monthlyOccupancyTrend.add(capacity > 0 ? (occupiedDays / capacity) * 100 : 0);
    }

    for (final p in activeProperties) {
      var occupiedDays = 0;
      for (var m = 1; m <= 12; m++) {
        final daysInMonth = DateTime(year, m + 1, 0).day;
        for (var day = 1; day <= daysInMonth; day++) {
          if (rentalPropertyIsOccupiedOnDate(
            propertyId: p.id,
            date: DateTime(year, m, day),
            bookings: bookings,
            leases: leases,
          )) {
            occupiedDays++;
          }
        }
      }
      final yearDays = DateTime(year + 1, 1, 1).difference(DateTime(year, 1, 1)).inDays;
      occupancyByProperty.add(
        PropertyOccupancyPoint(
          propertyId: p.id,
          label: p.title,
          occupancyRate: yearDays > 0 ? (occupiedDays / yearDays) * 100 : 0,
        ),
      );
    }
    occupancyByProperty.sort((a, b) => b.occupancyRate.compareTo(a.occupancyRate));
  }

  final unitMap = <String, ({String label, double revenue, double maintenance})>{};

  void addUnit(String key, String label, {double revenue = 0, double maintenance = 0}) {
    final cur = unitMap[key];
    unitMap[key] = (
      label: cur?.label ?? label,
      revenue: (cur?.revenue ?? 0) + revenue,
      maintenance: (cur?.maintenance ?? 0) + maintenance,
    );
  }

  for (final r in yearRecords) {
    final key = unitKeyForRecord(r);
    final label = unitLabelForRecord(r);
    if (r.recordType == FinancialRecordType.income) {
      addUnit(key, label, revenue: _recordAmount(r));
    } else if (isMaintenanceOrRepairExpense(r)) {
      addUnit(key, label, maintenance: _recordAmount(r));
    }
  }

  for (final charge in paidCharges) {
    if (!hasRentalModule) continue;
    if (charge.paidAt == null || charge.paidAt!.year != year) continue;
    final key = charge.propertyTitle != null ? 'charge:${charge.propertyTitle}' : 'charge:other';
    addUnit(key, charge.propertyTitle ?? 'Cobranças', revenue: charge.amount);
  }

  final unitProfitability = unitMap.entries
      .map(
        (e) => UnitProfitabilityPoint(
          key: e.key,
          label: e.value.label,
          revenue: e.value.revenue,
          maintenanceCost: e.value.maintenance,
        ),
      )
      .where((u) => u.revenue > 0 || u.maintenanceCost > 0)
      .toList()
    ..sort((a, b) => b.netProfit.compareTo(a.netProfit));

  final totalRevenue = unitProfitability.fold(0.0, (s, u) => s + u.revenue);
  final totalMaintenance = unitProfitability.fold(0.0, (s, u) => s + u.maintenanceCost);
  final overallProfitMargin = totalRevenue > 0
      ? ((totalRevenue - totalMaintenance) / totalRevenue) * 100.0
      : 0.0;

  return DashboardFinancialMetrics(
    monthlyIncome: sumIncome(monthRecords),
    monthlyExpenses: sumExpenses(monthRecords),
    annualIncome: sumIncome(yearRecords),
    annualExpenses: sumExpenses(yearRecords),
    monthlyTrend: monthlyTrend,
    previousYearMonthlyExpenses: previousYearMonthlyExpenses,
    occupancyRate: occupancyRate,
    occupiedProperties: occupiedCount,
    totalActiveProperties: activeProperties.isEmpty ? null : activeProperties.length,
    monthlyOccupancyTrend: monthlyOccupancyTrend,
    occupancyByProperty: occupancyByProperty.take(8).toList(),
    unitProfitability: unitProfitability.take(8).toList(),
    overallProfitMargin: overallProfitMargin,
    hasRentalModule: hasRentalModule,
  );
}
