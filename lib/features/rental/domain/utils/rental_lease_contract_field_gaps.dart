import 'package:cond_manager/features/rental/domain/utils/rental_lease_contract_pdf_mapper.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_lease_contract_template.dart';

/// Onde cadastrar campos que ainda não existem no sistema.
enum RentalContractFieldPlacement {
  leaseForm,
  partyLandlord,
  partyTenantIntake,
  property,
  condominium,
  booking,
  companySettings,
  documentsAnnex,
  futureSignature,
}

class RentalContractFieldGap {
  const RentalContractFieldGap({
    required this.placeholder,
    required this.label,
    required this.placement,
    this.priority = RentalContractFieldPriority.medium,
  });

  final String placeholder;
  final String label;
  final RentalContractFieldPlacement placement;
  final RentalContractFieldPriority priority;
}

enum RentalContractFieldPriority { critical, high, medium, low }

const _blank = '________________';
const _notInformed = '[não informado]';

bool _isFilled(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  if (value == _blank || value == _notInformed) return false;
  return true;
}

/// Analisa quais placeholders do contrato estão preenchidos para o contexto informado.
RentalContractFieldGapReport analyzeRentalLeaseContractFieldGaps(
  RentalLeaseContractPdfContext context,
) {
  final values = buildRentalLeaseContractPlaceholderMap(context);
  final keys = rentalLeaseContractPlaceholderKeys;

  final filled = <String>[];
  final missing = <String>[];

  for (final key in keys) {
    if (_isFilled(values[key])) {
      filled.add(key);
    } else {
      missing.add(key);
    }
  }

  return RentalContractFieldGapReport(
    filledCount: filled.length,
    totalCount: keys.length,
    filledKeys: filled,
    missingKeys: missing,
    recommendedGaps: _recommendedGaps.where((g) => missing.contains(g.placeholder)).toList(),
  );
}

class RentalContractFieldGapReport {
  const RentalContractFieldGapReport({
    required this.filledCount,
    required this.totalCount,
    required this.filledKeys,
    required this.missingKeys,
    required this.recommendedGaps,
  });

  final int filledCount;
  final int totalCount;
  final List<String> filledKeys;
  final List<String> missingKeys;
  final List<RentalContractFieldGap> recommendedGaps;

  double get completenessRatio => totalCount == 0 ? 0 : filledCount / totalCount;
}

/// Campos prioritários para cadastro — agrupados por tela/módulo do sistema.
const _recommendedGaps = <RentalContractFieldGap>[
  // Locador — formulário de pessoa (categoria locador) ou intake do locador
  RentalContractFieldGap(
    placeholder: 'LOCADOR_NACIONALIDADE',
    label: 'Nacionalidade do locador',
    placement: RentalContractFieldPlacement.partyLandlord,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'LOCADOR_ESTADO_CIVIL',
    label: 'Estado civil do locador',
    placement: RentalContractFieldPlacement.partyLandlord,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'LOCADOR_PROFISSAO',
    label: 'Profissão do locador',
    placement: RentalContractFieldPlacement.partyLandlord,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'LOCADOR_RG_IE',
    label: 'RG / IE do locador',
    placement: RentalContractFieldPlacement.partyLandlord,
    priority: RentalContractFieldPriority.high,
  ),
  // Imóvel — cadastro do imóvel
  RentalContractFieldGap(
    placeholder: 'IMOVEL_MATRICULA_INSCRICAO',
    label: 'Matrícula / inscrição imobiliária',
    placement: RentalContractFieldPlacement.property,
    priority: RentalContractFieldPriority.critical,
  ),
  RentalContractFieldGap(
    placeholder: 'IMOVEL_INSCRICAO_IPTU',
    label: 'Inscrição IPTU',
    placement: RentalContractFieldPlacement.property,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'IMOVEL_MOBILIADO',
    label: 'Imóvel mobiliado (sim/não)',
    placement: RentalContractFieldPlacement.property,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'IMOVEL_ACEITA_PET',
    label: 'Aceita animais de estimação',
    placement: RentalContractFieldPlacement.property,
    priority: RentalContractFieldPriority.medium,
  ),
  // Contrato — tela de contrato
  RentalContractFieldGap(
    placeholder: 'TIPO_GARANTIA',
    label: 'Tipo de garantia locatícia',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.critical,
  ),
  RentalContractFieldGap(
    placeholder: 'INDICE_REAJUSTE',
    label: 'Índice de reajuste (IPCA, IGP-M…)',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'PERIODICIDADE_REAJUSTE',
    label: 'Periodicidade do reajuste (meses)',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'MULTA_RESCISORIA_BASE',
    label: 'Multa rescisória / fórmula',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'FORMA_PAGAMENTO',
    label: 'Forma de pagamento (PIX, boleto…)',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'CHAVE_PIX',
    label: 'Chave PIX do locador',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.medium,
  ),
  RentalContractFieldGap(
    placeholder: 'VALOR_TOTAL_TEMPORADA',
    label: 'Valor total temporada',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'POLITICA_CANCELAMENTO',
    label: 'Política de cancelamento',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'PRAZO_RESSALVA_VISTORIA',
    label: 'Prazo para ressalvas da vistoria (dias)',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.medium,
  ),
  RentalContractFieldGap(
    placeholder: 'FORMA_ENTREGA_CHAVES',
    label: 'Forma de entrega das chaves',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.medium,
  ),
  RentalContractFieldGap(
    placeholder: 'QUANTIDADE_MAXIMA_OCUPANTES',
    label: 'Quantidade máxima de ocupantes',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.medium,
  ),
  RentalContractFieldGap(
    placeholder: 'PERMITE_ANIMAIS',
    label: 'Permite animais de estimação',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.medium,
  ),
  RentalContractFieldGap(
    placeholder: 'TESTEMUNHA1_NOME',
    label: 'Testemunha 1 (nome e CPF)',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.low,
  ),
  RentalContractFieldGap(
    placeholder: 'TESTEMUNHA2_NOME',
    label: 'Testemunha 2 (nome e CPF)',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.low,
  ),
  // Locatário — já coberto pelo intake; campos extras
  RentalContractFieldGap(
    placeholder: 'LOCATARIO_RG_IE',
    label: 'RG do locatário',
    placement: RentalContractFieldPlacement.partyTenantIntake,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'LOCATARIO_NACIONALIDADE',
    label: 'Nacionalidade do locatário',
    placement: RentalContractFieldPlacement.partyTenantIntake,
    priority: RentalContractFieldPriority.medium,
  ),
  // Condomínio
  RentalContractFieldGap(
    placeholder: 'ANEXO_REGRAS_CONDOMINIO',
    label: 'Regras do condomínio (anexo)',
    placement: RentalContractFieldPlacement.condominium,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'RESTRICOES_CONDOMINIAIS_OU_LEGAIS',
    label: 'Restrições condominiais / legais',
    placement: RentalContractFieldPlacement.condominium,
    priority: RentalContractFieldPriority.high,
  ),
  // Temporada / plataforma — reserva + intake
  RentalContractFieldGap(
    placeholder: 'NOME_PLATAFORMA',
    label: 'Plataforma (Airbnb, Booking…)',
    placement: RentalContractFieldPlacement.booking,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'NUMERO_RESERVA_PLATAFORMA',
    label: 'Número da reserva',
    placement: RentalContractFieldPlacement.booking,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'VALOR_TOTAL_PLATAFORMA',
    label: 'Valor total na plataforma',
    placement: RentalContractFieldPlacement.booking,
    priority: RentalContractFieldPriority.high,
  ),
  // Encargos
  RentalContractFieldGap(
    placeholder: 'ENCARGOS_RESPONSABILIDADE_LOCATARIO',
    label: 'Encargos do locatário (IPTU, condomínio, água…)',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'ENCARGOS_RESPONSABILIDADE_LOCADOR',
    label: 'Encargos do locador',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.medium,
  ),
  // Inventário / vistoria — anexos
  RentalContractFieldGap(
    placeholder: 'ANEXO_INVENTARIO_MOVEIS',
    label: 'Inventário de móveis e utensílios',
    placement: RentalContractFieldPlacement.documentsAnnex,
    priority: RentalContractFieldPriority.high,
  ),
  RentalContractFieldGap(
    placeholder: 'LAUDO_VISTORIA_INICIAL_ANEXO',
    label: 'Laudo de vistoria inicial',
    placement: RentalContractFieldPlacement.documentsAnnex,
    priority: RentalContractFieldPriority.medium,
  ),
  // Multas contratuais
  RentalContractFieldGap(
    placeholder: 'MULTA_ATRASO_PERCENTUAL',
    label: 'Multa por atraso (%)',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.medium,
  ),
  RentalContractFieldGap(
    placeholder: 'JUROS_MORA_PERCENTUAL',
    label: 'Juros de mora (%)',
    placement: RentalContractFieldPlacement.leaseForm,
    priority: RentalContractFieldPriority.medium,
  ),
];

String placementLabel(RentalContractFieldPlacement p) => switch (p) {
      RentalContractFieldPlacement.leaseForm => 'Tela de Contrato',
      RentalContractFieldPlacement.partyLandlord => 'Cadastro de Pessoas (Locador)',
      RentalContractFieldPlacement.partyTenantIntake => 'Formulário do Locatário (intake)',
      RentalContractFieldPlacement.property => 'Cadastro de Imóveis',
      RentalContractFieldPlacement.condominium => 'Cadastro de Condomínio',
      RentalContractFieldPlacement.booking => 'Reserva / Plataforma',
      RentalContractFieldPlacement.companySettings => 'Configurações da Empresa',
      RentalContractFieldPlacement.documentsAnnex => 'Anexos do Contrato',
      RentalContractFieldPlacement.futureSignature => 'Assinatura Eletrônica (futuro)',
    };
