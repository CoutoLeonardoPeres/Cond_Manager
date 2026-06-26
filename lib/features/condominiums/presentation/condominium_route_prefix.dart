/// Prefixo de rotas para reutilizar telas de condomínio em Manutenção e Locação.
class CondominiumRoutePrefix {
  const CondominiumRoutePrefix(this.base);

  final String base;

  static const maintenance = CondominiumRoutePrefix('/condominiums');
  static const rental = CondominiumRoutePrefix('/rental/condominiums');

  String get list => base;
  String detail(String id) => '$base/$id';
  String get create => '$base/new';
  String edit(String id) => '$base/$id/edit';
}
