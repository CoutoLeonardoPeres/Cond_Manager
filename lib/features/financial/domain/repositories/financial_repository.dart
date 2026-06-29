import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';

abstract class FinancialRepository {
  Future<Result<List<FinancialRecord>>> list(FinancialListFilter filter);

  Future<Result<List<FinancialRecord>>> listRentalExpenses({
    String? condominiumId,
    String? unitId,
  });

  Future<Result<int>> generateRecurringRentalExpenses({
    String? condominiumId,
    required DateTime month,
  });

  Future<Result<List<FinancialRecord>>> listRentalExpenseAllocations(String parentId);

  Future<Result<List<FinancialRecord>>> allocateRentalExpenseToUnits({
    required String expenseId,
    required String method,
  });

  Future<Result<FinancialRecord>> getById(String id);

  Future<Result<FinancialRecord>> create(FinancialRecordCreateInput input);

  Future<Result<FinancialRecord>> update(String id, FinancialRecordUpdateInput input);

  Future<Result<void>> delete(String id);

  Future<Result<FinancialReportSummary>> reportSummary({
    required FinancialScope scope,
    String? condominiumId,
    DateTime? fromDate,
    DateTime? toDate,
  });
}
