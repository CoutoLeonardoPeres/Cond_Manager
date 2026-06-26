import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/condominium_route_prefix.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/domain/enums/rental_property_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RentalPropertyFormPage extends ConsumerStatefulWidget {
  const RentalPropertyFormPage({super.key, this.propertyId});

  final String? propertyId;

  bool get isEditing => propertyId != null;

  @override
  ConsumerState<RentalPropertyFormPage> createState() => _RentalPropertyFormPageState();
}

class _RentalPropertyFormPageState extends ConsumerState<RentalPropertyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _areaController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _maxGuestsController = TextEditingController();
  final _baseRentController = TextEditingController();
  final _baseDailyController = TextEditingController();
  final _depositController = TextEditingController();

  RentalPropertyType _propertyType = RentalPropertyType.apartment;
  RentalListingMode _listingMode = RentalListingMode.longTerm;
  Condominium? _condominium;
  RentalParty? _owner;
  String _status = 'active';
  bool _loading = false;
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _maxGuestsController.dispose();
    _baseRentController.dispose();
    _baseDailyController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  double? _parseDouble(String text) {
    final v = double.tryParse(text.replaceAll(',', '.'));
    return v != null && v > 0 ? v : null;
  }

  int? _parseInt(String text) {
    final v = int.tryParse(text.trim());
    return v != null && v > 0 ? v : null;
  }

  void _fill(RentalProperty p, List<Condominium> condos, List<RentalParty> parties) {
    _titleController.text = p.title;
    _codeController.text = p.code ?? '';
    _descriptionController.text = p.description ?? '';
    _streetController.text = p.addressStreet ?? '';
    _numberController.text = p.addressNumber ?? '';
    _neighborhoodController.text = p.addressNeighborhood ?? '';
    _cityController.text = p.addressCity ?? '';
    _stateController.text = p.addressState ?? '';
    _zipController.text = p.addressZip ?? '';
    if (p.areaSqm != null) _areaController.text = p.areaSqm.toString();
    if (p.bedrooms != null) _bedroomsController.text = p.bedrooms.toString();
    if (p.bathrooms != null) _bathroomsController.text = p.bathrooms.toString();
    if (p.maxGuests != null) _maxGuestsController.text = p.maxGuests.toString();
    if (p.baseRentAmount != null) _baseRentController.text = p.baseRentAmount.toString();
    if (p.baseDailyRate != null) _baseDailyController.text = p.baseDailyRate.toString();
    if (p.depositAmount != null) _depositController.text = p.depositAmount.toString();
    _propertyType = p.propertyType;
    _listingMode = p.listingMode;
    _status = p.status;
    for (final c in condos) {
      if (c.id == p.condominiumId) _condominium = c;
    }
    for (final party in parties) {
      if (party.id == p.ownerPartyId) _owner = party;
    }
    _loaded = true;
  }

  RentalPropertyInput _buildInput(String companyId) => RentalPropertyInput(
        companyId: companyId,
        title: _titleController.text.trim(),
        propertyType: _propertyType,
        listingMode: _listingMode,
        code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        condominiumId: _condominium?.id,
        ownerPartyId: _owner?.id,
        addressStreet: _streetController.text.trim().isEmpty ? null : _streetController.text.trim(),
        addressNumber: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
        addressNeighborhood:
            _neighborhoodController.text.trim().isEmpty ? null : _neighborhoodController.text.trim(),
        addressCity: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        addressState: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        addressZip: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
        areaSqm: _parseDouble(_areaController.text),
        bedrooms: _parseInt(_bedroomsController.text),
        bathrooms: _parseInt(_bathroomsController.text),
        maxGuests: _parseInt(_maxGuestsController.text),
        baseRentAmount: _parseDouble(_baseRentController.text),
        baseDailyRate: _parseDouble(_baseDailyController.text),
        depositAmount: _parseDouble(_depositController.text),
        status: _status,
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final companyId = ref.read(currentProfileProvider).value?.companyId;
    if (companyId == null) {
      setState(() => _error = 'Empresa não identificada.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(rentalRepositoryProvider);
    final input = _buildInput(companyId);

    if (widget.isEditing) {
      final result = await repo.updateProperty(widget.propertyId!, input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalPropertiesListProvider);
          ref.invalidate(rentalPropertyDetailProvider(widget.propertyId!));
          context.go(resolveReturnPath(context, fallback: '/rental/properties'));
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final result = await repo.createProperty(input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalPropertiesListProvider);
          context.go(resolveReturnPath(context, fallback: '/rental/properties'));
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final partiesAsync = ref.watch(rentalPartiesListProvider);
    final condos = condosAsync.value ?? const <Condominium>[];
    final parties = partiesAsync.value ?? const <RentalParty>[];

    if (widget.isEditing) {
      ref.watch(rentalPropertyDetailProvider(widget.propertyId!)).whenData((p) {
        if (!_loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) setState(() => _fill(p, condos, parties));
          });
        }
      });
    }

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
                            context.go(resolveReturnPath(context, fallback: '/rental/properties')),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Editar imóvel' : 'Novo imóvel',
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
                      ? 'Atualize dados, endereço e valores do imóvel.'
                      : 'Cadastre um imóvel para locação de longo ou curto prazo.',
                  style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                ),
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
                FormGridSection(
                  title: 'Identificação',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayTextField(
                        controller: _titleController,
                        label: 'Título *',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<RentalPropertyType>(
                        label: 'Tipo',
                        value: _propertyType,
                        items: RentalPropertyType.values,
                        itemLabel: (t) => t.label,
                        onChanged: (v) =>
                            setState(() => _propertyType = v ?? RentalPropertyType.apartment),
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<RentalListingMode>(
                        label: 'Modalidade',
                        value: _listingMode,
                        items: RentalListingMode.values,
                        itemLabel: (m) => m.label,
                        onChanged: (v) =>
                            setState(() => _listingMode = v ?? RentalListingMode.longTerm),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(controller: _codeController, label: 'Código'),
                    ),
                    FormGridField(
                      span: columns,
                      child: ClayTextField(
                        controller: _descriptionController,
                        label: 'Descrição',
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Vínculos',
                  columns: columns,
                  items: [
                    FormGridField(
                      span: 2,
                      child: condosAsync.when(
                        data: (list) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClayDropdownField<Condominium?>(
                              label: 'Condomínio',
                              value: _condominium,
                              items: [null, ...list],
                              itemLabel: (c) => c?.name ?? '—',
                              onChanged: (v) => setState(() => _condominium = v),
                            ),
                            if (list.isEmpty) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () => context.push(
                                    CondominiumRoutePrefix.rental.create,
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Cadastrar condomínio'),
                                ),
                              ),
                            ],
                          ],
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    FormGridField(
                      child: partiesAsync.when(
                        data: (list) => ClayDropdownField<RentalParty?>(
                          label: 'Proprietário',
                          value: _owner,
                          items: [null, ...list],
                          itemLabel: (p) => p?.fullName ?? '—',
                          onChanged: (v) => setState(() => _owner = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
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
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Endereço',
                  columns: columns,
                  items: [
                    FormGridField(
                      span: columns >= 2 ? 2 : 1,
                      child: ClayTextField(controller: _streetController, label: 'Rua'),
                    ),
                    FormGridField(child: ClayTextField(controller: _numberController, label: 'Número')),
                    FormGridField(
                      child: ClayTextField(controller: _neighborhoodController, label: 'Bairro'),
                    ),
                    FormGridField(child: ClayTextField(controller: _cityController, label: 'Cidade')),
                    FormGridField(child: ClayTextField(controller: _stateController, label: 'Estado')),
                    FormGridField(child: ClayTextField(controller: _zipController, label: 'CEP')),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Características e valores',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayTextField(
                        controller: _areaController,
                        label: 'Área (m²)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _bedroomsController,
                        label: 'Quartos',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _bathroomsController,
                        label: 'Banheiros',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _maxGuestsController,
                        label: 'Máx. hóspedes',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _baseRentController,
                        label: 'Aluguel mensal (R\$)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _baseDailyController,
                        label: 'Diária base (R\$)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _depositController,
                        label: 'Caução (R\$)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      onPressed: _loading ? null : _submit,
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
