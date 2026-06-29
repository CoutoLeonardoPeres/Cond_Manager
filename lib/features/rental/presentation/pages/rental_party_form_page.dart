import 'dart:async';

import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/config/tenant_intake_form_config.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/domain/utils/tenant_intake_party_sync.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/dynamic_tenant_intake_form.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_contract_enums.dart';
import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RentalPartyFormPage extends ConsumerStatefulWidget {
  const RentalPartyFormPage({super.key, this.partyId});

  final String? partyId;

  bool get isEditing => partyId != null;

  @override
  ConsumerState<RentalPartyFormPage> createState() => _RentalPartyFormPageState();
}

class _RentalPartyFormPageState extends ConsumerState<RentalPartyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _intakeFormKey = GlobalKey<DynamicTenantIntakeFormState>();

  // Formulário simplificado (locador e demais)
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentController = TextEditingController();
  final _notesController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _rgNumberController = TextEditingController();
  final _rgIssuerController = TextEditingController();
  final _professionController = TextEditingController();
  late final AddressFields _addressFields;

  String _status = 'active';
  RentalPartyCategory _category = RentalPartyCategory.tenant;
  RentalMaritalStatus? _maritalStatus;
  bool _loading = false;
  bool _lookupLoading = false;
  String? _error;
  bool _loaded = false;
  RentalParty? _matchedParty;
  bool _blockSubmitForRestriction = false;
  Map<String, String> _intakeInitialValues = {};
  Timer? _lookupDebounce;

  bool get _usesIntakeForm => partyCategoryUsesIntakeForm(_category);

  @override
  void initState() {
    super.initState();
    _addressFields = AddressFields(
      zip: TextEditingController(),
      street: TextEditingController(),
      number: TextEditingController(),
      complement: TextEditingController(),
      neighborhood: TextEditingController(),
      city: TextEditingController(),
      state: TextEditingController(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialCategoryFromRoute());
  }

  void _applyInitialCategoryFromRoute() {
    if (widget.isEditing || !mounted) return;
    final categoryParam = GoRouterState.of(context).uri.queryParameters['category'];
    if (categoryParam == null) return;
    setState(() => _category = RentalPartyCategory.fromValue(categoryParam));
  }

  @override
  void dispose() {
    _lookupDebounce?.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    _notesController.dispose();
    _nationalityController.dispose();
    _rgNumberController.dispose();
    _rgIssuerController.dispose();
    _professionController.dispose();
    _addressFields.zip.dispose();
    _addressFields.street.dispose();
    _addressFields.number.dispose();
    _addressFields.complement.dispose();
    _addressFields.neighborhood.dispose();
    _addressFields.city.dispose();
    _addressFields.state.dispose();
    super.dispose();
  }

  void _refreshIntakeForm(Map<String, String> values) {
    _intakeInitialValues = values;
    _intakeFormKey.currentState?.applyValues(values);
  }

  String? _lookupDocument() {
    if (_usesIntakeForm) {
      final values = _intakeFormKey.currentState?.collectValues() ?? {};
      final cpf = values['LOCATARIO_CPF']?.trim();
      return cpf != null && cpf.isNotEmpty ? cpf : null;
    }
    final doc = _documentController.text.trim();
    return doc.isEmpty ? null : doc;
  }

  String? _lookupPhone() {
    if (_usesIntakeForm) {
      final values = _intakeFormKey.currentState?.collectValues() ?? {};
      final phone = values['LOCATARIO_WHATSAPP']?.trim() ?? values['LOCATARIO_TELEFONE']?.trim();
      return phone != null && phone.isNotEmpty ? phone : null;
    }
    final phone = _phoneController.text.trim();
    return phone.isEmpty ? null : phone;
  }

  void _scheduleLookupParty() {
    if (widget.isEditing || _lookupLoading) return;
    _lookupDebounce?.cancel();
    _lookupDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) unawaited(_lookupParty());
    });
  }

  void _fillAddress(RentalParty p) {
    ClayMaskedField.setCep(_addressFields.zip, p.addressZip);
    _addressFields.street.text = p.addressStreet ?? '';
    _addressFields.number.text = p.addressNumber ?? '';
    _addressFields.complement.text = p.addressComplement ?? '';
    _addressFields.neighborhood.text = p.addressNeighborhood ?? '';
    _addressFields.city.text = p.addressCity ?? '';
    _addressFields.state.text = p.addressState ?? '';
  }

  void _fill(RentalParty p) {
    _fullNameController.text = p.fullName;
    _emailController.text = p.email ?? '';
    ClayMaskedField.setPhone(_phoneController, p.phone);
    ClayMaskedField.setCpf(_documentController, p.documentNumber);
    _notesController.text = p.notes ?? '';
    _nationalityController.text = p.nationality ?? '';
    _rgNumberController.text = p.rgNumber ?? '';
    _rgIssuerController.text = p.rgIssuer ?? '';
    _professionController.text = p.profession ?? '';
    _maritalStatus = RentalMaritalStatus.fromValue(p.maritalStatus);
    _status = p.status;
    _category = p.category;
    _fillAddress(p);
    _refreshIntakeForm(partyToIntakeFieldValues(p));
    _loaded = true;
    _matchedParty = p.isRentalRestricted ? p : null;
    _blockSubmitForRestriction = !widget.isEditing && p.isRentalRestricted;
  }

  Future<void> _lookupParty() async {
    if (widget.isEditing || _lookupLoading) return;

    final documentNumber = _lookupDocument();
    final phone = _lookupPhone();
    if (documentNumber == null && phone == null) return;

    final companyId = ref.read(currentProfileProvider).value?.companyId;
    if (companyId == null) return;

    setState(() => _lookupLoading = true);

    final result = await ref.read(rentalRepositoryProvider).findPartyByDocumentOrPhone(
          companyId: companyId,
          documentNumber: documentNumber,
          phone: phone,
          excludePartyId: widget.partyId,
        );

    if (!mounted) return;

    result.when(
      success: (party) {
        setState(() {
          _lookupLoading = false;
          _matchedParty = party;
          _blockSubmitForRestriction = party != null && party.isRentalRestricted;
        });
        if (party != null) {
          _applyPartyToForm(party);
        }
      },
      failure: (_) => setState(() {
        _lookupLoading = false;
        _matchedParty = null;
        _blockSubmitForRestriction = false;
      }),
    );
  }

  void _applyPartyToForm(RentalParty party) {
    final intakeValues = partyToIntakeFieldValues(party);
    setState(() {
      if (!_usesIntakeForm) {
        _fullNameController.text = party.fullName;
        _emailController.text = party.email ?? '';
        ClayMaskedField.setPhone(_phoneController, party.phone);
        ClayMaskedField.setCpf(_documentController, party.documentNumber);
        _fillAddress(party);
        _nationalityController.text = party.nationality ?? '';
        _rgNumberController.text = party.rgNumber ?? '';
        _rgIssuerController.text = party.rgIssuer ?? '';
        _professionController.text = party.profession ?? '';
        _maritalStatus = RentalMaritalStatus.fromValue(party.maritalStatus);
      } else {
        _intakeInitialValues = intakeValues;
      }
      _notesController.text = party.notes ?? '';
      _category = party.category;
      _status = party.status;
    });
    if (_usesIntakeForm) {
      _intakeFormKey.currentState?.applyValues(intakeValues);
    }
  }

  RentalPartyInput _buildSimpleInput(String companyId) => RentalPartyInput(
        companyId: companyId,
        fullName: _fullNameController.text.trim(),
        category: _category,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        documentNumber:
            _documentController.text.trim().isEmpty ? null : _documentController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        status: _status,
        addressStreet: _addressFields.street.text.trim().isEmpty
            ? null
            : _addressFields.street.text.trim(),
        addressNumber: _addressFields.number.text.trim().isEmpty
            ? null
            : _addressFields.number.text.trim(),
        addressComplement: _addressFields.complement.text.trim().isEmpty
            ? null
            : _addressFields.complement.text.trim(),
        addressNeighborhood: _addressFields.neighborhood.text.trim().isEmpty
            ? null
            : _addressFields.neighborhood.text.trim(),
        addressCity:
            _addressFields.city.text.trim().isEmpty ? null : _addressFields.city.text.trim(),
        addressState:
            _addressFields.state.text.trim().isEmpty ? null : _addressFields.state.text.trim(),
        addressZip:
            _addressFields.zip.text.trim().isEmpty ? null : _addressFields.zip.text.trim(),
        nationality: _category == RentalPartyCategory.landlord &&
                _nationalityController.text.trim().isNotEmpty
            ? _nationalityController.text.trim()
            : null,
        rgNumber: _category == RentalPartyCategory.landlord &&
                _rgNumberController.text.trim().isNotEmpty
            ? _rgNumberController.text.trim()
            : null,
        rgIssuer: _category == RentalPartyCategory.landlord &&
                _rgIssuerController.text.trim().isNotEmpty
            ? _rgIssuerController.text.trim()
            : null,
        profession: _category == RentalPartyCategory.landlord &&
                _professionController.text.trim().isNotEmpty
            ? _professionController.text.trim()
            : null,
        maritalStatus:
            _category == RentalPartyCategory.landlord ? _maritalStatus?.value : null,
      );

  RentalPartyInput? _buildInput(String companyId) {
    if (_usesIntakeForm) {
      final intakeState = _intakeFormKey.currentState;
      if (intakeState == null || !intakeState.validateForSave()) return null;
      return partyInputFromIntakeValues(
        companyId: companyId,
        values: intakeState.collectValues(),
        category: _category,
        status: _status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }
    if (!_formKey.currentState!.validate()) return null;
    return _buildSimpleInput(companyId);
  }

  Future<void> _submit() async {
    if (_blockSubmitForRestriction) {
      setState(() => _error = 'Esta pessoa possui restrição de locação e não pode ser cadastrada novamente.');
      return;
    }

    if (!widget.isEditing && _matchedParty != null && !_usesIntakeForm) {
      setState(() => _error = 'Pessoa já cadastrada. Use "Editar cadastro" para atualizar os dados.');
      return;
    }

    final companyId = ref.read(currentProfileProvider).value?.companyId;
    if (companyId == null) {
      setState(() => _error = 'Empresa não identificada.');
      return;
    }

    final input = _buildInput(companyId);
    if (input == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(rentalRepositoryProvider);

    if (widget.isEditing) {
      final result = await repo.updateParty(widget.partyId!, input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalPartiesListProvider);
          ref.invalidate(rentalPartyDetailProvider(widget.partyId!));
          ref.invalidate(rentalGanttLeasesProvider);
          ref.invalidate(rentalGanttBookingsProvider);
          ref.invalidate(rentalLeasesListProvider);
          ref.invalidate(rentalBookingsListProvider);
          context.go(resolveReturnPath(context, fallback: '/rental/parties'));
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final result = await repo.createParty(input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalPartiesListProvider);
          context.go(resolveReturnPath(context, fallback: '/rental/parties'));
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    }
  }

  Widget? _buildLookupBanner() {
    final party = _matchedParty;
    if (party == null || widget.isEditing) return null;

    if (party.isRentalRestricted) {
      return ClaySurface(
        depth: ClayDepth.pressed,
        color: ClayTokens.error.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.block_rounded, color: ClayTokens.error, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Restrição de locação',
                    style: TextStyle(fontWeight: FontWeight.w800, color: ClayTokens.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${party.fullName} possui restrição por histórico como inquilino/locatário.'),
            if (party.restrictionReason != null && party.restrictionReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Motivo: ${party.restrictionReason}',
                style: const TextStyle(fontSize: 13, color: ClayTokens.textSecondary),
              ),
            ],
          ],
        ),
      );
    }

    return ClaySurface(
      depth: ClayDepth.pressed,
      color: ClayTokens.warning.withValues(alpha: 0.12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_search_rounded, color: ClayTokens.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pessoa já cadastrada: ${party.fullName}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => context.go('/rental/parties/${party.id}/edit'),
                child: const Text('Editar cadastro'),
              ),
              TextButton(
                onPressed: () => _applyPartyToForm(party),
                child: const Text('Carregar dados'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFields(int columns) {
    return FormGridSection(
      title: 'Cadastro',
      columns: columns,
      items: [
        FormGridField(
          child: ClayDropdownField<RentalPartyCategory>(
            label: 'Categoria *',
            value: _category,
            items: RentalPartyCategory.values,
            itemLabel: (c) => c.label,
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
        ),
        FormGridField(
          child: ClayDropdownField<String>(
            label: 'Status',
            value: _status,
            items: const ['active', 'inactive'],
            itemLabel: (s) => s == 'active' ? 'Ativo' : 'Inativo',
            onChanged: (v) => setState(() => _status = v ?? 'active'),
          ),
        ),
      ],
    );
  }

  Widget _buildSimplePartyForm(int columns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormGridSection(
          title: 'Identificação',
          columns: columns,
          items: [
            FormGridField(
              child: ClayMaskedField.cpf(
                controller: _documentController,
                label: 'CPF',
                onComplete: () async => _scheduleLookupParty(),
              ),
            ),
            FormGridField(
              child: ClayMaskedField.phone(
                controller: _phoneController,
                label: 'Telefone',
                onComplete: () async => _scheduleLookupParty(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormGridSection(
          title: 'Dados pessoais',
          columns: columns,
          items: [
            FormGridField(
              child: ClayTextField(
                controller: _fullNameController,
                label: 'Nome completo *',
                validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _emailController,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AddressFormSection(title: 'Endereço', fields: _addressFields),
        if (_category == RentalPartyCategory.landlord) ...[
          const SizedBox(height: 16),
          _buildLandlordContractSection(columns),
        ],
      ],
    );
  }

  Widget _buildLandlordContractSection(int columns) {
    return FormGridSection(
      title: 'Dados para contrato',
      columns: columns,
      items: [
        FormGridField(
          child: ClayTextField(
            controller: _nationalityController,
            label: 'Nacionalidade',
          ),
        ),
        FormGridField(
          child: ClayTextField(
            controller: _rgNumberController,
            label: 'RG',
          ),
        ),
        FormGridField(
          child: ClayTextField(
            controller: _rgIssuerController,
            label: 'Órgão emissor',
          ),
        ),
        FormGridField(
          child: ClayTextField(
            controller: _professionController,
            label: 'Profissão',
          ),
        ),
        FormGridField(
          child: ClayDropdownField<RentalMaritalStatus?>(
            label: 'Estado civil',
            value: _maritalStatus,
            items: [null, ...RentalMaritalStatus.values],
            itemLabel: (s) => s?.label ?? '—',
            onChanged: (v) => setState(() => _maritalStatus = v),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      ref.watch(rentalPartyDetailProvider(widget.partyId!)).whenData((p) {
        if (!_loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) setState(() => _fill(p));
          });
        }
      });
    }

    final lookupBanner = _buildLookupBanner();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : formColumnsForWidth(constraints.maxWidth);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ClaySurface(
                      depth: ClayDepth.raised,
                      radius: ClayTokens.radiusFull,
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        onPressed: () =>
                            context.go(resolveReturnPath(context, fallback: '/rental/parties')),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Editar pessoa' : 'Nova pessoa',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _usesIntakeForm
                      ? 'Preencha CPF ou telefone no formulário — ao completar o campo, os dados são buscados e preenchidos automaticamente.'
                      : 'Cadastre dados de locadores e demais categorias.',
                  style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                ),
                if (_lookupLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (lookupBanner != null) ...[
                  const SizedBox(height: 16),
                  lookupBanner,
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  ClaySurface(
                    depth: ClayDepth.pressed,
                    color: ClayTokens.error.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(14),
                    child: Text(_error!, style: const TextStyle(color: ClayTokens.error)),
                  ),
                ],
                const SizedBox(height: 20),
                _buildAdminFields(columns),
                const SizedBox(height: 16),
                if (_usesIntakeForm)
                  DynamicTenantIntakeForm(
                    key: _intakeFormKey,
                    definition: defaultTenantIntakeFormDefinition,
                    initialValues: _intakeInitialValues,
                    showSubmitButton: false,
                    relaxRequiredValidation: true,
                    onIdentityLookup: widget.isEditing ? null : _scheduleLookupParty,
                    onSubmit: (_) async {},
                  ) else
                  _buildSimplePartyForm(columns),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Observações internas',
                  columns: columns,
                  items: [
                    FormGridField(
                      span: columns,
                      child: ClayTextField(
                        controller: _notesController,
                        label: 'Observações (uso interno)',
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: columns >= 3 ? 220 : double.infinity,
                    child: ClayButton(
                      label: widget.isEditing ? 'Salvar' : 'Cadastrar',
                      icon: Icons.save_rounded,
                      isLoading: _loading,
                      onPressed: (_loading || _blockSubmitForRestriction) ? null : _submit,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
