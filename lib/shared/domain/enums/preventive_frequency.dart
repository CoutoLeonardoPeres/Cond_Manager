enum PreventiveFrequency {
  daily('daily', 'Diária'),
  weekly('weekly', 'Semanal'),
  monthly('monthly', 'Mensal'),
  quarterly('quarterly', 'Trimestral'),
  semiannual('semiannual', 'Semestral'),
  annual('annual', 'Anual');

  const PreventiveFrequency(this.value, this.label);
  final String value;
  final String label;

  static PreventiveFrequency fromValue(String value) {
    return PreventiveFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PreventiveFrequency.monthly,
    );
  }
}
