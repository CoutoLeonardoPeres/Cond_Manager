enum OrganizationRole {
  manager('manager', 'Gerente'),
  analyst('analyst', 'Analista'),
  fieldTeam('field_team', 'Equipe de campo'),
  client('client', 'Usuário cliente');

  const OrganizationRole(this.value, this.label);
  final String value;
  final String label;

  static OrganizationRole fromValue(String value) {
    return OrganizationRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => OrganizationRole.client,
    );
  }
}
