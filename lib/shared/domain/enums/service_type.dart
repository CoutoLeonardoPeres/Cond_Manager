enum ServiceType {
  electrical('electrical', 'Elétrica'),
  plumbing('plumbing', 'Hidráulica'),
  mechanical('mechanical', 'Mecânica'),
  masonry('masonry', 'Alvenaria'),
  painting('painting', 'Pintura'),
  gates('gates', 'Portões'),
  accessControl('access_control', 'Controle de acesso'),
  cctv('cctv', 'CFTV'),
  intercom('intercom', 'Interfonia'),
  cleaning('cleaning', 'Limpeza'),
  waterTank('water_tank', 'Caixas d\'água'),
  lighting('lighting', 'Iluminação'),
  landscaping('landscaping', 'Paisagismo'),
  elevators('elevators', 'Elevadores'),
  pumps('pumps', 'Bombas'),
  pool('pool', 'Piscina'),
  roof('roof', 'Telhado'),
  waterproofing('waterproofing', 'Impermeabilização'),
  other('other', 'Outros');

  const ServiceType(this.value, this.label);
  final String value;
  final String label;

  static ServiceType fromValue(String value) {
    return ServiceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ServiceType.other,
    );
  }
}
