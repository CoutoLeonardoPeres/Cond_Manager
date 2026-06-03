enum PreventiveExecutionStatus {
  pending('pending', 'Pendente'),
  completed('completed', 'Concluída'),
  skipped('skipped', 'Ignorada'),
  overdue('overdue', 'Atrasada');

  const PreventiveExecutionStatus(this.value, this.label);
  final String value;
  final String label;

  static PreventiveExecutionStatus fromValue(String value) {
    return PreventiveExecutionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PreventiveExecutionStatus.pending,
    );
  }
}
