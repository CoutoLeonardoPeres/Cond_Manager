enum StockMovementType {
  entry('entry', 'Entrada'),
  exit('exit', 'Saída'),
  adjustment('adjustment', 'Ajuste');

  const StockMovementType(this.value, this.label);
  final String value;
  final String label;

  static StockMovementType fromValue(String value) {
    return StockMovementType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StockMovementType.entry,
    );
  }
}
