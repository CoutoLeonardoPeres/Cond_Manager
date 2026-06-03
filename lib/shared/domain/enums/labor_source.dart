enum LaborSource {
  thirdParty('third_party', 'Terceirizado'),
  internalTeam('internal_team', 'Equipe própria');

  const LaborSource(this.value, this.label);
  final String value;
  final String label;

  static LaborSource fromValue(String value) {
    return LaborSource.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LaborSource.thirdParty,
    );
  }
}
