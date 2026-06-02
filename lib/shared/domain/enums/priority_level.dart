enum PriorityLevel {
  low('low', 'Baixa'),
  medium('medium', 'Média'),
  high('high', 'Alta'),
  urgent('urgent', 'Urgente');

  const PriorityLevel(this.value, this.label);
  final String value;
  final String label;

  static PriorityLevel fromValue(String value) {
    return PriorityLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PriorityLevel.medium,
    );
  }
}
