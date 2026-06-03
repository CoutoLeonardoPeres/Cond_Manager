enum EntityStatus {
  active('active', 'Ativo'),
  inactive('inactive', 'Inativo'),
  blocked('blocked', 'Bloqueado'),
  pending('pending', 'Pendente');

  const EntityStatus(this.value, this.label);
  final String value;
  final String label;

  static EntityStatus fromValue(String value) {
    return EntityStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EntityStatus.pending,
    );
  }
}
