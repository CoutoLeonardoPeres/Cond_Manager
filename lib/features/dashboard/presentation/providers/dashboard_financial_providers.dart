import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/dashboard/domain/dashboard_financial_metrics.dart';
import 'package:cond_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardFinancialMetricsProvider =
    FutureProvider.autoDispose<DashboardFinancialMetrics>((ref) async {
  final filter = ref.watch(dashboardFilterProvider);
  final year = filter.effectiveYear;
  final focusMonth = filter.anchorDate.month;
  final condoId = filter.condominiumId;

  final profile = ref.watch(currentProfileProvider).value;
  final hasRental = profile?.permissions.hasModule(AppModule.rental) ?? false;

  final financialRepo = ref.watch(financialRepositoryProvider);

  final yearEnd = DateTime(year, 12, 31);

  final condoFilter = FinancialListFilter(
    scope: FinancialScope.condominium,
    condominiumId: condoId,
    fromDate: DateTime(year - 1, 1, 1),
    toDate: yearEnd,
  );
  final companyFilter = FinancialListFilter(
    scope: FinancialScope.managementCompany,
    fromDate: DateTime(year - 1, 1, 1),
    toDate: yearEnd,
  );

  final condoResult = await financialRepo.list(condoFilter);
  final companyResult = await financialRepo.list(companyFilter);

  final condoRecords = condoResult.when(
    success: (l) => l,
    failure: (e) => throw e,
  );
  final companyRecords = companyResult.when(
    success: (l) => l,
    failure: (e) => throw e,
  );

  if (!hasRental) {
    return computeDashboardFinancialMetrics(
      condoRecords: condoRecords,
      companyRecords: companyRecords,
      year: year,
      focusMonth: focusMonth,
      condominiumId: condoId,
      hasRentalModule: false,
    );
  }

  final properties = await ref.watch(rentalPropertiesListProvider.future);
  final bookings = await ref.watch(rentalBookingsListProvider.future);
  final leases = await ref.watch(rentalLeasesListProvider.future);

  final rentalRepo = ref.watch(rentalRepositoryProvider);
  final chargesResult = await rentalRepo.listCharges(
    const RentalChargeListFilter(status: RentalChargeStatus.paid),
  );
  final paidCharges = chargesResult.when(
    success: (l) => l,
    failure: (e) => throw e,
  );

  return computeDashboardFinancialMetrics(
    condoRecords: condoRecords,
    companyRecords: companyRecords,
    year: year,
    focusMonth: focusMonth,
    condominiumId: condoId,
    properties: properties,
    bookings: bookings,
    leases: leases,
    paidCharges: paidCharges,
    hasRentalModule: true,
  );
});
