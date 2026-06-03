import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/providers/domain/entities/service_provider.dart';
import 'package:cond_manager/features/providers/presentation/providers/service_provider_providers.dart';
import 'package:cond_manager/features/providers/presentation/widgets/service_specialties_selector.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/provider_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProviderFormPage extends ConsumerStatefulWidget {
  const ProviderFormPage({
    super.key,
    this.providerId,
    this.initialCondominiumId,
    this.initialServiceType,
  });

  final String? providerId;
  final String? initialCondominiumId;
  final ServiceType? initialServiceType;

  bool get isEditing => providerId != null;

  @override
  ConsumerState<ProviderFormPage> createState() => _ProviderFormPageState();
}

class _ProviderFormPageState extends ConsumerState<ProviderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _legalNameController = TextEditingController();
  final _tradeNameController = TextEditingController();
  final _documentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _notesController = TextEditingController();

  Condominium? _condominium;
  ProviderType _providerType = ProviderType.outsourced;
  String _documentType = 'cnpj';
  EntityStatus _status = EntityStatus.active;
  Set<ServiceType> _specialties = {};
  String? _specialtiesError;
  bool _isLoading = false;
  String? _error;
  bool _loaded = false;
  bool _addressCepLoading = false;

  late final AddressFields _addressFields;
  late final AddressCepAutofill _addressCepAutofill;

  @override
  void initState() {
    super.initState();
    if (widget.initialServiceType != null) {
      _specialties = {widget.initialServiceType!};
    }
    _addressFields = AddressFields(
      zip: _zipController,
      street: _streetController,
      number: _numberController,
      complement: _complementController,
      neighborhood: _neighborhoodController,
      city: _cityController,
      state: _stateController,
    );
    _addressCepAutofill = AddressCepAutofill(
      _addressFields,
      onLoadingChanged: (v) => setState(() => _addressCepLoading = v),
      onNotFound: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CEP não encontrado.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
    _addressCepAutofill.attach();
  }

  @override
  void dispose() {
    _addressCepAutofill.detach();
    _legalNameController.dispose();
    _tradeNameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _fillFromProvider(ServiceProvider p, List<Condominium> condos) {
    _legalNameController.text = p.legalName;
    _tradeNameController.text = p.tradeName ?? '';
    _documentType = p.documentType;
    ClayMaskedField.setDocument(
      _documentController,
      p.documentNumber,
      isCnpj: _documentType == 'cnpj',
    );
    _providerType = p.providerType;
    _status = p.status;
    _specialties = Set<ServiceType>.from(p.specialties);
    ClayMaskedField.setPhone(_phoneController, p.phones.isNotEmpty ? p.phones.first : null);
    _emailController.text = p.emails.isNotEmpty ? p.emails.first : '';
    _addressCepAutofill.pause();
    ClayMaskedField.setCep(_zipController, p.zipCode);
    _streetController.text = p.street ?? '';
    _numberController.text = p.number ?? '';
    _complementController.text = p.complement ?? '';
    _neighborhoodController.text = p.neighborhood ?? '';
    _cityController.text = p.city ?? '';
    _stateController.text = p.state ?? '';
    _addressCepAutofill.resume();
    _notesController.text = p.notes ?? '';
    for (final c in condos) {
      if (c.id == p.condominiumId) {
        _condominium = c;
        break;
      }
    }
    _loaded = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_condominium == null) {
      setState(() => _error = 'Selecione o condomínio.');
      return;
    }
    if (_specialties.isEmpty) {
      setState(() => _specialtiesError = 'Selecione ao menos uma área de serviço.');
      return;
    }
    setState(() {
      _specialtiesError = null;
      _isLoading = true;
      _error = null;
    });

    final repo = ref.read(serviceProviderRepositoryProvider);
    final phones = [_phoneController.text.trim()];
    final emails = [_emailController.text.trim()];

    if (widget.isEditing) {
      final input = ServiceProviderUpdateInput(
        providerType: _providerType,
        documentType: _documentType,
        documentNumber: _documentController.text,
        legalName: _legalNameController.text,
        tradeName: _tradeNameController.text,
        specialties: _specialties.toList(),
        phones: phones,
        emails: emails,
        street: _streetController.text,
        number: _numberController.text,
        complement: _complementController.text,
        neighborhood: _neighborhoodController.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipController.text,
        status: _status,
        notes: _notesController.text,
      );
      final result = await repo.update(widget.providerId!, input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(serviceProvidersListProvider);
          ref.invalidate(serviceProviderDetailProvider(widget.providerId!));
          ref.invalidate(workOrderProviderPickerProvider);
          context.go(resolveReturnPath(context, fallback: '/providers'));
        },
        failure: (e) => setState(() {
          _isLoading = false;
          _error = e.message;
        }),
      );
    } else {
      final input = ServiceProviderCreateInput(
        condominiumId: _condominium!.id,
        providerType: _providerType,
        documentType: _documentType,
        documentNumber: _documentController.text,
        legalName: _legalNameController.text,
        tradeName: _tradeNameController.text,
        specialties: _specialties.toList(),
        phones: phones,
        emails: emails,
        street: _streetController.text,
        number: _numberController.text,
        complement: _complementController.text,
        neighborhood: _neighborhoodController.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipController.text,
        status: _status,
        notes: _notesController.text,
      );
      final result = await repo.create(input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(serviceProvidersListProvider);
          ref.invalidate(workOrderProviderPickerProvider);
          context.go(resolveReturnPath(context, fallback: '/providers'));
        },
        failure: (e) => setState(() {
          _isLoading = false;
          _error = e.message;
        }),
      );
    }
  }

  String get _returnPath => resolveReturnPath(context, fallback: '/providers');

  @override
  Widget build(BuildContext context) {
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final condos = condosAsync.value ?? const <Condominium>[];
    if (widget.isEditing) {
      final detailAsync = ref.watch(serviceProviderDetailProvider(widget.providerId!));
      detailAsync.whenData((p) {
        if (!_loaded && condos.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) {
              setState(() => _fillFromProvider(p, condos));
            }
          });
        } else if (!_loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) {
              setState(() => _fillFromProvider(p, condos));
            }
          });
        }
      });
      if (detailAsync.isLoading && !_loaded) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 3));
      }
      if (detailAsync.hasError && !_loaded) {
        return Center(
          child: Text('Erro: ${detailAsync.error}'),
        );
      }
    } else {
      if (_condominium == null && widget.initialCondominiumId != null && condos.isNotEmpty) {
        final match = condos.where((c) => c.id == widget.initialCondominiumId);
        if (match.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _condominium == null) {
              setState(() => _condominium = match.first);
            }
          });
        }
      } else if (_condominium == null && condos.length == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _condominium == null) {
            setState(() => _condominium = condos.first);
          }
        });
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = formColumnsForWidth(constraints.maxWidth);

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
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => context.go(_returnPath),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Editar prestador' : 'Novo prestador',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isEditing
                      ? 'Atualize os dados e as áreas de serviço em que o prestador atua.'
                      : 'Cadastre o prestador e marque todas as categorias de serviço aplicáveis.',
                  style: const TextStyle(color: ClayTokens.textSecondary),
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  ClaySurface(
                    depth: ClayDepth.pressed,
                    color: ClayTokens.error.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(14),
                    child: Text(_error!, style: const TextStyle(color: ClayTokens.error)),
                  ),
                  const SizedBox(height: 16),
                ],
                FormGridSection(
                  title: 'Condomínio e vínculo',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: condosAsync.isLoading
                          ? const LinearProgressIndicator()
                          : ClayDropdownField<Condominium>(
                              label: 'Condomínio *',
                              value: _condominium,
                              items: condos,
                              itemLabel: (c) => c.name,
                              onChanged: widget.isEditing
                                  ? null
                                  : (v) => setState(() => _condominium = v),
                            ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<ProviderType>(
                        label: 'Tipo de prestador *',
                        value: _providerType,
                        items: ProviderType.values,
                        itemLabel: (t) => t.label,
                        onChanged: (v) =>
                            setState(() => _providerType = v ?? ProviderType.outsourced),
                      ),
                    ),
                    if (widget.isEditing)
                      FormGridField(
                        child: ClayDropdownField<EntityStatus>(
                          label: 'Status *',
                          value: _status,
                          items: EntityStatus.values,
                          itemLabel: (s) => s.label,
                          onChanged: (v) => setState(() => _status = v ?? EntityStatus.active),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Identificação',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayDropdownField<String>(
                        label: 'Documento *',
                        value: _documentType,
                        items: const ['cpf', 'cnpj'],
                        itemLabel: (v) => v == 'cpf' ? 'CPF' : 'CNPJ',
                        onChanged: (v) => setState(() {
                          _documentType = v ?? 'cnpj';
                          ClayMaskedField.onDocumentTypeChanged(
                            _documentController,
                            isCnpj: _documentType == 'cnpj',
                          );
                        }),
                      ),
                    ),
                    FormGridField(
                      child: ClayMaskedField.document(
                        controller: _documentController,
                        isCnpj: _documentType == 'cnpj',
                        label: 'Número do documento *',
                        required: true,
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _legalNameController,
                        label: 'Razão social / nome *',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _tradeNameController,
                        label: 'Nome fantasia',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Áreas de serviço',
                  columns: 1,
                  items: [
                    FormGridField(
                      span: columns,
                      child: ServiceSpecialtiesSelector(
                        selected: _specialties,
                        errorText: _specialtiesError,
                        onChanged: (next) => setState(() {
                          _specialties = next;
                          _specialtiesError = null;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Contato',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayMaskedField.phone(
                        controller: _phoneController,
                        label: 'Telefone *',
                        required: true,
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _emailController,
                        label: 'E-mail *',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obrigatório';
                          if (!v.contains('@')) return 'E-mail inválido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                buildAddressFormSection(
                  title: 'Endereço (opcional)',
                  fields: _addressFields,
                  streetLabel: 'Logradouro',
                  cepLoading: _addressCepLoading,
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Observações',
                  columns: 1,
                  items: [
                    FormGridField(
                      span: columns,
                      child: ClayTextField(
                        controller: _notesController,
                        label: 'Observações',
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ClayButton(
                    label: widget.isEditing ? 'Salvar alterações' : 'Cadastrar prestador',
                    icon: Icons.save_rounded,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
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
