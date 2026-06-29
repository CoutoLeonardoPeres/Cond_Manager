enum CondominiumBillType {
  water('water', 'Água'),
  energy('energy', 'Energia elétrica'),
  gas('gas', 'Gás'),
  internet('internet', 'Internet'),
  cableTv('cable_tv', 'TV a cabo'),
  condoAdministration('condo_administration', 'Administração do condomínio'),
  syndic('syndic', 'Síndico / honorários'),
  administrator('administrator', 'Administradora'),
  proLabore('pro_labore', 'Pró-labore / funcionários fixos'),
  officeSupplies('office_supplies', 'Materiais de escritório'),
  improvements('improvements', 'Investimentos / melhorias'),
  other('other', 'Outros');

  const CondominiumBillType(this.value, this.label);
  final String value;
  final String label;

  static CondominiumBillType fromValue(String value) {
    return CondominiumBillType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CondominiumBillType.other,
    );
  }

  /// Contas que costumam ser repetidas todo mês.
  bool get typicallyRecurring => switch (this) {
        CondominiumBillType.water ||
        CondominiumBillType.energy ||
        CondominiumBillType.gas ||
        CondominiumBillType.internet ||
        CondominiumBillType.cableTv ||
        CondominiumBillType.condoAdministration ||
        CondominiumBillType.syndic ||
        CondominiumBillType.administrator ||
        CondominiumBillType.proLabore =>
          true,
        _ => false,
      };
}
