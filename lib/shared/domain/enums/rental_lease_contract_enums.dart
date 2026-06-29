enum RentalGuaranteeType {
  none('SEM_GARANTIA', 'Sem garantia'),
  depositCash('CAUCAO_DINHEIRO', 'Caução em dinheiro'),
  depositAsset('CAUCAO_BEM', 'Caução em bens'),
  guarantor('FIADOR', 'Fiança / fiador'),
  insurance('SEGURO_FIANCA', 'Seguro-fiança'),
  capitalization('TITULO_CAPITALIZACAO', 'Título de capitalização'),
  fiduciary('CESSAO_FIDUCIARIA', 'Cessão fiduciária'),
  other('OUTRA', 'Outra garantia');

  const RentalGuaranteeType(this.value, this.label);
  final String value;
  final String label;

  static RentalGuaranteeType? fromValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final e in values) {
      if (e.value == raw) return e;
    }
    return null;
  }
}

enum RentalAdjustmentIndex {
  ipca('IPCA', 'IPCA'),
  igpm('IGP-M', 'IGP-M'),
  inpc('INPC', 'INPC'),
  other('OUTRO', 'Outro índice'),
  none('SEM_REAJUSTE', 'Sem reajuste');

  const RentalAdjustmentIndex(this.value, this.label);
  final String value;
  final String label;

  static RentalAdjustmentIndex? fromValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final e in values) {
      if (e.value == raw) return e;
    }
    return null;
  }
}

enum RentalPaymentMethod {
  pix('PIX', 'PIX'),
  bankTransfer('TRANSFERENCIA', 'Transferência bancária'),
  boleto('BOLETO', 'Boleto'),
  cash('DINHEIRO', 'Dinheiro'),
  card('CARTAO', 'Cartão'),
  platform('PLATAFORMA', 'Pela plataforma digital'),
  other('OUTRO', 'Outro');

  const RentalPaymentMethod(this.value, this.label);
  final String value;
  final String label;

  static RentalPaymentMethod? fromValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final e in values) {
      if (e.value == raw) return e;
    }
    return null;
  }
}

enum RentalCancellationPolicy {
  flexible('FLEXIVEL', 'Flexível'),
  moderate('MODERADA', 'Moderada'),
  strict('RIGIDA', 'Rígida'),
  custom('PERSONALIZADA', 'Personalizada');

  const RentalCancellationPolicy(this.value, this.label);
  final String value;
  final String label;

  static RentalCancellationPolicy? fromValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final e in values) {
      if (e.value == raw) return e;
    }
    return null;
  }
}

enum RentalMaritalStatus {
  single('SOLTEIRO', 'Solteiro(a)'),
  married('CASADO', 'Casado(a)'),
  divorced('DIVORCIADO', 'Divorciado(a)'),
  widowed('VIUVO', 'Viúvo(a)'),
  stableUnion('UNIAO_ESTAVEL', 'União estável'),
  separated('SEPARADO', 'Separado(a)');

  const RentalMaritalStatus(this.value, this.label);
  final String value;
  final String label;

  static RentalMaritalStatus? fromValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final e in values) {
      if (e.value == raw) return e;
    }
    return null;
  }
}
