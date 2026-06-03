enum FinancialCategory {
  personnel('personnel', 'Pessoal / folha'),
  laborHour('labor_hour', 'Mão de obra / homem hora'),
  materials('materials', 'Materiais'),
  freight('freight', 'Frete / transporte'),
  tax('tax', 'Impostos'),
  contractedServices('contracted_services', 'Serviços contratados'),
  overhead('overhead', 'Custos operacionais'),
  condominiumPassThrough('condominium_pass_through', 'Repasse condomínio'),
  revenue('revenue', 'Receita'),
  other('other', 'Outros');

  const FinancialCategory(this.value, this.label);
  final String value;
  final String label;

  static FinancialCategory fromValue(String value) {
    return FinancialCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FinancialCategory.other,
    );
  }
}
