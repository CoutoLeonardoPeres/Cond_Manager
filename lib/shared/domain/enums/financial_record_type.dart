enum FinancialRecordType {
  expense('expense', 'Despesa'),
  income('income', 'Receita'),
  budget('budget', 'Orçamento');

  const FinancialRecordType(this.value, this.label);
  final String value;
  final String label;

  static FinancialRecordType fromValue(String value) {
    return FinancialRecordType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FinancialRecordType.expense,
    );
  }
}
