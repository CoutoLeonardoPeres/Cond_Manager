import 'package:cond_manager/core/formatters/brazilian_input_format.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/domain/utils/tenant_intake_party_sync.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:intl/intl.dart';

/// Dados necessários para preencher o contrato de locação em PDF.
class RentalLeaseContractPdfContext {
  const RentalLeaseContractPdfContext({
    required this.property,
    this.landlord,
    this.tenant,
    required this.startDate,
    this.endDate,
    required this.monthlyRent,
    this.depositAmount,
    this.dueDayOfMonth,
    this.leaseNumber,
    this.leaseId,
    this.status = RentalLeaseStatus.draft,
    this.listingMode = RentalListingMode.longTerm,
    this.notes,
    this.generatedAt,
    this.contractTerms = RentalLeaseContractTerms.empty,
  });

  final RentalProperty property;
  final RentalParty? landlord;
  final RentalParty? tenant;
  final DateTime startDate;
  final DateTime? endDate;
  final double monthlyRent;
  final double? depositAmount;
  final int? dueDayOfMonth;
  final String? leaseNumber;
  final String? leaseId;
  final RentalLeaseStatus status;
  final RentalListingMode listingMode;
  final String? notes;
  final DateTime? generatedAt;
  final RentalLeaseContractTerms contractTerms;

  factory RentalLeaseContractPdfContext.fromLease({
    required RentalLease lease,
    required RentalProperty property,
    RentalParty? landlord,
    RentalParty? tenant,
  }) {
    return RentalLeaseContractPdfContext(
      property: property,
      landlord: landlord,
      tenant: tenant,
      startDate: lease.startDate,
      endDate: lease.endDate,
      monthlyRent: lease.monthlyRent,
      depositAmount: lease.depositAmount,
      dueDayOfMonth: lease.dueDayOfMonth,
      leaseNumber: lease.leaseNumber,
      leaseId: lease.id,
      status: lease.status,
      listingMode: lease.listingMode,
      notes: lease.notes,
      contractTerms: lease.contractTerms,
    );
  }
}

const _notInformed = '[não informado]';
const _blankLine = '________________';

final _dateFmt = DateFormat('dd/MM/yyyy');
final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

const _tipoLocacaoLabels = <String, String>{
  'LONGO_PRAZO': 'Locação residencial de longo prazo',
  'TEMPORADA': 'Locação por temporada',
  'DIARIA': 'Locação por diária',
  'PLATAFORMA_DIGITAL': 'Locação por plataforma digital',
  'AIRBNB': 'Locação por plataforma digital (Airbnb)',
  'BOOKING': 'Locação por plataforma digital (Booking)',
  'OUTRA': 'Outra modalidade',
};

const _finalidadeLabels = <String, String>{
  'MORADIA': 'Moradia',
  'LAZER': 'Lazer',
  'TRABALHO_TEMPORARIO': 'Trabalho temporário',
  'CURSO_ESTUDO': 'Curso / estudo',
  'CURSO': 'Curso / estudo',
  'TRATAMENTO_SAUDE': 'Tratamento de saúde',
  'EVENTO': 'Evento',
  'REFORMA_IMOVEL_PROPRIO': 'Reforma em imóvel próprio',
  'HOSPEDAGEM_TEMPORARIA': 'Hospedagem temporária',
  'OUTRA': 'Outra finalidade',
};

const _estadoCivilLabels = <String, String>{
  'SOLTEIRO': 'solteiro(a)',
  'CASADO': 'casado(a)',
  'DIVORCIADO': 'divorciado(a)',
  'VIUVO': 'viúvo(a)',
  'UNIAO_ESTAVEL': 'em união estável',
  'SEPARADO': 'separado(a)',
};

/// Monta o mapa de placeholders para o template do contrato.
Map<String, String> buildRentalLeaseContractPlaceholderMap(
  RentalLeaseContractPdfContext context,
) {
  final values = <String, String>{};
  final intake = context.tenant != null
      ? partyToIntakeFieldValues(context.tenant!)
      : <String, String>{};
  final generatedAt = context.generatedAt ?? DateTime.now();

  void set(String key, String? value) {
    if (value != null && value.trim().isNotEmpty) {
      values[key] = value.trim();
    }
  }

  String labelFor(Map<String, String> map, String key, Map<String, String> labels) {
    final raw = map[key]?.trim();
    if (raw == null || raw.isEmpty) return '';
    return labels[raw.toUpperCase()] ?? raw;
  }

  String formatDocument(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final digits = BrazilianInputFormat.digitsOnly(value);
    if (digits.length > 11) return BrazilianInputFormat.formatCnpj(value);
    return BrazilianInputFormat.formatCpf(value);
  }

  String formatAddress({
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
    String? zip,
    String? country,
  }) {
    final parts = <String>[
      if (street != null && street.trim().isNotEmpty) street.trim(),
      if (number != null && number.trim().isNotEmpty) 'nº ${number.trim()}',
      if (complement != null && complement.trim().isNotEmpty) complement.trim(),
      if (neighborhood != null && neighborhood.trim().isNotEmpty) neighborhood.trim(),
      if (city != null && city.trim().isNotEmpty) city.trim(),
      if (state != null && state.trim().isNotEmpty) state.trim(),
      if (zip != null && zip.trim().isNotEmpty) 'CEP ${zip.trim()}',
      if (country != null && country.trim().isNotEmpty) country.trim(),
    ];
    return parts.join(', ');
  }

  void mapParty({
    required String prefix,
    required RentalParty? party,
    Map<String, String> intakeFields = const {},
    bool isTenant = false,
  }) {
    final nameKey = isTenant ? 'LOCATARIO_NOME_COMPLETO' : null;
    final name = party?.fullName ??
        (nameKey != null ? intakeFields[nameKey] : null) ??
        '';

    set('${prefix}_NOME', name);
    set('${prefix}_EMAIL', party?.email ?? intakeFields['${prefix}_EMAIL']);
    set(
      '${prefix}_TELEFONE',
      party?.phone ??
          intakeFields['${prefix}_TELEFONE'] ??
          intakeFields['${prefix}_WHATSAPP'],
    );
    set('${prefix}_WHATSAPP', intakeFields['${prefix}_WHATSAPP'] ?? party?.phone);

    final doc = party?.documentNumber ??
        intakeFields['${prefix}_CPF'] ??
        intakeFields['${prefix}_CPF_CNPJ'];
    set('${prefix}_CPF_CNPJ', formatDocument(doc));
  }

  void mapPartyAddress({
    required String prefix,
    required RentalParty? party,
    Map<String, String> intakeFields = const {},
  }) {
    set('${prefix}_LOGRADOURO', party?.addressStreet ?? intakeFields['${prefix}_LOGRADOURO']);
    set('${prefix}_NUMERO', party?.addressNumber ?? intakeFields['${prefix}_NUMERO']);
    set(
      '${prefix}_COMPLEMENTO',
      party?.addressComplement ?? intakeFields['${prefix}_COMPLEMENTO'],
    );
    set('${prefix}_BAIRRO', party?.addressNeighborhood ?? intakeFields['${prefix}_BAIRRO']);
    set('${prefix}_CIDADE', party?.addressCity ?? intakeFields['${prefix}_CIDADE']);
    set('${prefix}_ESTADO', party?.addressState ?? intakeFields['${prefix}_ESTADO']);
    set('${prefix}_CEP', party?.addressZip ?? intakeFields['${prefix}_CEP']);
    set('${prefix}_PAIS', intakeFields['${prefix}_PAIS'] ?? 'Brasil');

    final full = formatAddress(
      street: party?.addressStreet ?? intakeFields['${prefix}_LOGRADOURO'],
      number: party?.addressNumber ?? intakeFields['${prefix}_NUMERO'],
      complement: party?.addressComplement ?? intakeFields['${prefix}_COMPLEMENTO'],
      neighborhood: party?.addressNeighborhood ?? intakeFields['${prefix}_BAIRRO'],
      city: party?.addressCity ?? intakeFields['${prefix}_CIDADE'],
      state: party?.addressState ?? intakeFields['${prefix}_ESTADO'],
      zip: party?.addressZip ?? intakeFields['${prefix}_CEP'],
      country: intakeFields['${prefix}_PAIS'] ?? 'Brasil',
    );
    set('${prefix}_ENDERECO_COMPLETO', full);
  }

  void mapTenantIntakeExtras() {
    set('LOCATARIO_NACIONALIDADE', intake['LOCATARIO_NACIONALIDADE']);
    set(
      'LOCATARIO_ESTADO_CIVIL',
      labelFor(intake, 'LOCATARIO_ESTADO_CIVIL', _estadoCivilLabels),
    );
    set('LOCATARIO_PROFISSAO', intake['LOCATARIO_PROFISSAO']);
    set('LOCATARIO_RG_IE', intake['LOCATARIO_RG']);
    set('LOCATARIO_ORGAO_EXPEDIDOR', intake['LOCATARIO_ORGAO_EXPEDIDOR']);
    set('LOCATARIO_DATA_NASCIMENTO', _formatIntakeDate(intake['LOCATARIO_DATA_NASCIMENTO']));
    set('LOCATARIO_REGIME_BENS', intake['LOCATARIO_REGIME_BENS']);
    set('LOCATARIO_EMPRESA_TRABALHO', intake['LOCATARIO_EMPRESA_TRABALHO']);
    set('LOCATARIO_CARGO', intake['LOCATARIO_CARGO']);
    set('LOCATARIO_RENDA_MENSAL', intake['LOCATARIO_RENDA_MENSAL']);
    set('LOCATARIO_TEMPO_EMPRESA', intake['LOCATARIO_TEMPO_EMPRESA']);
    set('LOCATARIO_ENDERECO_TRABALHO', intake['LOCATARIO_ENDERECO_TRABALHO']);
    set('LOCATARIO_TELEFONE_TRABALHO', intake['LOCATARIO_TELEFONE_TRABALHO']);

    set('CONJUGE_NOME_COMPLETO', intake['CONJUGE_NOME_COMPLETO']);
    set('CONJUGE_CPF', formatDocument(intake['CONJUGE_CPF']));
    set('CONJUGE_RG', intake['CONJUGE_RG']);
    set('CONJUGE_PROFISSAO', intake['CONJUGE_PROFISSAO']);
    set('CONJUGE_EMAIL', intake['CONJUGE_EMAIL']);
    set('CONJUGE_TELEFONE', intake['CONJUGE_TELEFONE']);
  }

  // Locador
  mapParty(prefix: 'LOCADOR', party: context.landlord);
  mapPartyAddress(prefix: 'LOCADOR', party: context.landlord);
  final landlord = context.landlord;
  set('LOCADOR_NACIONALIDADE', landlord?.nationality);
  set(
    'LOCADOR_ESTADO_CIVIL',
    labelFor(
      {'MARITAL_STATUS': landlord?.maritalStatus ?? ''},
      'MARITAL_STATUS',
      _estadoCivilLabels,
    ),
  );
  set('LOCADOR_PROFISSAO', landlord?.profession);
  if (landlord != null) {
    final rgParts = <String>[
      if (landlord.rgNumber != null && landlord.rgNumber!.trim().isNotEmpty)
        landlord.rgNumber!.trim(),
      if (landlord.rgIssuer != null && landlord.rgIssuer!.trim().isNotEmpty)
        landlord.rgIssuer!.trim(),
    ];
    set('LOCADOR_RG_IE', rgParts.isNotEmpty ? rgParts.join(' — ') : null);
  }
  values.putIfAbsent('LOCADOR_NACIONALIDADE', () => _notInformed);
  values.putIfAbsent('LOCADOR_ESTADO_CIVIL', () => _notInformed);
  values.putIfAbsent('LOCADOR_PROFISSAO', () => _notInformed);
  values.putIfAbsent('LOCADOR_RG_IE', () => _blankLine);

  // Locatário
  mapParty(prefix: 'LOCATARIO', party: context.tenant, intakeFields: intake, isTenant: true);
  mapPartyAddress(prefix: 'LOCATARIO', party: context.tenant, intakeFields: intake);
  mapTenantIntakeExtras();

  // Imóvel
  final property = context.property;
  set('IMOVEL_CODIGO_INTERNO', property.code ?? property.title);
  set('IMOVEL_TIPO', property.propertyType.label);
  set('IMOVEL_DESCRICAO_GERAL', property.description);
  set('IMOVEL_LOGRADOURO', property.addressStreet);
  set('IMOVEL_NUMERO', property.addressNumber);
  set('IMOVEL_BLOCO', property.addressBlock);
  set('IMOVEL_UNIDADE', property.addressApartment);
  set('IMOVEL_BAIRRO', property.addressNeighborhood);
  set('IMOVEL_CIDADE', property.addressCity);
  set('IMOVEL_ESTADO', property.addressState);
  set('IMOVEL_CEP', property.addressZip);
  set('IMOVEL_PAIS', 'Brasil');
  if (property.bedrooms != null) set('IMOVEL_QUARTOS', property.bedrooms.toString());
  if (property.bathrooms != null) set('IMOVEL_BANHEIROS', property.bathrooms.toString());
  if (property.areaSqm != null) {
    set('IMOVEL_AREA_PRIVATIVA', '${property.areaSqm!.toStringAsFixed(0)} m²');
    set('IMOVEL_AREA_TOTAL', '${property.areaSqm!.toStringAsFixed(0)} m²');
  }

  final propertyAddress = formatAddress(
    street: property.addressStreet,
    number: property.addressNumber,
    complement: property.addressBuilding,
    neighborhood: property.addressNeighborhood,
    city: property.addressCity,
    state: property.addressState,
    zip: property.addressZip,
    country: 'Brasil',
  );
  set('IMOVEL_ENDERECO_COMPLETO', propertyAddress.isNotEmpty ? propertyAddress : property.title);

  final matriculaParts = <String>[
    if (property.registryMatricula != null && property.registryMatricula!.trim().isNotEmpty)
      'Matrícula nº ${property.registryMatricula!.trim()}',
    if (property.registryCartorio != null && property.registryCartorio!.trim().isNotEmpty)
      'Cartório: ${property.registryCartorio!.trim()}',
    if (property.municipalInscription != null && property.municipalInscription!.trim().isNotEmpty)
      'Inscrição municipal: ${property.municipalInscription!.trim()}',
  ];
  set('IMOVEL_MATRICULA_INSCRICAO', matriculaParts.isNotEmpty ? matriculaParts.join('; ') : null);
  set('IMOVEL_INSCRICAO_IPTU', property.iptuInscription);
  if (property.isFurnished != null) {
    set('IMOVEL_MOBILIADO', property.isFurnished! ? 'Sim' : 'Não');
  }
  if (property.acceptsPets != null) {
    set('IMOVEL_ACEITA_PET', property.acceptsPets! ? 'Sim' : 'Não');
  }
  values.putIfAbsent('IMOVEL_MATRICULA_INSCRICAO', () => _blankLine);

  set('CONDOMINIO_NOME', property.condominiumName);
  values.putIfAbsent('CONDOMINIO_EXISTE', () => property.condominiumName != null ? 'Sim' : 'Não');

  // Tipo e finalidade
  final tipoCode = intake['TIPO_LOCACAO'] ?? _listingModeToTipoCode(context.listingMode);
  final tipoLabel = labelFor({'TIPO_LOCACAO': tipoCode}, 'TIPO_LOCACAO', _tipoLocacaoLabels);
  set('TIPO_LOCACAO', tipoLabel.isNotEmpty ? tipoLabel : _listingModeLabel(context.listingMode));
  set('TIPO_LOCACAO_OUTRA_DESCRICAO', intake['TIPO_LOCACAO_OUTRA_DESCRICAO']);

  final finalidadeCode = intake['FINALIDADE_LOCACAO'];
  final finalidadeLabel =
      labelFor({'FINALIDADE_LOCACAO': finalidadeCode ?? ''}, 'FINALIDADE_LOCACAO', _finalidadeLabels);
  set(
    'FINALIDADE_LOCACAO',
    finalidadeLabel.isNotEmpty ? finalidadeLabel : _defaultFinalidade(context.listingMode),
  );
  set('FINALIDADE_OUTRA_DESCRICAO', intake['OUTRA_FINALIDADE_LOCACAO']);

  // Prazo
  set('DATA_INICIO_LOCACAO', _dateFmt.format(context.startDate));
  set(
    'DATA_TERMINO_LOCACAO',
    context.endDate != null ? _dateFmt.format(context.endDate!) : 'prazo indeterminado',
  );

  final periodDays = context.endDate != null
      ? context.endDate!.difference(context.startDate).inDays + 1
      : null;
  if (periodDays != null && periodDays > 0) {
    set('QUANTIDADE_DIAS_MESES', '$periodDays dia(s)');
    set('PRAZO_TOTAL_DIAS', periodDays.toString());
  } else {
    values.putIfAbsent('QUANTIDADE_DIAS_MESES', () => _notInformed);
  }

  final monthsIntake = intake['PRAZO_PRETENDIDO_MESES'];
  final months = monthsIntake ??
      (context.endDate != null ? _monthsBetween(context.startDate, context.endDate!).toString() : null);
  set('PRAZO_LONGO_PRAZO_MESES', months);
  set('QUANTIDADE_DIARIAS', intake['QUANTIDADE_DIARIAS']);

  // Check-in / check-out
  set('DATA_CHECKIN', _formatIntakeDate(intake['DATA_PREVISTA_ENTRADA']) ?? _dateFmt.format(context.startDate));
  set('DATA_CHECKOUT', _formatIntakeDate(intake['DATA_PREVISTA_SAIDA']) ??
      (context.endDate != null ? _dateFmt.format(context.endDate!) : null));
  set('HORARIO_CHECKIN', intake['HORARIO_PREVISTO_ENTRADA']);
  set('HORARIO_CHECKOUT', intake['HORARIO_PREVISTO_SAIDA']);
  set('DATA_ENTREGA_CHAVES', _formatIntakeDate(intake['DATA_PREVISTA_ENTRADA']) ?? _dateFmt.format(context.startDate));

  // Valores
  if (context.monthlyRent > 0) {
    set('VALOR_ALUGUEL_MENSAL', _currencyFmt.format(context.monthlyRent).replaceAll('\u00a0', ' '));
  }
  if (context.depositAmount != null && context.depositAmount! > 0) {
    set('VALOR_CAUCAO', _currencyFmt.format(context.depositAmount!).replaceAll('\u00a0', ' '));
    values.putIfAbsent('GARANTIA_EXISTE', () => 'Sim');
  } else {
    values.putIfAbsent('GARANTIA_EXISTE', () => 'Não');
  }

  final terms = context.contractTerms;
  if (terms.guaranteeType != null) {
    set('TIPO_GARANTIA', terms.guaranteeType!.label);
  } else if (context.depositAmount != null && context.depositAmount! > 0) {
    set('TIPO_GARANTIA', 'caução em dinheiro');
  } else {
    values.putIfAbsent('TIPO_GARANTIA', () => _notInformed);
  }
  set('GARANTIA_OUTRA_DESCRICAO', terms.guaranteeOtherDescription);
  set('INDICE_REAJUSTE', terms.adjustmentIndex?.label);
  if (terms.adjustmentPeriodMonths != null) {
    set('PERIODICIDADE_REAJUSTE', terms.adjustmentPeriodMonths.toString());
  }
  set('FORMA_PAGAMENTO', terms.paymentMethod?.label);
  set('CHAVE_PIX', terms.pixKey);
  set('BANCO_NOME', terms.bankName);
  set('BANCO_AGENCIA', terms.bankAgency);
  set('BANCO_CONTA', terms.bankAccount);
  set('BANCO_TIPO_CONTA', terms.bankAccountType);
  set('BANCO_TITULAR', terms.bankHolder);
  set('BANCO_CPF_CNPJ_TITULAR', terms.bankHolderDocument);
  if (terms.lateFeePercent != null) {
    set('MULTA_ATRASO_PERCENTUAL', terms.lateFeePercent.toString());
  }
  if (terms.interestPercent != null) {
    set('JUROS_MORA_PERCENTUAL', terms.interestPercent.toString());
  }
  if (terms.terminationPenaltyMonths != null) {
    set('MULTA_RESCISORIA_BASE', '${terms.terminationPenaltyMonths} mês(es) de aluguel');
    set(
      'MULTA_RESCISORIA_FORMULA',
      'Multa devida = ${terms.terminationPenaltyMonths} aluguéis × meses restantes / prazo total contratado',
    );
  }
  if (terms.inspectionObjectionDays != null) {
    set('PRAZO_RESSALVA_VISTORIA', terms.inspectionObjectionDays.toString());
  }
  set('FORMA_ENTREGA_CHAVES', terms.keyDeliveryMethod);
  set('FORMA_DEVOLUCAO_CHAVES', terms.keyDeliveryMethod);
  if (terms.maxOccupants != null) {
    set('QUANTIDADE_MAXIMA_OCUPANTES', terms.maxOccupants.toString());
  }
  if (terms.allowsPets != null) {
    set('PERMITE_ANIMAIS', terms.allowsPets! ? 'Sim, conforme regras abaixo' : 'Não');
    set('DESCRICAO_ANIMAIS_PERMITIDOS', terms.petsDescription);
  }
  set('POLITICA_CANCELAMENTO', terms.cancellationPolicy?.label);
  if (terms.seasonTotalAmount != null && terms.seasonTotalAmount! > 0) {
    set(
      'VALOR_TOTAL_TEMPORADA',
      _currencyFmt.format(terms.seasonTotalAmount!).replaceAll('\u00a0', ' '),
    );
  }
  set('ENCARGOS_RESPONSABILIDADE_LOCATARIO', terms.tenantCharges);
  set('ENCARGOS_RESPONSABILIDADE_LOCADOR', terms.landlordCharges);
  set('TESTEMUNHA1_NOME', terms.witness1Name);
  set('TESTEMUNHA1_CPF', formatDocument(terms.witness1Cpf));
  set('TESTEMUNHA2_NOME', terms.witness2Name);
  set('TESTEMUNHA2_CPF', formatDocument(terms.witness2Cpf));

  if (context.dueDayOfMonth != null) {
    set('DIA_VENCIMENTO_ALUGUEL', context.dueDayOfMonth.toString());
  }

  if (property.baseDailyRate != null && property.baseDailyRate! > 0) {
    set('VALOR_DIARIA', _currencyFmt.format(property.baseDailyRate!).replaceAll('\u00a0', ' '));
  }

  // Contrato / metadados
  set('CONTRATO_ID', context.leaseId);
  set('CONTRATO_NUMERO', context.leaseNumber);
  set('CONTRATO_DATA_GERACAO', _dateFmt.format(generatedAt));
  set('CONTRATO_STATUS', context.status.label);
  set('CONTRATO_MODELO_UTILIZADO', 'Contrato padrão de locação de imóvel');
  set('CONTRATO_OBSERVACOES_GERAIS', context.notes);
  set('LOCAL_ASSINATURA', property.addressCity ?? property.locationLabel);
  set('DATA_ASSINATURA', _dateFmt.format(generatedAt));
  set('FORO_COMARCA', property.addressCity ?? _notInformed);
  set('FORO_ESTADO', property.addressState ?? _notInformed);

  // Testemunhas e campos não mapeados ficam com sublinhado via template default.
  return values;
}

String? _formatIntakeDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final trimmed = raw.trim();
  try {
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(trimmed)) {
      return _dateFmt.format(DateTime.parse(trimmed));
    }
    if (RegExp(r'^\d{2}/\d{2}/\d{4}').hasMatch(trimmed)) {
      return trimmed;
    }
  } catch (_) {}
  return trimmed;
}

int _monthsBetween(DateTime start, DateTime end) {
  var months = (end.year - start.year) * 12 + end.month - start.month;
  if (end.day < start.day) months -= 1;
  return months < 0 ? 0 : months;
}

String _listingModeToTipoCode(RentalListingMode mode) => switch (mode) {
      RentalListingMode.longTerm || RentalListingMode.corporate => 'LONGO_PRAZO',
      RentalListingMode.daily => 'DIARIA',
      RentalListingMode.shortTerm ||
      RentalListingMode.seasonal ||
      RentalListingMode.vacationRental =>
        'TEMPORADA',
    };

String _listingModeLabel(RentalListingMode mode) => switch (mode) {
      RentalListingMode.longTerm => 'Locação residencial de longo prazo',
      RentalListingMode.daily => 'Locação por diária',
      RentalListingMode.shortTerm => 'Locação por temporada',
      RentalListingMode.seasonal => 'Locação sazonal',
      RentalListingMode.vacationRental => 'Locação por temporada / férias',
      RentalListingMode.corporate => 'Locação corporativa',
    };

String _defaultFinalidade(RentalListingMode mode) => switch (mode) {
      RentalListingMode.longTerm || RentalListingMode.corporate => 'Moradia',
      RentalListingMode.daily ||
      RentalListingMode.shortTerm ||
      RentalListingMode.seasonal ||
      RentalListingMode.vacationRental =>
        'Lazer',
    };

/// Valida dados mínimos para gerar o PDF.
String? validateRentalLeaseContractPdfContext(RentalLeaseContractPdfContext context) {
  if (context.property.id.isEmpty) return 'Selecione o imóvel.';
  if (context.tenant == null) return 'Selecione o inquilino / locatário.';
  if (context.monthlyRent <= 0) return 'Informe o aluguel mensal.';
  return null;
}
