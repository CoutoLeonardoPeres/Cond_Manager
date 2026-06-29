import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/condominium_route_prefix.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_inclusion.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_photo.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_property_inclusions_editor.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_property_photos_editor.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/domain/enums/rental_property_type.dart';
import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';
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
  final _buildingController = TextEditingController();
  final _blockController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _complementController = TextEditingController();
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
  final _matriculaController = TextEditingController();
  final _cartorioController = TextEditingController();
  final _iptuController = TextEditingController();
  final _municipalController = TextEditingController();

  RentalPropertyType _propertyType = RentalPropertyType.apartment;
  RentalListingMode _listingMode = RentalListingMode.longTerm;
  Condominium? _condominium;
  RentalParty? _owner;
  String _status = 'active';
  bool _loading = false;
  String? _error;
  bool _loaded = false;
  bool _inclusionsLoaded = false;
  bool _photosLoaded = false;
  bool _cepLoading = false;
  bool? _isFurnished;
  bool? _acceptsPets;
  List<RentalPropertyInclusionInput> _inclusions = [];
  List<RentalPropertyPhotoDraft> _photos = [];
  List<RentalPropertyPhotoDraft> _initialPhotos = [];

  late final AddressFields _address;
  late final AddressCepAutofill _cepAutofill;

  @override
  void initState() {
    super.initState();
    _address = AddressFields(
      zip: _zipController,
      street: _streetController,
      number: _numberController,
      complement: _complementController,
      neighborhood: _neighborhoodController,
      city: _cityController,
      state: _stateController,
    );
    _cepAutofill = AddressCepAutofill(
      _address,
      onLoadingChanged: (loading) {
        if (mounted) setState(() => _cepLoading = loading);
      },
    );
    _cepAutofill.attach();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _buildingController.dispose();
    _blockController.dispose();
    _apartmentController.dispose();
    _complementController.dispose();
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
    _matriculaController.dispose();
    _cartorioController.dispose();
    _iptuController.dispose();
    _municipalController.dispose();
    _cepAutofill.detach();
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

  void _applyCondominiumAddress(Condominium condo) {
    _address.pauseCepLookup();
    ClayMaskedField.setCep(_zipController, condo.zipCode);
    _streetController.text = condo.street ?? '';
    _numberController.text = condo.number ?? '';
    _neighborhoodController.text = condo.neighborhood ?? '';
    _cityController.text = condo.city;
    _stateController.text = condo.state;
    _address.resumeCepLookup();
  }

  void _onCondominiumChanged(Condominium? condo) {
    setState(() {
      _condominium = condo;
      if (condo != null) _applyCondominiumAddress(condo);
    });
  }

  void _fill(RentalProperty p, List<Condominium> condos, List<RentalParty> parties) {
    _titleController.text = p.title;
    _codeController.text = p.code ?? '';
    _descriptionController.text = p.description ?? '';
    _address.pauseCepLookup();
    ClayMaskedField.setCep(_zipController, p.addressZip);
    _streetController.text = p.addressStreet ?? '';
    _numberController.text = p.addressNumber ?? '';
    _buildingController.text = p.addressBuilding ?? '';
    _blockController.text = p.addressBlock ?? '';
    _apartmentController.text = p.addressApartment ?? '';
    _neighborhoodController.text = p.addressNeighborhood ?? '';
    _cityController.text = p.addressCity ?? '';
    _stateController.text = p.addressState ?? '';
    _address.resumeCepLookup();
    if (p.areaSqm != null) _areaController.text = p.areaSqm.toString();
    if (p.bedrooms != null) _bedroomsController.text = p.bedrooms.toString();
    if (p.bathrooms != null) _bathroomsController.text = p.bathrooms.toString();
    if (p.maxGuests != null) _maxGuestsController.text = p.maxGuests.toString();
    if (p.baseRentAmount != null) _baseRentController.text = p.baseRentAmount.toString();
    if (p.baseDailyRate != null) _baseDailyController.text = p.baseDailyRate.toString();
    if (p.depositAmount != null) _depositController.text = p.depositAmount.toString();
    _matriculaController.text = p.registryMatricula ?? '';
    _cartorioController.text = p.registryCartorio ?? '';
    _iptuController.text = p.iptuInscription ?? '';
    _municipalController.text = p.municipalInscription ?? '';
    _isFurnished = p.isFurnished;
    _acceptsPets = p.acceptsPets;
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
        addressBuilding:
            _buildingController.text.trim().isEmpty ? null : _buildingController.text.trim(),
        addressBlock: _blockController.text.trim().isEmpty ? null : _blockController.text.trim(),
        addressApartment:
            _apartmentController.text.trim().isEmpty ? null : _apartmentController.text.trim(),
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
        registryMatricula: _matriculaController.text.trim().isEmpty
            ? null
            : _matriculaController.text.trim(),
        registryCartorio:
            _cartorioController.text.trim().isEmpty ? null : _cartorioController.text.trim(),
        iptuInscription: _iptuController.text.trim().isEmpty ? null : _iptuController.text.trim(),
        municipalInscription: _municipalController.text.trim().isEmpty
            ? null
            : _municipalController.text.trim(),
        isFurnished: _isFurnished,
        acceptsPets: _acceptsPets,
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

    Future<void> onSaved(RentalProperty property) async {
      final photoChanges = RentalPropertyPhotosChanges.fromDrafts(
        current: _photos,
        initial: _initialPhotos,
      );

      if (photoChanges.deletedPhotoIds.isNotEmpty) {
        final delResult = await repo.deletePropertyPhotos(photoChanges.deletedPhotoIds);
        if (!mounted) return;
        final delFailed = delResult.when(
          success: (_) => false,
          failure: (_) => true,
        );
        if (delFailed) {
          setState(() {
            _loading = false;
            _error = 'Imóvel salvo, mas falha ao remover fotos antigas.';
          });
          return;
        }
      }

      final incResult = await repo.replacePropertyInclusions(
        property.id,
        companyId,
        _inclusions,
      );
      if (!mounted) return;
      var stopAfterInclusions = false;
      incResult.when(
        success: (_) {},
        failure: (e) {
          stopAfterInclusions = true;
          setState(() {
            _loading = false;
            _error = 'Imóvel salvo, mas falha nos itens inclusos: ${e.message}';
          });
        },
      );
      if (stopAfterInclusions) return;

      if (photoChanges.pendingUploads.isNotEmpty) {
        final upResult = await repo.uploadPropertyPhotos(
          propertyId: property.id,
          companyId: companyId,
          files: photoChanges.pendingUploads,
          sortOffset: photoChanges.existingCount,
        );
        if (!mounted) return;
        var stopAfterUpload = false;
        upResult.when(
          success: (_) {},
          failure: (e) {
            stopAfterUpload = true;
            setState(() {
              _loading = false;
              _error = 'Imóvel salvo, mas falha ao enviar fotos: ${e.message}';
            });
          },
        );
        if (stopAfterUpload) return;
      }

      ref.invalidate(rentalPropertiesListProvider);
      ref.invalidate(rentalPropertyInclusionsProvider(property.id));
      ref.invalidate(rentalPropertyPhotosProvider(property.id));
      if (widget.isEditing) {
        ref.invalidate(rentalPropertyDetailProvider(widget.propertyId!));
      }
      if (!mounted) return;
      context.go(resolveReturnPath(context, fallback: '/rental/properties'));
    }

    if (widget.isEditing) {
      final result = await repo.updateProperty(widget.propertyId!, input);
      if (!mounted) return;
      await result.when(
        success: onSaved,
        failure: (e) async => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final result = await repo.createProperty(input);
      if (!mounted) return;
      await result.when(
        success: onSaved,
        failure: (e) async => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final title = _titleController.text.trim().isEmpty
        ? 'este imóvel'
        : '"${_titleController.text.trim()}"';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir imóvel'),
        content: Text(
          'Tem certeza que deseja excluir $title?\n\n'
          'Reservas, contratos e cobranças vinculados também serão removidos. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: ClayTokens.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref.read(rentalRepositoryProvider).deleteProperty(widget.propertyId!);
    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(rentalPropertiesListProvider);
        ref.invalidate(rentalGanttBookingsProvider);
        ref.invalidate(rentalGanttLeasesProvider);
        context.go(resolveReturnPath(context, fallback: '/rental/properties'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imóvel excluído com sucesso.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      failure: (e) => setState(() {
        _loading = false;
        _error = e.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        ref.watch(currentProfileProvider).value?.permissions.canManageRental ?? false;
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
      ref.watch(rentalPropertyInclusionsProvider(widget.propertyId!)).whenData((list) {
        if (!_inclusionsLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_inclusionsLoaded) {
              setState(() {
                _inclusions = list.map(RentalPropertyInclusionInput.fromEntity).toList();
                _inclusionsLoaded = true;
              });
            }
          });
        }
      });
      ref.watch(rentalPropertyPhotosProvider(widget.propertyId!)).whenData((list) {
        if (!_photosLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_photosLoaded) {
              final drafts = list.map((p) => RentalPropertyPhotoDraft.existing(p)).toList();
              setState(() {
                _photos = drafts;
                _initialPhotos = drafts;
                _photosLoaded = true;
              });
            }
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
                              onChanged: _onCondominiumChanged,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ao selecionar, o endereço do condomínio preenche os campos abaixo (você pode alterar).',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ClayTokens.textMuted,
                                  ),
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
                      span: 2,
                      child: partiesAsync.when(
                        data: (list) {
                          final owners = list
                              .where((p) => p.category == RentalPartyCategory.landlord)
                              .toList();
                          final selectedOwner = _owner != null &&
                                  owners.every((p) => p.id != _owner!.id)
                              ? _owner
                              : null;
                          final dropdownItems = [
                            null,
                            if (selectedOwner != null) selectedOwner,
                            ...owners,
                          ];
                          return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClayDropdownField<RentalParty?>(
                              label: 'Locador',
                              hint: owners.isEmpty
                                  ? 'Cadastre um locador em Pessoas'
                                  : null,
                              value: _owner,
                              items: dropdownItems,
                              itemLabel: (p) => p?.fullName ?? '—',
                              onChanged: (v) => setState(() => _owner = v),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Lista pessoas cadastradas como Locador em Locação → Pessoas.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ClayTokens.textMuted,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  final returnTo = GoRouterState.of(context).uri.toString();
                                  final uri = Uri(
                                    path: '/rental/parties/new',
                                    queryParameters: {
                                      'returnTo': returnTo,
                                      'category': RentalPartyCategory.landlord.value,
                                    },
                                  );
                                  context.go(uri.toString());
                                },
                                icon: const Icon(Icons.person_add_rounded, size: 18),
                                label: Text(
                                  owners.isEmpty
                                      ? 'Cadastrar locador'
                                      : 'Cadastrar novo locador',
                                ),
                              ),
                            ),
                          ],
                        );
                        },
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
                      child: ClayMaskedField.cep(
                        controller: _zipController,
                        label: 'CEP',
                        suffixIcon: _cepLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Buscar CEP',
                                icon: const Icon(Icons.search_rounded, size: 20),
                                color: ClayTokens.accent,
                                onPressed: _cepAutofill.lookupNow,
                              ),
                        onComplete: _cepAutofill.lookupNow,
                      ),
                    ),
                    FormGridField(
                      span: columns >= 2 ? 2 : 1,
                      child: ClayTextField(controller: _streetController, label: 'Rua'),
                    ),
                    FormGridField(child: ClayTextField(controller: _numberController, label: 'Número')),
                    FormGridField(
                      child: ClayTextField(controller: _buildingController, label: 'Edifício'),
                    ),
                    FormGridField(
                      child: ClayTextField(controller: _blockController, label: 'Bloco/Torre'),
                    ),
                    FormGridField(
                      child: ClayTextField(controller: _apartmentController, label: 'Apartamento'),
                    ),
                    FormGridField(
                      child: ClayTextField(controller: _neighborhoodController, label: 'Bairro'),
                    ),
                    FormGridField(child: ClayTextField(controller: _cityController, label: 'Cidade')),
                    FormGridField(
                      child: ClayTextField(
                        controller: _stateController,
                        label: 'Estado',
                        onChanged: (v) {
                          final upper = v.toUpperCase();
                          if (upper != v) {
                            _stateController.value = _stateController.value.copyWith(
                              text: upper,
                              selection: TextSelection.collapsed(offset: upper.length),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RentalPropertyInclusionsEditor(
                  companyId: ref.watch(currentProfileProvider).value?.companyId ?? '',
                  items: _inclusions,
                  columns: columns,
                  onChanged: (items) => setState(() => _inclusions = items),
                ),
                const SizedBox(height: 16),
                RentalPropertyPhotosEditor(
                  photos: _photos,
                  enabled: !_loading,
                  onChanged: (photos) => setState(() => _photos = photos),
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
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Dados para contrato',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayTextField(
                        controller: _matriculaController,
                        label: 'Matrícula',
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _cartorioController,
                        label: 'Cartório',
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _iptuController,
                        label: 'Inscrição IPTU',
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _municipalController,
                        label: 'Inscrição municipal',
                      ),
                    ),
                    FormGridField(
                      span: columns,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Imóvel mobiliado'),
                            subtitle: const Text(
                              'Usado no contrato de locação (PDF).',
                              style: TextStyle(fontSize: 12, color: ClayTokens.textMuted),
                            ),
                            value: _isFurnished,
                            tristate: true,
                            onChanged: (v) => setState(() => _isFurnished = v),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Aceita pets'),
                            subtitle: const Text(
                              'Usado no contrato de locação (PDF).',
                              style: TextStyle(fontSize: 12, color: ClayTokens.textMuted),
                            ),
                            value: _acceptsPets,
                            tristate: true,
                            onChanged: (v) => setState(() => _acceptsPets = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (widget.isEditing && canManage) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _confirmDelete,
                          icon: const Icon(Icons.delete_outline_rounded, color: ClayTokens.error),
                          label: const Text(
                            'Excluir',
                            style: TextStyle(color: ClayTokens.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ClayButton(
                        label: widget.isEditing ? 'Salvar' : 'Cadastrar',
                        icon: Icons.save_rounded,
                        isLoading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
