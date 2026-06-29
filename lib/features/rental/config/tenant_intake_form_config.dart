import 'package:cond_manager/features/rental/domain/entities/tenant_intake_form_models.dart';

/// Definição do formulário público de cadastro de locatário/inquilino.
TenantIntakeFormDefinition get defaultTenantIntakeFormDefinition =>
    TenantIntakeFormDefinition.fromJson(_formJson);

const _ufOptions = [
  ('AC', 'AC'), ('AL', 'AL'), ('AP', 'AP'), ('AM', 'AM'), ('BA', 'BA'),
  ('CE', 'CE'), ('DF', 'DF'), ('ES', 'ES'), ('GO', 'GO'), ('MA', 'MA'),
  ('MT', 'MT'), ('MS', 'MS'), ('MG', 'MG'), ('PA', 'PA'), ('PB', 'PB'),
  ('PR', 'PR'), ('PE', 'PE'), ('PI', 'PI'), ('RJ', 'RJ'), ('RN', 'RN'),
  ('RS', 'RS'), ('RO', 'RO'), ('RR', 'RR'), ('SC', 'SC'), ('SP', 'SP'),
  ('SE', 'SE'), ('TO', 'TO'),
];

Map<String, dynamic> get _formJson => {
      'form': {
        'id': 'cadastro_locatario_contrato_locacao',
        'name': 'Cadastro do Locatário para Contrato de Locação',
        'description':
            'Formulário para coleta de dados do inquilino/locatário para geração automática de contrato de locação.',
        'version': '1.0.0',
        'language': 'pt-BR',
        'submitButtonLabel': 'Enviar dados para geração do contrato',
        'successMessage':
            'Dados enviados com sucesso. Em breve o contrato será gerado e enviado para assinatura.',
        'whatsapp': {
          'enabled': true,
          'messageTemplate':
              'Olá, {{LOCATARIO_NOME_COMPLETO}}! Segue o link para preenchimento dos seus dados para geração do contrato de locação: {{FORM_LINK}}',
          'fallbackMessage':
              'Olá! Segue o link para preenchimento dos dados necessários para geração do contrato de locação: {{FORM_LINK}}',
          'linkExpirationHours': 72,
          'requiresAuthentication': false,
        },
        'sections': [
          {
            'id': 'tipo_locacao',
            'title': '1. Tipo e finalidade da locação',
            'description': 'Informe o tipo de locação desejado e a finalidade da estadia.',
            'fields': [
              _select('TIPO_LOCACAO', 'Tipo de locação', true, [
                ('Locação residencial de longo prazo', 'LONGO_PRAZO'),
                ('Locação por temporada', 'TEMPORADA'),
                ('Locação por diária', 'DIARIA'),
                ('Airbnb / Booking / Plataforma digital', 'PLATAFORMA_DIGITAL'),
                ('Outro', 'OUTRA'),
              ]),
              _textarea('TIPO_LOCACAO_OUTRA_DESCRICAO', 'Descreva o tipo de locação', false,
                  visible: _eq('TIPO_LOCACAO', 'OUTRA')),
              _select('FINALIDADE_LOCACAO', 'Finalidade da locação', true, [
                ('Moradia', 'MORADIA'),
                ('Lazer', 'LAZER'),
                ('Trabalho temporário', 'TRABALHO_TEMPORARIO'),
                ('Curso / estudo', 'CURSO_ESTUDO'),
                ('Tratamento de saúde', 'TRATAMENTO_SAUDE'),
                ('Evento', 'EVENTO'),
                ('Reforma em imóvel próprio', 'REFORMA_IMOVEL_PROPRIO'),
                ('Hospedagem temporária', 'HOSPEDAGEM_TEMPORARIA'),
                ('Outro', 'OUTRA'),
              ]),
              _textarea('OUTRA_FINALIDADE_LOCACAO', 'Descreva a finalidade', false,
                  visible: _eq('FINALIDADE_LOCACAO', 'OUTRA')),
              _text('IMOVEL_DESEJADO', 'Imóvel desejado', true,
                  placeholder: 'Informe o código, nome, referência ou endereço do imóvel'),
            ],
          },
          {
            'id': 'datas_entrada_saida',
            'title': '2. Previsão de entrada e saída',
            'description': 'Informe a data prevista de entrada e saída do imóvel.',
            'fields': [
              _field('DATA_PREVISTA_ENTRADA', 'Data prevista de entrada', 'date', true),
              _field('HORARIO_PREVISTO_ENTRADA', 'Horário previsto de entrada / check-in', 'time', true),
              _field('DATA_PREVISTA_SAIDA', 'Data prevista de saída', 'date', true),
              _field('HORARIO_PREVISTO_SAIDA', 'Horário previsto de saída / check-out', 'time', true),
              _number('PRAZO_PRETENDIDO_DIAS', 'Prazo pretendido em dias', min: 1),
              _number('PRAZO_PRETENDIDO_MESES', 'Prazo pretendido em meses', min: 1,
                  visible: _eq('TIPO_LOCACAO', 'LONGO_PRAZO')),
              _number('QUANTIDADE_DIARIAS', 'Quantidade de diárias', min: 1,
                  visible: _in('TIPO_LOCACAO', ['TEMPORADA', 'DIARIA', 'PLATAFORMA_DIGITAL'])),
              _select('PRETENDE_PRORROGAR', 'Existe possibilidade de prorrogação?', false, [
                ('Sim', 'SIM'),
                ('Não', 'NAO'),
                ('Talvez', 'TALVEZ'),
              ]),
              _textarea('MOTIVO_DA_LOCACAO', 'Motivo da locação', false),
              _textarea('OBSERVACOES_SOBRE_PERIODO', 'Observações sobre o período pretendido', false),
            ],
          },
          {
            'id': 'dados_pessoais_locatario',
            'title': '3. Dados pessoais do inquilino / locatário',
            'description': 'Informe seus dados pessoais para elaboração do contrato.',
            'fields': [
              _text('LOCATARIO_NOME_COMPLETO', 'Nome completo', true),
              _text('LOCATARIO_CPF', 'CPF', true, mask: '000.000.000-00'),
              _text('LOCATARIO_RG', 'RG ou documento equivalente', true),
              _text('LOCATARIO_ORGAO_EXPEDIDOR', 'Órgão expedidor', false),
              _field('LOCATARIO_DATA_NASCIMENTO', 'Data de nascimento', 'date', true),
              _text('LOCATARIO_NACIONALIDADE', 'Nacionalidade', true, defaultValue: 'Brasileira'),
              _select('LOCATARIO_ESTADO_CIVIL', 'Estado civil', true, [
                ('Solteiro(a)', 'SOLTEIRO'),
                ('Casado(a)', 'CASADO'),
                ('Divorciado(a)', 'DIVORCIADO'),
                ('Viúvo(a)', 'VIUVO'),
                ('União estável', 'UNIAO_ESTAVEL'),
                ('Separado(a)', 'SEPARADO'),
              ]),
              _select('LOCATARIO_REGIME_BENS', 'Regime de bens', false, [
                ('Comunhão parcial de bens', 'COMUNHAO_PARCIAL'),
                ('Comunhão universal de bens', 'COMUNHAO_UNIVERSAL'),
                ('Separação total de bens', 'SEPARACAO_TOTAL'),
                ('Participação final nos aquestos', 'PARTICIPACAO_FINAL_AQUESTOS'),
                ('Não sei informar', 'NAO_SEI'),
                ('Não se aplica', 'NAO_APLICA'),
              ], visible: _in('LOCATARIO_ESTADO_CIVIL', ['CASADO', 'UNIAO_ESTAVEL'])),
              _text('LOCATARIO_PROFISSAO', 'Profissão / ocupação', true),
              _field('LOCATARIO_EMAIL', 'E-mail', 'email', true),
              _field('LOCATARIO_TELEFONE', 'Telefone principal', 'tel', true, mask: '(00) 00000-0000'),
              _field('LOCATARIO_WHATSAPP', 'WhatsApp', 'tel', true, mask: '(00) 00000-0000'),
            ],
          },
          {
            'id': 'endereco_locatario',
            'title': '4. Endereço atual do inquilino',
            'description': 'Informe seu endereço residencial atual.',
            'fields': [
              _text('LOCATARIO_CEP', 'CEP', true, mask: '00000-000'),
              _text('LOCATARIO_LOGRADOURO', 'Rua / Avenida / Logradouro', true),
              _text('LOCATARIO_NUMERO', 'Número', true),
              _text('LOCATARIO_COMPLEMENTO', 'Complemento', false),
              _text('LOCATARIO_BAIRRO', 'Bairro', true),
              _text('LOCATARIO_CIDADE', 'Cidade', true),
              _select('LOCATARIO_ESTADO', 'Estado', true, _ufOptions),
              _text('LOCATARIO_PAIS', 'País', true, defaultValue: 'Brasil'),
            ],
          },
          {
            'id': 'dados_profissionais',
            'title': '5. Dados profissionais e renda',
            'description':
                'Dados utilizados para análise cadastral, especialmente em locações de longo prazo.',
            'fields': [
              _select('LOCATARIO_TIPO_RENDA', 'Tipo de renda', false, [
                ('CLT', 'CLT'),
                ('Autônomo', 'AUTONOMO'),
                ('MEI', 'MEI'),
                ('Empresário', 'EMPRESARIO'),
                ('Servidor público', 'SERVIDOR_PUBLICO'),
                ('Aposentado', 'APOSENTADO'),
                ('Pensionista', 'PENSIONISTA'),
                ('Profissional liberal', 'PROFISSIONAL_LIBERAL'),
                ('Outro', 'OUTRO'),
              ]),
              _text('LOCATARIO_EMPRESA_TRABALHO', 'Empresa onde trabalha', false),
              _text('LOCATARIO_CARGO', 'Cargo atual', false),
              _field('LOCATARIO_RENDA_MENSAL', 'Renda mensal aproximada', 'currency', false),
              _text('LOCATARIO_TEMPO_EMPRESA', 'Tempo de vínculo profissional', false,
                  placeholder: 'Ex.: 2 anos e 3 meses'),
              _text('LOCATARIO_ENDERECO_TRABALHO', 'Endereço profissional', false),
              _field('LOCATARIO_TELEFONE_TRABALHO', 'Telefone comercial', 'tel', false),
            ],
          },
          {
            'id': 'conjuge_locatario',
            'title': '6. Dados do cônjuge ou companheiro(a)',
            'description': 'Preencha se for casado(a) ou viver em união estável.',
            'fields': [
              _select('LOCATARIO_POSSUI_CONJUGE', 'Possui cônjuge ou companheiro(a)?', true, [
                ('Sim', 'SIM'),
                ('Não', 'NAO'),
              ]),
              _text('CONJUGE_NOME_COMPLETO', 'Nome completo do cônjuge', false,
                  visible: _eq('LOCATARIO_POSSUI_CONJUGE', 'SIM')),
              _text('CONJUGE_CPF', 'CPF do cônjuge', false, mask: '000.000.000-00',
                  visible: _eq('LOCATARIO_POSSUI_CONJUGE', 'SIM')),
              _text('CONJUGE_RG', 'RG do cônjuge', false, visible: _eq('LOCATARIO_POSSUI_CONJUGE', 'SIM')),
              _field('CONJUGE_DATA_NASCIMENTO', 'Data de nascimento do cônjuge', 'date', false,
                  visible: _eq('LOCATARIO_POSSUI_CONJUGE', 'SIM')),
              _text('CONJUGE_PROFISSAO', 'Profissão do cônjuge', false,
                  visible: _eq('LOCATARIO_POSSUI_CONJUGE', 'SIM')),
              _field('CONJUGE_EMAIL', 'E-mail do cônjuge', 'email', false,
                  visible: _eq('LOCATARIO_POSSUI_CONJUGE', 'SIM')),
              _field('CONJUGE_TELEFONE', 'Telefone do cônjuge', 'tel', false,
                  visible: _eq('LOCATARIO_POSSUI_CONJUGE', 'SIM')),
            ],
          },
          {
            'id': 'declaracoes',
            'title': '7. Declarações finais',
            'description': 'Confirme a veracidade das informações prestadas.',
            'fields': [
              _select('DECLARA_VERACIDADE', 'Declaro que as informações são verdadeiras', true, [
                ('Sim, declaro', 'SIM'),
              ]),
              _textarea('OBSERVACOES_FINAIS', 'Observações adicionais', false),
            ],
          },
        ],
      },
    };

Map<String, dynamic> _field(
  String name,
  String label,
  String type,
  bool required, {
  String? mask,
  String? placeholder,
  String? defaultValue,
  Map<String, dynamic>? visible,
}) =>
    {
      'name': name,
      'label': label,
      'type': type,
      'required': required,
      if (mask != null) 'mask': mask,
      if (placeholder != null) 'placeholder': placeholder,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (visible != null) 'visibleWhen': visible,
    };

Map<String, dynamic> _text(
  String name,
  String label,
  bool required, {
  String? mask,
  String? placeholder,
  String? defaultValue,
  Map<String, dynamic>? visible,
}) =>
    _field(name, label, 'text', required,
        mask: mask, placeholder: placeholder, defaultValue: defaultValue, visible: visible);

Map<String, dynamic> _textarea(String name, String label, bool required,
        {Map<String, dynamic>? visible}) =>
    _field(name, label, 'textarea', required, visible: visible);

Map<String, dynamic> _number(String name, String label, {num? min, Map<String, dynamic>? visible}) => {
      'name': name,
      'label': label,
      'type': 'number',
      'required': false,
      if (min != null) 'validation': {'min': min},
      if (visible != null) 'visibleWhen': visible,
    };

Map<String, dynamic> _select(
  String name,
  String label,
  bool required,
  List<(String, String)> options, {
  Map<String, dynamic>? visible,
}) =>
    {
      'name': name,
      'label': label,
      'type': 'select',
      'required': required,
      'options': options.map((o) => {'label': o.$1, 'value': o.$2}).toList(),
      if (visible != null) 'visibleWhen': visible,
    };

Map<String, dynamic> _eq(String field, String value) => {
      'field': field,
      'operator': 'equals',
      'value': value,
    };

Map<String, dynamic> _in(String field, List<String> values) => {
      'field': field,
      'operator': 'in',
      'value': values,
    };
