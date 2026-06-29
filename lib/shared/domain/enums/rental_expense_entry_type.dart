enum RentalExpenseEntryType {
  fixedBill('fixed_bill', 'Conta / despesa fixa'),
  service('service', 'Serviço técnico'),
  material('material', 'Material / insumo');

  const RentalExpenseEntryType(this.value, this.label);
  final String value;
  final String label;

  static RentalExpenseEntryType fromValue(String value) {
    return RentalExpenseEntryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RentalExpenseEntryType.fixedBill,
    );
  }
}
