import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/financial/data/repositories/financial_repository_impl.dart';
import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/domain/repositories/financial_repository.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  return FinancialRepositoryImpl(ref.watch(supabaseClientProvider));
});

class FinancialReportQuery extends Equatable {
  const FinancialReportQuery({
    required this.scope,
    this.condominiumId,
    this.fromDate,
    this.toDate,
    this.excludeRentalModule = false,
  });

  final FinancialScope scope;
  final String? condominiumId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool excludeRentalModule;

  FinancialReportQuery copyWith({
    FinancialScope? scope,
    String? condominiumId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? excludeRentalModule,
    bool clearCondominium = false,
    bool clearDates = false,
  }) {
    return FinancialReportQuery(
      scope: scope ?? this.scope,
      condominiumId: clearCondominium ? null : (condominiumId ?? this.condominiumId),
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
      excludeRentalModule: excludeRentalModule ?? this.excludeRentalModule,
    );
  }

  FinancialReportQuery withReferenceMonth(DateTime? month) {
    if (month == null) return copyWith(clearDates: true);
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);
    return copyWith(fromDate: from, toDate: to);
  }

  DateTime? get referenceMonth =>
      fromDate == null ? null : DateTime(fromDate!.year, fromDate!.month, 1);

  @override
  List<Object?> get props =>
      [scope, condominiumId, fromDate, toDate, excludeRentalModule];
}

DateTime _currentMonthStart() => DateTime(DateTime.now().year, DateTime.now().month, 1);

DateTime _currentMonthEnd() => DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

final financialListFilterProvider = StateProvider<FinancialListFilter>(
  (ref) => FinancialListFilter(
    scope: FinancialScope.condominium,
    fromDate: _currentMonthStart(),
    toDate: _currentMonthEnd(),
    excludeRentalModule: true,
  ),
);

final financialRecordsListProvider =
    FutureProvider.autoDispose<List<FinancialRecord>>((ref) async {
  final filter = ref.watch(financialListFilterProvider);
  final repo = ref.watch(financialRepositoryProvider);
  final result = await repo.list(filter);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final financialRecordDetailProvider =
    FutureProvider.autoDispose.family<FinancialRecord, String>((ref, id) async {
  final repo = ref.watch(financialRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (r) => r,
    failure: (e) => throw e,
  );
});

final financialReportProvider =
    FutureProvider.autoDispose.family<FinancialReportSummary, FinancialReportQuery>(
  (ref, query) async {
    final repo = ref.watch(financialRepositoryProvider);
    final result = await repo.reportSummary(
      scope: query.scope,
      condominiumId: query.condominiumId,
      fromDate: query.fromDate,
      toDate: query.toDate,
      excludeRentalModule: query.excludeRentalModule,
    );
    return result.when(
      success: (s) => s,
      failure: (e) => throw e,
    );
  },
);

final financialCondoReportFilterProvider = StateProvider<FinancialReportQuery>(
  (ref) => FinancialReportQuery(
    scope: FinancialScope.condominium,
    fromDate: _currentMonthStart(),
    toDate: _currentMonthEnd(),
    excludeRentalModule: true,
  ),
);

final financialCompanyReportFilterProvider = StateProvider<FinancialReportQuery>(
  (ref) => FinancialReportQuery(
    scope: FinancialScope.managementCompany,
    fromDate: _currentMonthStart(),
    toDate: _currentMonthEnd(),
    excludeRentalModule: true,
  ),
);
