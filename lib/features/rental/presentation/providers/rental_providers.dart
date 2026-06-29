import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/modules/data/repositories/company_modules_repository_impl.dart';
import 'package:cond_manager/features/modules/domain/repositories/company_modules_repository.dart';
import 'package:cond_manager/features/rental/data/repositories/rental_repository_impl.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inclusion_catalog_item.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_inclusion.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_photo.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking_search_filter.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease_list_filter.dart';
import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_expense_list_filter.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/domain/repositories/rental_repository.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_expense_due_alerts.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_occupancy_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rentalRepositoryProvider = Provider<RentalRepository>((ref) {
  return RentalRepositoryImpl(ref.watch(supabaseClientProvider));
});

final companyModulesRepositoryProvider = Provider<CompanyModulesRepository>((ref) {
  return CompanyModulesRepositoryImpl(ref.watch(supabaseClientProvider));
});

final rentalPropertyListFilterProvider = StateProvider<RentalPropertyListFilter>(
  (ref) => const RentalPropertyListFilter(),
);

final rentalChargeListFilterProvider = StateProvider<RentalChargeListFilter>(
  (ref) => RentalChargeListFilter(
    month: DateTime(DateTime.now().year, DateTime.now().month),
  ),
);

final rentalLeaseListFilterProvider = StateProvider<RentalLeaseListFilter>(
  (ref) => RentalLeaseListFilter(
    month: DateTime(DateTime.now().year, DateTime.now().month),
  ),
);

final rentalExpenseListFilterProvider = StateProvider<RentalExpenseListFilter>(
  (ref) => RentalExpenseListFilter(
    month: DateTime(DateTime.now().year, DateTime.now().month),
  ),
);

final rentalLeaseSearchQueryProvider = StateProvider<String>((ref) => '');

final rentalBookingSearchFilterProvider = StateProvider<RentalBookingSearchFilter>(
  (ref) => const RentalBookingSearchFilter(),
);

final rentalPartySearchQueryProvider = StateProvider<String>((ref) => '');

final rentalOccupancyViewModeProvider = StateProvider<RentalOccupancyViewMode>(
  (ref) => RentalOccupancyViewMode.month,
);

final rentalOccupancyAnchorProvider = StateProvider<DateTime>(
  (ref) => rentalGanttDateOnly(DateTime.now()),
);

final rentalOccupancyRangeProvider = Provider<RentalGanttRange>((ref) {
  final mode = ref.watch(rentalOccupancyViewModeProvider);
  final anchor = ref.watch(rentalOccupancyAnchorProvider);
  return rentalOccupancyRangeFor(mode, anchor);
});

final rentalGanttBookingsProvider =
    FutureProvider.autoDispose<List<RentalBooking>>((ref) async {
  final range = ref.watch(rentalOccupancyRangeProvider);
  final result = await ref.watch(rentalRepositoryProvider).listBookings(
        from: range.start,
        to: range.end.subtract(const Duration(days: 1)),
      );
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalGanttLeasesProvider =
    FutureProvider.autoDispose<List<RentalLease>>((ref) async {
  final result = await ref.watch(rentalRepositoryProvider).listLeases();
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalPropertiesListProvider =
    FutureProvider.autoDispose<List<RentalProperty>>((ref) async {
  final repo = ref.watch(rentalRepositoryProvider);
  final result = await repo.listProperties(const RentalPropertyListFilter());
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalPropertiesByCondominiumProvider =
    FutureProvider.autoDispose.family<List<RentalProperty>, String>((ref, condominiumId) async {
  final result = await ref.watch(rentalRepositoryProvider).listProperties(
        RentalPropertyListFilter(condominiumId: condominiumId),
      );
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalPropertyDetailProvider =
    FutureProvider.autoDispose.family<RentalProperty, String>((ref, id) async {
  final result = await ref.watch(rentalRepositoryProvider).getProperty(id);
  return result.when(success: (p) => p, failure: (e) => throw e);
});

final rentalPropertyInclusionsProvider =
    FutureProvider.autoDispose.family<List<RentalPropertyInclusion>, String>((ref, id) async {
  final result = await ref.watch(rentalRepositoryProvider).listPropertyInclusions(id);
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalInclusionCatalogProvider =
    FutureProvider.autoDispose.family<List<RentalInclusionCatalogItem>, String>((ref, companyId) async {
  final result = await ref.watch(rentalRepositoryProvider).listInclusionCatalog(companyId);
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalPropertyPhotosProvider =
    FutureProvider.autoDispose.family<List<RentalPropertyPhoto>, String>((ref, id) async {
  final result = await ref.watch(rentalRepositoryProvider).listPropertyPhotos(id);
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalLeasesListProvider =
    FutureProvider.autoDispose<List<RentalLease>>((ref) async {
  final result = await ref.watch(rentalRepositoryProvider).listLeases();
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalLeaseDetailProvider =
    FutureProvider.autoDispose.family<RentalLease, String>((ref, id) async {
  final result = await ref.watch(rentalRepositoryProvider).getLease(id);
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalBookingsListProvider =
    FutureProvider.autoDispose<List<RentalBooking>>((ref) async {
  final result = await ref.watch(rentalRepositoryProvider).listBookings();
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalBookingDetailProvider =
    FutureProvider.autoDispose.family<RentalBooking, String>((ref, id) async {
  final result = await ref.watch(rentalRepositoryProvider).getBooking(id);
  return result.when(success: (b) => b, failure: (e) => throw e);
});

final rentalPartiesListProvider =
    FutureProvider.autoDispose<List<RentalParty>>((ref) async {
  final result = await ref.watch(rentalRepositoryProvider).listParties();
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalPartyDetailProvider =
    FutureProvider.autoDispose.family<RentalParty, String>((ref, id) async {
  final result = await ref.watch(rentalRepositoryProvider).getParty(id);
  return result.when(success: (p) => p, failure: (e) => throw e);
});

final rentalChargesListProvider =
    FutureProvider.autoDispose<List<RentalCharge>>((ref) async {
  final repo = ref.watch(rentalRepositoryProvider);
  await repo.generateMonthlyCharges();
  final filter = ref.watch(rentalChargeListFilterProvider);
  final result = await repo.listCharges(filter);
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalExpensesListProvider =
    FutureProvider.autoDispose<List<FinancialRecord>>((ref) async {
  final filter = ref.watch(rentalExpenseListFilterProvider);
  final repo = ref.watch(financialRepositoryProvider);
  final result = await repo.listRentalExpenses(
    condominiumId: filter.condominiumId,
  );
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalExpenseDetailProvider =
    FutureProvider.autoDispose.family<FinancialRecord, String>((ref, id) async {
  final result = await ref.watch(financialRepositoryProvider).getById(id);
  return result.when(success: (r) => r, failure: (e) => throw e);
});

final rentalExpenseAllocationsProvider =
    FutureProvider.autoDispose.family<List<FinancialRecord>, String>((ref, parentId) async {
  final result = await ref.watch(financialRepositoryProvider).listRentalExpenseAllocations(parentId);
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalExpenseDueAlertsProvider =
    FutureProvider.autoDispose<List<RentalExpenseDueAlert>>((ref) async {
  final expenses = await ref.watch(rentalExpensesListProvider.future);
  return computeRentalExpenseDueAlerts(expenses);
});

final rentalChargeDetailProvider =
    FutureProvider.autoDispose.family<RentalCharge, String>((ref, id) async {
  final result = await ref.watch(rentalRepositoryProvider).getCharge(id);
  return result.when(success: (c) => c, failure: (e) => throw e);
});

final companyModulesListProvider =
    FutureProvider.autoDispose<List<CompanyModuleRow>>((ref) async {
  final result = await ref.watch(companyModulesRepositoryProvider).listCompanyModules();
  return result.when(success: (l) => l, failure: (e) => throw e);
});
