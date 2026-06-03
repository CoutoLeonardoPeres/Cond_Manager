enum ProviderType {
  supplier('supplier', 'Fornecedor'),
  outsourced('outsourced', 'Terceirizado'),
  subcontracted('subcontracted', 'Subempreiteiro'),
  internalTeam('internal_team', 'Equipe interna');

  const ProviderType(this.value, this.label);
  final String value;
  final String label;

  static ProviderType fromValue(String value) {
    return ProviderType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProviderType.outsourced,
    );
  }
}
