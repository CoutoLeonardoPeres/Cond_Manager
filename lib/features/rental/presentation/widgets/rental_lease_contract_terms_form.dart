import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_contract_enums.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';

/// Campos de garantia, reajuste, pagamento, uso e testemunhas do contrato.
class RentalLeaseContractTermsForm extends StatefulWidget {
  const RentalLeaseContractTermsForm({
    super.key,
    required this.columns,
    required this.listingMode,
    required this.onChanged,
    this.initial = RentalLeaseContractTerms.empty,
  });

  final int columns;
  final RentalListingMode listingMode;
  final RentalLeaseContractTerms initial;
  final ValueChanged<RentalLeaseContractTerms> onChanged;

  @override
  State<RentalLeaseContractTermsForm> createState() => _RentalLeaseContractTermsFormState();
}

class _RentalLeaseContractTermsFormState extends State<RentalLeaseContractTermsForm> {
  RentalGuaranteeType? _guaranteeType;
  RentalAdjustmentIndex? _adjustmentIndex;
  RentalPaymentMethod? _paymentMethod;
  RentalCancellationPolicy? _cancellationPolicy;
  String? _allowsPets;

  late final _guaranteeOther = TextEditingController();
  late final _adjustmentPeriod = TextEditingController();
  late final _pixKey = TextEditingController();
  late final _bankName = TextEditingController();
  late final _bankAgency = TextEditingController();
  late final _bankAccount = TextEditingController();
  late final _bankAccountType = TextEditingController();
  late final _bankHolder = TextEditingController();
  late final _bankHolderDoc = TextEditingController();
  late final _lateFee = TextEditingController();
  late final _interest = TextEditingController();
  late final _terminationPenalty = TextEditingController();
  late final _inspectionDays = TextEditingController();
  late final _keyDelivery = TextEditingController();
  late final _maxOccupants = TextEditingController();
  late final _petsDescription = TextEditingController();
  late final _seasonTotal = TextEditingController();
  late final _tenantCharges = TextEditingController();
  late final _landlordCharges = TextEditingController();
  late final _witness1Name = TextEditingController();
  late final _witness1Cpf = TextEditingController();
  late final _witness2Name = TextEditingController();
  late final _witness2Cpf = TextEditingController();

  bool get _isLongTerm =>
      widget.listingMode == RentalListingMode.longTerm ||
      widget.listingMode == RentalListingMode.corporate;

  @override
  void initState() {
    super.initState();
    _apply(widget.initial);
  }

  @override
  void didUpdateWidget(covariant RentalLeaseContractTermsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) _apply(widget.initial);
  }

  void _apply(RentalLeaseContractTerms t) {
    _guaranteeType = t.guaranteeType;
    _adjustmentIndex = t.adjustmentIndex;
    _paymentMethod = t.paymentMethod;
    _cancellationPolicy = t.cancellationPolicy;
    _allowsPets = t.allowsPets == null ? null : (t.allowsPets! ? 'sim' : 'nao');
    _guaranteeOther.text = t.guaranteeOtherDescription ?? '';
    _adjustmentPeriod.text = t.adjustmentPeriodMonths?.toString() ?? '';
    _pixKey.text = t.pixKey ?? '';
    _bankName.text = t.bankName ?? '';
    _bankAgency.text = t.bankAgency ?? '';
    _bankAccount.text = t.bankAccount ?? '';
    _bankAccountType.text = t.bankAccountType ?? '';
    _bankHolder.text = t.bankHolder ?? '';
    _bankHolderDoc.text = t.bankHolderDocument ?? '';
    _lateFee.text = t.lateFeePercent?.toString() ?? '';
    _interest.text = t.interestPercent?.toString() ?? '';
    _terminationPenalty.text = t.terminationPenaltyMonths?.toString() ?? '';
    _inspectionDays.text = t.inspectionObjectionDays?.toString() ?? '';
    _keyDelivery.text = t.keyDeliveryMethod ?? '';
    _maxOccupants.text = t.maxOccupants?.toString() ?? '';
    _petsDescription.text = t.petsDescription ?? '';
    _seasonTotal.text = t.seasonTotalAmount?.toString() ?? '';
    _tenantCharges.text = t.tenantCharges ?? '';
    _landlordCharges.text = t.landlordCharges ?? '';
    _witness1Name.text = t.witness1Name ?? '';
    _witness1Cpf.text = t.witness1Cpf ?? '';
    _witness2Name.text = t.witness2Name ?? '';
    _witness2Cpf.text = t.witness2Cpf ?? '';
  }

  @override
  void dispose() {
    for (final c in [
      _guaranteeOther,
      _adjustmentPeriod,
      _pixKey,
      _bankName,
      _bankAgency,
      _bankAccount,
      _bankAccountType,
      _bankHolder,
      _bankHolderDoc,
      _lateFee,
      _interest,
      _terminationPenalty,
      _inspectionDays,
      _keyDelivery,
      _maxOccupants,
      _petsDescription,
      _seasonTotal,
      _tenantCharges,
      _landlordCharges,
      _witness1Name,
      _witness1Cpf,
      _witness2Name,
      _witness2Cpf,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parseDouble(String text) {
    final v = double.tryParse(text.replaceAll(',', '.'));
    return v;
  }

  int? _parseInt(String text) {
    final v = int.tryParse(text.trim());
    return v;
  }

  void _notify() {
    widget.onChanged(
      RentalLeaseContractTerms(
        guaranteeType: _guaranteeType,
        guaranteeOtherDescription:
            _guaranteeOther.text.trim().isEmpty ? null : _guaranteeOther.text.trim(),
        adjustmentIndex: _adjustmentIndex,
        adjustmentPeriodMonths: _parseInt(_adjustmentPeriod.text),
        paymentMethod: _paymentMethod,
        pixKey: _pixKey.text.trim().isEmpty ? null : _pixKey.text.trim(),
        bankName: _bankName.text.trim().isEmpty ? null : _bankName.text.trim(),
        bankAgency: _bankAgency.text.trim().isEmpty ? null : _bankAgency.text.trim(),
        bankAccount: _bankAccount.text.trim().isEmpty ? null : _bankAccount.text.trim(),
        bankAccountType:
            _bankAccountType.text.trim().isEmpty ? null : _bankAccountType.text.trim(),
        bankHolder: _bankHolder.text.trim().isEmpty ? null : _bankHolder.text.trim(),
        bankHolderDocument:
            _bankHolderDoc.text.trim().isEmpty ? null : _bankHolderDoc.text.trim(),
        lateFeePercent: _parseDouble(_lateFee.text),
        interestPercent: _parseDouble(_interest.text),
        terminationPenaltyMonths: _parseInt(_terminationPenalty.text),
        inspectionObjectionDays: _parseInt(_inspectionDays.text),
        keyDeliveryMethod: _keyDelivery.text.trim().isEmpty ? null : _keyDelivery.text.trim(),
        maxOccupants: _parseInt(_maxOccupants.text),
        allowsPets: _allowsPets == null ? null : _allowsPets == 'sim',
        petsDescription:
            _petsDescription.text.trim().isEmpty ? null : _petsDescription.text.trim(),
        cancellationPolicy: _cancellationPolicy,
        seasonTotalAmount: _parseDouble(_seasonTotal.text),
        tenantCharges: _tenantCharges.text.trim().isEmpty ? null : _tenantCharges.text.trim(),
        landlordCharges:
            _landlordCharges.text.trim().isEmpty ? null : _landlordCharges.text.trim(),
        witness1Name: _witness1Name.text.trim().isEmpty ? null : _witness1Name.text.trim(),
        witness1Cpf: _witness1Cpf.text.trim().isEmpty ? null : _witness1Cpf.text.trim(),
        witness2Name: _witness2Name.text.trim().isEmpty ? null : _witness2Name.text.trim(),
        witness2Cpf: _witness2Cpf.text.trim().isEmpty ? null : _witness2Cpf.text.trim(),
      ),
    );
  }

  void _setStateNotify(VoidCallback fn) => setState(() {
        fn();
        _notify();
      });

  @override
  Widget build(BuildContext context) {
    final c = widget.columns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormGridSection(
          title: 'Garantia locatícia',
          columns: c,
          items: [
            FormGridField(
              child: ClayDropdownField<RentalGuaranteeType>(
                label: 'Tipo de garantia',
                value: _guaranteeType,
                items: RentalGuaranteeType.values,
                itemLabel: (e) => e.label,
                onChanged: (v) => _setStateNotify(() => _guaranteeType = v),
              ),
            ),
            if (_guaranteeType == RentalGuaranteeType.other)
              FormGridField(
                child: ClayTextField(
                  controller: _guaranteeOther,
                  label: 'Descrição da garantia',
                  onChanged: (_) => _notify(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLongTerm) ...[
          FormGridSection(
            title: 'Reajuste',
            columns: c,
            items: [
              FormGridField(
                child: ClayDropdownField<RentalAdjustmentIndex>(
                  label: 'Índice de reajuste',
                  value: _adjustmentIndex,
                  items: RentalAdjustmentIndex.values,
                  itemLabel: (e) => e.label,
                  onChanged: (v) => _setStateNotify(() => _adjustmentIndex = v),
                ),
              ),
              FormGridField(
                child: ClayTextField(
                  controller: _adjustmentPeriod,
                  label: 'Periodicidade (meses)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        FormGridSection(
          title: 'Pagamento',
          columns: c,
          items: [
            FormGridField(
              child: ClayDropdownField<RentalPaymentMethod>(
                label: 'Forma de pagamento',
                value: _paymentMethod,
                items: RentalPaymentMethod.values,
                itemLabel: (e) => e.label,
                onChanged: (v) => _setStateNotify(() => _paymentMethod = v),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _pixKey,
                label: 'Chave PIX',
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _bankName,
                label: 'Banco',
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _bankAgency,
                label: 'Agência',
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _bankAccount,
                label: 'Conta',
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _bankAccountType,
                label: 'Tipo de conta',
                hint: 'Corrente ou poupança',
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _bankHolder,
                label: 'Titular da conta',
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _bankHolderDoc,
                label: 'CPF/CNPJ do titular',
                onChanged: (_) => _notify(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_isLongTerm) ...[
          FormGridSection(
            title: 'Temporada / diárias',
            columns: c,
            items: [
              FormGridField(
                child: ClayTextField(
                  controller: _seasonTotal,
                  label: 'Valor total da temporada (R\$)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _notify(),
                ),
              ),
              FormGridField(
                child: ClayDropdownField<RentalCancellationPolicy>(
                  label: 'Política de cancelamento',
                  value: _cancellationPolicy,
                  items: RentalCancellationPolicy.values,
                  itemLabel: (e) => e.label,
                  onChanged: (v) => _setStateNotify(() => _cancellationPolicy = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        FormGridSection(
          title: 'Multas e encargos',
          columns: c,
          items: [
            FormGridField(
              child: ClayTextField(
                controller: _lateFee,
                label: 'Multa por atraso (%)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _interest,
                label: 'Juros de mora (% ao mês)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _notify(),
              ),
            ),
            if (_isLongTerm)
              FormGridField(
                child: ClayTextField(
                  controller: _terminationPenalty,
                  label: 'Multa rescisória (meses de aluguel)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _notify(),
                ),
              ),
            FormGridField(
              span: c,
              child: ClayTextField(
                controller: _tenantCharges,
                label: 'Encargos do locatário (IPTU, condomínio, água…)',
                maxLines: 2,
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              span: c,
              child: ClayTextField(
                controller: _landlordCharges,
                label: 'Encargos do locador',
                maxLines: 2,
                onChanged: (_) => _notify(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormGridSection(
          title: 'Uso do imóvel',
          columns: c,
          items: [
            FormGridField(
              child: ClayTextField(
                controller: _maxOccupants,
                label: 'Máximo de ocupantes',
                keyboardType: TextInputType.number,
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              child: ClayDropdownField<String>(
                label: 'Permite animais',
                value: _allowsPets,
                items: const ['sim', 'nao'],
                itemLabel: (v) => v == 'sim' ? 'Sim' : 'Não',
                onChanged: (v) => _setStateNotify(() => _allowsPets = v),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _inspectionDays,
                label: 'Prazo ressalva vistoria (dias)',
                keyboardType: TextInputType.number,
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _keyDelivery,
                label: 'Entrega / devolução de chaves',
                hint: 'Portaria, cofre, presencial…',
                onChanged: (_) => _notify(),
              ),
            ),
            if (_allowsPets == 'sim')
              FormGridField(
                span: c,
                child: ClayTextField(
                  controller: _petsDescription,
                  label: 'Regras para animais',
                  maxLines: 2,
                  onChanged: (_) => _notify(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FormGridSection(
          title: 'Testemunhas',
          columns: c,
          items: [
            FormGridField(
              child: ClayTextField(
                controller: _witness1Name,
                label: 'Testemunha 1 — nome',
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              child: ClayMaskedField.cpf(
                controller: _witness1Cpf,
                label: 'Testemunha 1 — CPF',
                onComplete: () async => _notify(),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _witness2Name,
                label: 'Testemunha 2 — nome',
                onChanged: (_) => _notify(),
              ),
            ),
            FormGridField(
              child: ClayMaskedField.cpf(
                controller: _witness2Cpf,
                label: 'Testemunha 2 — CPF',
                onComplete: () async => _notify(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
