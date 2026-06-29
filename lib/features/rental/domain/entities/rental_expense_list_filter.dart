import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:equatable/equatable.dart';

class RentalExpenseListFilter extends Equatable {
  const RentalExpenseListFilter({
    this.condominiumId,
    this.unitId,
    this.month,
  });

  final String? condominiumId;
  final String? unitId;
  final DateTime? month;

  RentalExpenseListFilter copyWith({
    String? condominiumId,
    String? unitId,
    DateTime? month,
    bool clearCondominium = false,
    bool clearUnit = false,
    bool clearMonth = false,
  }) {
    return RentalExpenseListFilter(
      condominiumId: clearCondominium ? null : (condominiumId ?? this.condominiumId),
      unitId: clearUnit ? null : (unitId ?? this.unitId),
      month: clearMonth ? null : (month ?? this.month),
    );
  }

  @override
  List<Object?> get props => [condominiumId, unitId, month];
}

bool rentalExpenseMatchesFilter(FinancialRecord expense, RentalExpenseListFilter filter) {
  if (filter.condominiumId != null && expense.condominiumId != filter.condominiumId) {
    return false;
  }
  if (filter.month != null) {
    final ref = expense.referenceDate.toLocal();
    if (ref.year != filter.month!.year || ref.month != filter.month!.month) {
      return false;
    }
  }
  return true;
}

/// Totais das despesas visíveis na planilha (mesma lista filtrada passada à tabela).
class RentalExpenseSummary {
  const RentalExpenseSummary({
    required this.unpaidTotal,
    required this.unpaidCount,
    required this.paidTotal,
    required this.paidCount,
  });

  final double unpaidTotal;
  final int unpaidCount;
  final double paidTotal;
  final int paidCount;
}

RentalExpenseSummary computeRentalExpenseSummary(List<FinancialRecord> expenses) {
  final unpaid = expenses.where((e) => !e.isPaid).toList();
  final paid = expenses.where((e) => e.isPaid).toList();
  return RentalExpenseSummary(
    unpaidTotal: unpaid.fold<double>(0, (sum, e) => sum + e.amount),
    unpaidCount: unpaid.length,
    paidTotal: paid.fold<double>(0, (sum, e) => sum + e.amount),
    paidCount: paid.length,
  );
}
