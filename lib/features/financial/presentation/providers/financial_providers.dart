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
  });

  final FinancialScope scope;
  final String? condominiumId;
  final DateTime? fromDate;
  final DateTime? toDate;

  @override
  List<Object?> get props => [scope, condominiumId, fromDate, toDate];
}

final financialListFilterProvider = StateProvider<FinancialListFilter>(
  (ref) => FinancialListFilter(
    scope: FinancialScope.condominium,
    fromDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
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
    fromDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
  ),
);

final financialCompanyReportFilterProvider = StateProvider<FinancialReportQuery>(
  (ref) => FinancialReportQuery(
    scope: FinancialScope.managementCompany,
    fromDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
  ),
);
