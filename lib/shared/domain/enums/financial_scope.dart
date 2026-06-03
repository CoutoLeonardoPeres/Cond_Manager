enum FinancialScope {
  condominium('condominium', 'Condomínio'),
  managementCompany('management_company', 'Empresa gestora');

  const FinancialScope(this.value, this.label);
  final String value;
  final String label;

  static FinancialScope fromValue(String value) {
    return FinancialScope.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FinancialScope.condominium,
    );
  }
}
