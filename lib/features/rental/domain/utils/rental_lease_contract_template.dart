/// Texto integral do contrato de locação com placeholders `{{CHAVE}}`.
library;

const String rentalLeaseContractTemplate = '''
CONTRATO DE LOCAÇÃO DE IMÓVEL
Pelo presente instrumento particular, de um lado:
LOCADOR: {{LOCADOR_NOME}}, {{LOCADOR_NACIONALIDADE}}, {{LOCADOR_ESTADO_CIVIL}}, {{LOCADOR_PROFISSAO}}, portador(a) do CPF/CNPJ nº {{LOCADOR_CPF_CNPJ}}, RG/Inscrição Estadual nº {{LOCADOR_RG_IE}}, residente/sediado(a) à {{LOCADOR_ENDERECO_COMPLETO}}, e-mail {{LOCADOR_EMAIL}}, telefone {{LOCADOR_TELEFONE}};
e, de outro lado:
LOCATÁRIO/INQUILINO: {{LOCATARIO_NOME}}, {{LOCATARIO_NACIONALIDADE}}, {{LOCATARIO_ESTADO_CIVIL}}, {{LOCATARIO_PROFISSAO}}, portador(a) do CPF/CNPJ nº {{LOCATARIO_CPF_CNPJ}}, RG/Inscrição Estadual nº {{LOCATARIO_RG_IE}}, residente/sediado(a) à {{LOCATARIO_ENDERECO_COMPLETO}}, e-mail {{LOCATARIO_EMAIL}}, telefone {{LOCATARIO_TELEFONE}};
têm entre si justo e contratado o presente CONTRATO DE LOCAÇÃO DO IMÓVEL situado à {{IMOVEL_ENDERECO_COMPLETO}}, matrícula/inscrição imobiliária nº {{IMOVEL_MATRICULA_INSCRICAO}}, doravante denominado IMÓVEL, mediante as cláusulas e condições seguintes.
1. DO TIPO DE LOCAÇÃO
1.1. A presente contratação será classificada pelo sistema conforme o tipo indicado no campo abaixo:
Tipo de locação: {{TIPO_LOCACAO}}
1.2. Para fins deste contrato, o campo {{TIPO_LOCACAO}} poderá assumir uma das seguintes modalidades:
a) LOCAÇÃO RESIDENCIAL DE LONGO PRAZO;
b) LOCAÇÃO POR TEMPORADA;
c) LOCAÇÃO POR DIÁRIAS;
d) LOCAÇÃO POR PLATAFORMA DIGITAL, incluindo, mas não se limitando a Airbnb, Booking, Vrbo ou similares;
e) OUTRA MODALIDADE: {{TIPO_LOCACAO_OUTRA_DESCRICAO}}.
1.3. Independentemente da modalidade escolhida, deverão ser respeitados a boa-fé objetiva, a transparência, o equilíbrio contratual, a função social do contrato, a vedação ao enriquecimento sem causa e a legislação aplicável.
1.4. Quando a locação for contratada por prazo superior a 90 dias e tiver finalidade de moradia, presume-se, para fins contratuais, tratar-se de locação residencial de prazo determinado ou indeterminado, conforme o caso.
1.5. Quando a locação for contratada por prazo igual ou inferior a 90 dias e tiver finalidade temporária, tais como lazer, estudo, tratamento de saúde, trabalho transitório, reforma no imóvel próprio, eventos ou outras situações transitórias, será considerada locação por temporada.
1.6. Quando houver contratação por diárias ou por plataforma digital, sem prestação de serviços típicos de hotelaria pelo locador, como recepção permanente, limpeza diária obrigatória, alimentação, lavanderia ou serviços similares, as partes declaram que a relação pretendida é de locação temporária de imóvel, salvo se a legislação, a convenção condominial ou decisão competente reconhecer natureza diversa.
1.7. Caso a contratação seja realizada por plataforma digital, o presente contrato complementará as regras da plataforma, prevalecendo as disposições mais favoráveis ao LOCATÁRIO quando não houver conflito com norma legal obrigatória.
2. DA FINALIDADE DA LOCAÇÃO
2.1. O imóvel será utilizado pelo LOCATÁRIO para a seguinte finalidade:
Finalidade: {{FINALIDADE_LOCACAO}}
2.2. A finalidade poderá ser, entre outras:
a) moradia residencial;
b) estadia temporária de lazer;
c) estadia por motivo de trabalho;
d) realização de curso ou atividade educacional;
e) tratamento de saúde;
f) estadia durante reforma em imóvel próprio;
g) hospedagem temporária por evento;
h) outra finalidade lícita: {{FINALIDADE_OUTRA_DESCRICAO}}.
2.3. O LOCATÁRIO compromete-se a utilizar o imóvel de forma regular, pacífica, lícita e compatível com sua destinação, respeitando normas legais, condominiais e de vizinhança.
3. DO PRAZO DA LOCAÇÃO
3.1. A locação terá início em {{DATA_INICIO_LOCACAO}} e término em {{DATA_TERMINO_LOCACAO}}, totalizando {{QUANTIDADE_DIAS_MESES}}.
3.2. No caso de locação residencial de longo prazo, o prazo contratual será de {{PRAZO_LONGO_PRAZO_MESES}} meses, podendo ser prorrogado na forma da lei e deste contrato.
3.3. No caso de locação por temporada, diárias ou plataforma digital, o prazo não poderá superar 90 dias, salvo se as partes firmarem novo instrumento ou se a situação jurídica for reclassificada conforme a legislação aplicável.
3.4. No caso de diárias, o período contratado será de {{QUANTIDADE_DIARIAS}} diária(s), com check-in previsto para {{DATA_CHECKIN}} às {{HORARIO_CHECKIN}} e check-out previsto para {{DATA_CHECKOUT}} às {{HORARIO_CHECKOUT}}.
3.5. A permanência do LOCATÁRIO após o prazo ajustado dependerá de autorização expressa do LOCADOR, salvo hipóteses legais de prorrogação.
4. DO VALOR DO ALUGUEL, DIÁRIA OU PREÇO DA ESTADIA
4.1. O valor da locação será:
a) Para locação residencial de longo prazo: aluguel mensal de R\$ {{VALOR_ALUGUEL_MENSAL}};
b) Para locação por temporada: valor total de R\$ {{VALOR_TOTAL_TEMPORADA}};
c) Para locação por diárias: valor da diária de R\$ {{VALOR_DIARIA}}, totalizando R\$ {{VALOR_TOTAL_DIARIAS}};
d) Para locação por plataforma digital: valor total de R\$ {{VALOR_TOTAL_PLATAFORMA}}, conforme reserva nº {{NUMERO_RESERVA_PLATAFORMA}} realizada na plataforma {{NOME_PLATAFORMA}}.
4.2. O vencimento do aluguel mensal ocorrerá todo dia {{DIA_VENCIMENTO_ALUGUEL}} de cada mês.
4.3. No caso de temporada, diárias ou plataforma digital, o pagamento poderá ocorrer antecipadamente, de forma total ou parcial, conforme indicado abaixo:
Valor pago antecipadamente: R\$ {{VALOR_PAGO_ANTECIPADO}}
Saldo remanescente: R\$ {{VALOR_SALDO_REMANESCENTE}}
Data de vencimento do saldo: {{DATA_VENCIMENTO_SALDO}}
4.4. Nenhuma cobrança adicional poderá ser exigida do LOCATÁRIO sem previsão expressa neste contrato, na reserva da plataforma ou em documento aceito previamente pelo LOCATÁRIO.
4.5. Todas as cobranças deverão ser discriminadas de forma clara, indicando origem, competência, valor, vencimento e responsável pelo pagamento.
5. DO REAJUSTE
5.1. Esta cláusula aplica-se apenas às locações de longo prazo ou aos contratos com duração suficiente para admitir reajuste legal.
5.2. O aluguel poderá ser reajustado a cada {{PERIODICIDADE_REAJUSTE}} meses, pelo índice {{INDICE_REAJUSTE}}, ou outro índice que venha a substituí-lo legalmente.
5.3. Não haverá reajuste em locações por temporada, diárias ou plataforma digital, salvo prorrogação expressa ou nova contratação.
6. DA GARANTIA LOCATÍCIA
6.1. A garantia contratual escolhida será:
Tipo de garantia: {{TIPO_GARANTIA}}
6.2. Poderão ser utilizadas, conforme permitido em lei:
a) caução em dinheiro;
b) caução em bens;
c) fiança;
d) seguro-fiança;
e) título de capitalização;
f) cessão fiduciária de quotas de fundo de investimento;
g) ausência de garantia;
h) outra garantia permitida: {{GARANTIA_OUTRA_DESCRICAO}}.
6.3. Fica vedada a exigência cumulativa de mais de uma modalidade de garantia para o mesmo contrato, salvo hipóteses expressamente admitidas em lei.
6.4. Caso haja caução em dinheiro, o valor será de R\$ {{VALOR_CAUCAO}}, correspondente a {{QUANTIDADE_MESES_CAUCAO}} mês(es) de aluguel ou ao valor ajustado para a modalidade temporária.
6.5. A caução deverá ser restituída ao LOCATÁRIO ao final da locação, após a entrega das chaves e quitação das obrigações legítimas, líquidas, vencidas, exigíveis e comprovadas.
6.6. É vedada a retenção genérica, integral ou imotivada da caução sem apresentação de demonstrativo detalhado dos valores devidos.
7. DA ENTREGA DO IMÓVEL
7.1. O LOCADOR declara que entregará o imóvel em condições adequadas de uso, segurança, higiene, habitabilidade e funcionamento regular das instalações elétricas, hidráulicas, sanitárias, fechaduras, portas, janelas, móveis, equipamentos e utensílios existentes.
7.2. A entrega das chaves ocorrerá em {{DATA_ENTREGA_CHAVES}}, no endereço {{LOCAL_ENTREGA_CHAVES}}, ou por meio de acesso eletrônico, cofre de chaves, portaria ou outro método indicado no campo {{FORMA_ENTREGA_CHAVES}}.
7.3. O aluguel, diária ou preço de estadia somente será devido a partir da efetiva disponibilização do imóvel ao LOCATÁRIO, salvo se o atraso decorrer exclusivamente de culpa do LOCATÁRIO.
7.4. Caso o imóvel não seja entregue em condições adequadas de uso, o LOCATÁRIO poderá solicitar abatimento proporcional, reparo imediato, remarcação do início da estadia ou rescisão sem multa, conforme a gravidade da situação.
8. DA VISTORIA INICIAL
8.1. Antes da ocupação, deverá ser elaborado laudo de vistoria inicial, físico ou digital, acompanhado, sempre que possível, de fotos e vídeos.
8.2. O laudo deverá descrever o estado de conservação do imóvel, pintura, pisos, paredes, portas, janelas, vidros, fechaduras, instalações elétricas, hidráulicas, sanitárias, móveis, eletrodomésticos, utensílios, roupas de cama, equipamentos, controles, chaves, garagem e demais itens existentes.
8.3. O LOCATÁRIO poderá apresentar ressalvas ao laudo no prazo de {{PRAZO_RESSALVA_VISTORIA}} dias, contado do recebimento das chaves, check-in ou acesso ao imóvel.
8.4. As ressalvas enviadas pelo LOCATÁRIO por e-mail, aplicativo, plataforma digital ou sistema eletrônico integrarão este contrato para todos os fins.
8.5. Na ausência de vistoria inicial detalhada, não se presumirá que o imóvel foi entregue em perfeito estado, cabendo ao LOCADOR comprovar eventual dano atribuído ao LOCATÁRIO.
9. DO INVENTÁRIO DE MÓVEIS, UTENSÍLIOS E EQUIPAMENTOS
9.1. Esta cláusula é obrigatória para imóveis mobiliados, especialmente em locações por temporada, diárias ou plataforma digital.
9.2. O imóvel será entregue com os móveis, utensílios, eletrodomésticos e equipamentos descritos no Anexo de Inventário: {{ANEXO_INVENTARIO_MOVEIS}}.
9.3. O inventário deverá conter, sempre que possível:
a) descrição do item;
b) quantidade;
c) marca/modelo, quando aplicável;
d) estado de conservação;
e) fotos;
f) observações.
9.4. O LOCATÁRIO não será responsável por defeitos preexistentes, desgaste natural, mau funcionamento anterior, vícios ocultos ou itens já danificados no momento da entrega.
10. DAS OBRIGAÇÕES DO LOCADOR
10.1. São obrigações do LOCADOR:
a) entregar o imóvel em condições de uso;
b) garantir o uso pacífico do imóvel durante a locação;
c) responder por vícios, defeitos ocultos e problemas anteriores à locação;
d) realizar reparos estruturais e essenciais não causados pelo LOCATÁRIO;
e) fornecer informações claras sobre valores, regras, limitações e encargos;
f) disponibilizar comprovantes de despesas repassadas ao LOCATÁRIO;
g) respeitar a privacidade e a posse direta do LOCATÁRIO;
h) não ingressar no imóvel sem autorização, salvo emergência comprovada;
i) informar previamente regras condominiais, restrições de acesso, uso de áreas comuns, garagem, piscina, churrasqueira, academia e demais dependências;
j) manter o imóvel livre de débitos anteriores à locação, salvo ajuste expresso em contrário.
11. DAS OBRIGAÇÕES DO LOCATÁRIO
11.1. São obrigações do LOCATÁRIO:
a) pagar os valores contratados nos prazos ajustados;
b) utilizar o imóvel de forma regular, lícita e cuidadosa;
c) respeitar regras condominiais e normas de vizinhança;
d) comunicar imediatamente ao LOCADOR qualquer dano, defeito, vazamento, infiltração, falha elétrica, hidráulica ou situação de risco;
e) restituir o imóvel ao final da locação no estado em que recebeu, ressalvados desgaste natural, vícios ocultos e deteriorações não causadas pelo LOCATÁRIO;
f) não realizar alterações estruturais sem autorização;
g) não sublocar, ceder ou emprestar o imóvel a terceiros sem autorização, salvo se expressamente permitido;
h) informar a quantidade de ocupantes quando exigido pela modalidade contratada.
12. DOS OCUPANTES, HÓSPEDES E VISITANTES
12.1. A quantidade máxima de ocupantes será de {{QUANTIDADE_MAXIMA_OCUPANTES}} pessoa(s).
12.2. Os ocupantes autorizados são:
{{LISTA_OCUPANTES_AUTORIZADOS}}
12.3. Em locações por temporada, diárias ou plataforma digital, o LOCATÁRIO deverá respeitar o limite de ocupantes informado no anúncio, reserva ou contrato.
12.4. Visitantes poderão ser admitidos conforme as regras do condomínio, do imóvel e deste contrato, desde que não caracterizem ocupação excedente, sublocação ou uso indevido.
12.5. O LOCATÁRIO responderá por danos comprovadamente causados por seus ocupantes, visitantes ou pessoas por ele autorizadas a ingressar no imóvel, ressalvados desgaste natural e vícios preexistentes.
13. DAS REGRAS DE CONVIVÊNCIA E CONDOMÍNIO
13.1. O LOCATÁRIO declara ter ciência das regras aplicáveis ao imóvel, incluindo regulamento interno, convenção condominial, normas de segurança, silêncio, animais, garagem, piscina, churrasqueira, academia e áreas comuns, conforme documentos disponibilizados em {{ANEXO_REGRAS_CONDOMINIO}}.
13.2. O LOCADOR deverá informar previamente qualquer restrição relevante que possa afetar o uso do imóvel pelo LOCATÁRIO.
13.3. Multas condominiais somente poderão ser repassadas ao LOCATÁRIO se decorrerem de ato comprovadamente praticado por ele, seus ocupantes ou visitantes, após apresentação da notificação, do motivo da multa e possibilidade razoável de contestação.
14. DOS ANIMAIS DE ESTIMAÇÃO
14.1. A permanência de animais de estimação será:
{{PERMITE_ANIMAIS}}
14.2. Caso permitida, serão admitidos os seguintes animais:
{{DESCRICAO_ANIMAIS_PERMITIDOS}}
14.3. O LOCATÁRIO será responsável por danos comprovadamente causados pelos animais, ressalvado o desgaste natural do imóvel.
14.4. Eventuais restrições condominiais deverão ser informadas pelo LOCADOR antes da assinatura ou confirmação da reserva.
15. DAS CONTAS DE CONSUMO
15.1. Serão de responsabilidade do LOCATÁRIO, quando não incluídas no preço da estadia, as contas de consumo individualizadas referentes ao período de ocupação, tais como água, energia elétrica, gás, internet, TV, lavanderia, limpeza extra e demais serviços contratados.
15.2. Contas incluídas no valor da locação:
{{CONTAS_INCLUIDAS}}
15.3. Contas cobradas separadamente:
{{CONTAS_COBRADAS_SEPARADAMENTE}}
15.4. O LOCATÁRIO não responderá por débitos anteriores ao início da locação nem por débitos posteriores à entrega das chaves ou check-out.
15.5. Em locações por temporada, diárias ou plataforma digital, eventual cobrança excedente de consumo deverá estar previamente prevista e acompanhada de critério claro de apuração.
16. DO IPTU, TAXAS, SEGURO E CONDOMÍNIO
16.1. Na locação residencial de longo prazo, o pagamento de IPTU, condomínio ordinário, seguro contra incêndio e demais encargos somente poderá ser exigido do LOCATÁRIO se houver previsão expressa neste contrato.
16.2. Encargos de responsabilidade do LOCATÁRIO:
{{ENCARGOS_RESPONSABILIDADE_LOCATARIO}}
16.3. Encargos de responsabilidade do LOCADOR:
{{ENCARGOS_RESPONSABILIDADE_LOCADOR}}
16.4. Despesas extraordinárias de condomínio, obras estruturais, fundo de obras, reformas de fachada, instalação de equipamentos, valorização patrimonial, indenizações trabalhistas anteriores e fundo de reserva para despesas extraordinárias serão de responsabilidade do LOCADOR, salvo disposição legal diversa.
16.5. Em locações por temporada, diárias ou plataforma digital, presume-se que IPTU, condomínio ordinário e despesas fixas estejam incluídos no preço total, salvo previsão expressa e destacada em contrário.
17. DA MANUTENÇÃO, REPAROS E VÍCIOS OCULTOS
17.1. O LOCADOR será responsável por reparos estruturais, vícios ocultos, defeitos anteriores à locação, problemas de instalação elétrica ou hidráulica preexistentes, infiltrações, vazamentos internos não causados pelo LOCATÁRIO, problemas em telhado, laje, fundação, fachada, rede principal de água, esgoto, gás e energia.
17.2. O LOCATÁRIO será responsável apenas por danos decorrentes de mau uso comprovado por ele, seus ocupantes, visitantes ou pessoas por ele autorizadas.
17.3. Em caso de urgência, risco à saúde, segurança, habitabilidade ou agravamento do dano, e havendo omissão do LOCADOR após comunicação, o LOCATÁRIO poderá providenciar reparo necessário e solicitar reembolso, mediante comprovação por notas, recibos, fotos, vídeos ou orçamentos.
18. DO USO PACÍFICO E DA PRIVACIDADE
18.1. O LOCADOR deverá garantir ao LOCATÁRIO o uso pacífico, privado e regular do imóvel durante toda a locação.
18.2. O LOCADOR, administrador, corretor, prestador de serviço ou terceiro somente poderá ingressar no imóvel mediante autorização prévia do LOCATÁRIO, salvo emergência comprovada.
18.3. É vedado ao LOCADOR trocar fechaduras, interromper serviços essenciais, retirar bens, acessar o imóvel sem autorização, constranger o LOCATÁRIO ou adotar qualquer medida de autotutela.
19. DO CHECK-IN E CHECK-OUT
19.1. Esta cláusula aplica-se especialmente às locações por temporada, diárias e plataforma digital.
19.2. O check-in ocorrerá em {{DATA_CHECKIN}} a partir de {{HORARIO_CHECKIN}}.
19.3. O check-out ocorrerá em {{DATA_CHECKOUT}} até {{HORARIO_CHECKOUT}}.
19.4. A forma de acesso será:
{{FORMA_ACESSO_IMOVEL}}
19.5. Atrasos de check-in causados pelo LOCADOR, falhas de acesso, ausência de chaves, código incorreto, portaria não autorizada ou indisponibilidade do imóvel poderão gerar abatimento proporcional, reembolso de despesas comprovadas ou cancelamento sem multa, conforme a gravidade.
19.6. Atraso injustificado no check-out pelo LOCATÁRIO poderá gerar cobrança proporcional, desde que previamente prevista e razoável.
20. DA LIMPEZA
20.1. O imóvel será entregue ao LOCATÁRIO em adequado estado de limpeza, higiene e conservação.
20.2. Taxa de limpeza:
Valor: R\$ {{VALOR_TAXA_LIMPEZA}}
Incluída no preço total: {{TAXA_LIMPEZA_INCLUIDA}}
Cobrada separadamente: {{TAXA_LIMPEZA_SEPARADA}}
20.3. A taxa de limpeza, quando existente, deverá estar informada previamente ao LOCATÁRIO.
20.4. A cobrança de limpeza extra somente será permitida quando houver sujeira excessiva, descarte inadequado de resíduos ou uso anormal do imóvel, devidamente comprovado.
21. DO CANCELAMENTO EM TEMPORADA, DIÁRIAS E PLATAFORMA DIGITAL
21.1. A política de cancelamento aplicável será:
{{POLITICA_CANCELAMENTO}}
21.2. Em caso de cancelamento pelo LOCADOR sem culpa do LOCATÁRIO, este terá direito à devolução integral dos valores pagos, inclusive taxas, sem prejuízo de eventual indenização por perdas comprovadas.
21.3. Em caso de cancelamento pelo LOCATÁRIO, aplicar-se-á a política previamente informada, desde que clara, proporcional e aceita antes da contratação.
21.4. Caso o imóvel esteja indisponível, inseguro, diferente do anunciado, sem condições de uso, com vício grave ou com restrição relevante não informada previamente, o LOCATÁRIO poderá requerer cancelamento sem multa, abatimento proporcional ou realocação equivalente, conforme o caso.
22. DA RESCISÃO ANTECIPADA NA LOCAÇÃO DE LONGO PRAZO
22.1. O LOCATÁRIO poderá devolver o imóvel antes do término do prazo contratual, mediante comunicação prévia ao LOCADOR.
22.2. A multa rescisória, quando aplicável, será calculada proporcionalmente ao período restante do contrato.
22.3. Multa contratual base: {{MULTA_RESCISORIA_BASE}}
22.4. Fórmula de cálculo proporcional:
Multa devida = {{MULTA_RESCISORIA_BASE}} x meses restantes / prazo total contratado.
22.5. O LOCATÁRIO ficará dispensado da multa nas hipóteses legais, incluindo transferência pelo empregador para localidade diversa, mediante notificação prévia, bem como em caso de descumprimento grave pelo LOCADOR, vício grave no imóvel, perda de habitabilidade ou impossibilidade de uso não causada pelo LOCATÁRIO.
23. DA DEVOLUÇÃO DO IMÓVEL
23.1. Ao final da locação, o LOCATÁRIO deverá restituir o imóvel no estado em que recebeu, ressalvados desgaste natural, ação do tempo, vícios ocultos, defeitos preexistentes e deteriorações não causadas pelo LOCATÁRIO.
23.2. A vistoria final deverá comparar o estado do imóvel com a vistoria inicial e com as ressalvas apresentadas pelo LOCATÁRIO.
23.3. Não poderão ser cobrados do LOCATÁRIO:
a) pintura integral automática, salvo se justificadamente necessária por dano superior ao desgaste natural;
b) reforma geral;
c) modernização do imóvel;
d) substituição de itens depreciados pelo tempo;
e) reparos de vícios preexistentes;
f) despesas sem comprovação;
g) danos genéricos não individualizados.
23.4. Eventuais danos deverão ser descritos de forma específica, acompanhados de fotos, vídeos, orçamento ou nota fiscal.
23.5. Em caso de divergência, o LOCATÁRIO poderá apresentar contestação, fotos, vídeos, laudo próprio, orçamentos e demais provas.
24. DA ENTREGA DAS CHAVES
24.1. A entrega das chaves ocorrerá em {{DATA_DEVOLUCAO_CHAVES}}, por meio de {{FORMA_DEVOLUCAO_CHAVES}}.
24.2. A recusa injustificada do LOCADOR em receber as chaves não autorizará a cobrança automática de novos aluguéis, diárias ou encargos, desde que o LOCATÁRIO comprove a tentativa de devolução e a desocupação do imóvel.
24.3. Após a entrega das chaves ou check-out, cessará a cobrança de aluguel, diária e encargos ordinários vinculados à posse, ressalvadas obrigações vencidas anteriormente ou danos comprovados.
25. DA CAUÇÃO, DEPÓSITO DE SEGURANÇA OU RETENÇÃO PREVENTIVA
25.1. Em locações por temporada, diárias ou plataforma digital, poderá ser previsto depósito de segurança no valor de R\$ {{VALOR_DEPOSITO_SEGURANCA}}.
25.2. O depósito de segurança não se confunde com multa automática e somente poderá ser utilizado para cobrir danos reais, específicos e comprovados, ou débitos previstos neste contrato.
25.3. Prazo para devolução do depósito: {{PRAZO_DEVOLUCAO_DEPOSITO}} dias após check-out, entrega das chaves ou conclusão da vistoria final.
25.4. Havendo retenção parcial ou total, o LOCADOR deverá apresentar demonstrativo detalhado, fotos, vídeos, orçamentos ou notas fiscais.
26. DAS BENFEITORIAS
26.1. Benfeitorias necessárias realizadas pelo LOCATÁRIO para conservar o imóvel, evitar deterioração, preservar habitabilidade ou segurança serão indenizáveis quando indispensáveis e comprovadas.
26.2. Benfeitorias úteis dependerão de autorização prévia do LOCADOR para eventual indenização.
26.3. Benfeitorias meramente estéticas ou voluptuárias não serão indenizáveis, salvo acordo expresso, podendo o LOCATÁRIO removê-las se a retirada não causar dano ao imóvel.
27. DO DIREITO DE PREFERÊNCIA
27.1. Esta cláusula aplica-se principalmente às locações residenciais de longo prazo.
27.2. Em caso de venda, promessa de venda, cessão ou dação em pagamento do imóvel, o LOCADOR deverá comunicar formalmente o LOCATÁRIO, informando preço, condições de pagamento, prazo, comissão, ônus e demais elementos da negociação.
27.3. O LOCATÁRIO poderá exercer direito de preferência em igualdade de condições com terceiros, nos termos da legislação aplicável.
28. DA ALIENAÇÃO DO IMÓVEL
28.1. A venda ou transferência do imóvel não prejudicará automaticamente os direitos do LOCATÁRIO.
28.2. O LOCADOR deverá informar ao adquirente a existência da locação e comunicar ao LOCATÁRIO os dados do novo proprietário ou responsável pelo recebimento dos pagamentos.
28.3. O LOCATÁRIO não responderá por pagamento feito ao antigo LOCADOR enquanto não for formalmente comunicado da transferência e dos novos dados de pagamento.
29. DA PROTEÇÃO DE DADOS PESSOAIS
29.1. Os dados pessoais das partes serão utilizados exclusivamente para análise cadastral, elaboração, assinatura, execução, gestão, cobrança, cumprimento legal e arquivamento deste contrato.
29.2. Dados do LOCATÁRIO não poderão ser compartilhados com terceiros estranhos à relação contratual, salvo autorização, obrigação legal ou necessidade operacional vinculada à locação.
29.3. O sistema de locação, imobiliária, administradora ou LOCADOR deverão adotar medidas razoáveis de segurança para proteção dos dados pessoais.
30. DAS COMUNICAÇÕES
30.1. As comunicações entre as partes poderão ocorrer por e-mail, telefone, aplicativo de mensagens, plataforma digital, sistema eletrônico ou outro meio informado neste contrato.
30.2. Dados de contato do LOCADOR:
E-mail: {{LOCADOR_EMAIL}}
Telefone/WhatsApp: {{LOCADOR_TELEFONE}}
30.3. Dados de contato do LOCATÁRIO:
E-mail: {{LOCATARIO_EMAIL}}
Telefone/WhatsApp: {{LOCATARIO_TELEFONE}}
30.4. As notificações eletrônicas serão consideradas válidas quando enviadas aos contatos informados, salvo comunicação formal de alteração.
31. DA ASSINATURA ELETRÔNICA
31.1. As partes reconhecem a validade jurídica da assinatura eletrônica ou digital deste contrato, inclusive por plataforma de assinatura, aceite eletrônico, biometria, registro de IP, token, e-mail, SMS, WhatsApp ou outro meio idôneo de identificação.
31.2. O contrato gerado em PDF e assinado eletronicamente produzirá os mesmos efeitos de documento físico assinado manualmente, desde que permita identificar os signatários e preservar a integridade do documento.
32. DA COBRANÇA, MULTAS E INADIMPLEMENTO
32.1. O LOCATÁRIO somente poderá ser cobrado por valores líquidos, vencidos, exigíveis, previstos contratualmente e devidamente comprovados.
32.2. Multas, juros e correção monetária deverão observar proporcionalidade, razoabilidade e boa-fé.
32.3. Encargos por atraso:
Multa por atraso: {{MULTA_ATRASO_PERCENTUAL}}%
Juros de mora: {{JUROS_MORA_PERCENTUAL}}% ao mês
Correção monetária: {{INDICE_CORRECAO_ATRASO}}
32.4. É vedada a negativação, protesto ou cobrança judicial de valores controvertidos sem prévia comunicação e demonstração detalhada do débito.
33. DA IMPOSSIBILIDADE DE USO DO IMÓVEL
33.1. Se o imóvel se tornar total ou parcialmente impróprio para uso por motivo não imputável ao LOCATÁRIO, este poderá solicitar abatimento proporcional, reparo, realocação equivalente ou rescisão sem multa, conforme a gravidade.
33.2. Se a impossibilidade for total, grave ou prolongada, o LOCATÁRIO poderá rescindir o contrato sem penalidade, sem prejuízo de eventual indenização por danos comprovados.
34. DAS PLATAFORMAS DIGITAIS
34.1. Caso a locação tenha sido intermediada por plataforma digital, os dados da reserva serão:
Plataforma: {{NOME_PLATAFORMA}}
Número da reserva: {{NUMERO_RESERVA_PLATAFORMA}}
Anfitrião/Locador na plataforma: {{NOME_ANFITRIAO_PLATAFORMA}}
Hóspede/Locatário na plataforma: {{NOME_HOSPEDE_PLATAFORMA}}
Valor informado na plataforma: R\$ {{VALOR_PLATAFORMA}}
Taxas da plataforma: R\$ {{TAXAS_PLATAFORMA}}
Política de cancelamento da plataforma: {{POLITICA_CANCELAMENTO_PLATAFORMA}}
34.2. Na hipótese de conflito entre este contrato e as regras da plataforma, prevalecerá a disposição que melhor proteja o LOCATÁRIO, desde que não contrarie norma legal obrigatória.
34.3. O LOCADOR declara que o imóvel está apto para uso na modalidade contratada e que não há restrição legal, administrativa ou condominial previamente conhecida que impeça a estadia, salvo as seguintes restrições informadas expressamente:
{{RESTRICOES_CONDOMINIAIS_OU_LEGAIS}}
34.4. Caso exista proibição ou restrição condominial relevante não informada previamente, o LOCATÁRIO poderá cancelar a estadia sem multa e requerer devolução dos valores pagos.
35. DA PROIBIÇÃO DE CLÁUSULAS ABUSIVAS
35.1. Serão consideradas sem efeito cláusulas que imponham ao LOCATÁRIO obrigações desproporcionais, renúncia genérica de direitos, cobrança sem comprovação, responsabilidade por vícios preexistentes, multas excessivas, cumulação indevida de garantias ou qualquer obrigação incompatível com a legislação aplicável.
35.2. A nulidade ou inexigibilidade de uma cláusula não invalidará o restante do contrato.
36. DA SOLUÇÃO DE CONFLITOS
36.1. As partes comprometem-se a tentar resolver divergências de forma amigável, por comunicação direta, negociação, mediação ou conciliação, antes da adoção de medidas judiciais, salvo urgência.
36.2. O LOCATÁRIO poderá contestar cobranças, apresentar provas, exigir reparos, requerer abatimentos, reembolsos ou rescisão quando cabível.
37. DO FORO
37.1. Para dirimir controvérsias decorrentes deste contrato, fica eleito o foro da comarca de {{FORO_COMARCA}}, Estado de {{FORO_ESTADO}}, salvo disposição legal que assegure foro mais favorável ao LOCATÁRIO.
E, por estarem justas e contratadas, as partes assinam eletronicamente o presente instrumento.
Local: {{LOCAL_ASSINATURA}}
Data: {{DATA_ASSINATURA}}
LOCADOR:
{{LOCADOR_NOME}}
CPF/CNPJ: {{LOCADOR_CPF_CNPJ}}
LOCATÁRIO/INQUILINO:
{{LOCATARIO_NOME}}
CPF/CNPJ: {{LOCATARIO_CPF_CNPJ}}
TESTEMUNHA 1:
{{TESTEMUNHA1_NOME}}
CPF: {{TESTEMUNHA1_CPF}}
TESTEMUNHA 2:
{{TESTEMUNHA2_NOME}}
CPF: {{TESTEMUNHA2_CPF}}
''';

final _placeholderPattern = RegExp(r'\{\{([A-Z0-9_]+)\}\}');

/// Substitui todos os placeholders do template pelos valores do mapa.
/// Chaves ausentes recebem [missingValue] (padrão: sublinhado).
String applyRentalLeaseContractTemplate(
  Map<String, String> values, {
  String missingValue = '________________',
}) {
  return rentalLeaseContractTemplate.replaceAllMapped(_placeholderPattern, (match) {
    final key = match.group(1)!;
    final value = values[key];
    if (value == null || value.trim().isEmpty) {
      return missingValue;
    }
    return value.trim();
  });
}

/// Lista única de placeholders presentes no template.
List<String> get rentalLeaseContractPlaceholderKeys {
  final keys = <String>{};
  for (final m in _placeholderPattern.allMatches(rentalLeaseContractTemplate)) {
    keys.add(m.group(1)!);
  }
  return keys.toList()..sort();
}
