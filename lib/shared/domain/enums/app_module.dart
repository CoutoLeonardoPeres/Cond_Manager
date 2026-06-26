enum AppModule {
  maintenance('maintenance', 'Manutenção', 'Condomínios, chamados e ordens de serviço'),
  rental('rental', 'Locação', 'Imóveis, contratos, reservas e cobranças');

  const AppModule(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;

  static AppModule fromValue(String value) {
    return AppModule.values.firstWhere(
      (m) => m.value == value,
      orElse: () => AppModule.maintenance,
    );
  }
}
