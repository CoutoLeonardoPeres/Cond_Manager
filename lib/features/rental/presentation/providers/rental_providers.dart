import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/modules/data/repositories/company_modules_repository_impl.dart';
import 'package:cond_manager/features/modules/domain/repositories/company_modules_repository.dart';
import 'package:cond_manager/features/rental/data/repositories/rental_repository_impl.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/domain/repositories/rental_repository.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';
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
  (ref) => const RentalChargeListFilter(),
);

final rentalGanttRangeProvider = StateProvider<RentalGanttRange>(
  (ref) => rentalGanttDefaultRange(),
);

final rentalGanttBookingsProvider =
    FutureProvider.autoDispose<List<RentalBooking>>((ref) async {
  final range = ref.watch(rentalGanttRangeProvider);
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
  final filter = ref.watch(rentalPropertyListFilterProvider);
  final repo = ref.watch(rentalRepositoryProvider);
  final result = await repo.listProperties(filter);
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final rentalPropertyDetailProvider =
    FutureProvider.autoDispose.family<RentalProperty, String>((ref, id) async {
  final result = await ref.watch(rentalRepositoryProvider).getProperty(id);
  return result.when(success: (p) => p, failure: (e) => throw e);
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
  final filter = ref.watch(rentalChargeListFilterProvider);
  final result = await ref.watch(rentalRepositoryProvider).listCharges(filter);
  return result.when(success: (l) => l, failure: (e) => throw e);
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
