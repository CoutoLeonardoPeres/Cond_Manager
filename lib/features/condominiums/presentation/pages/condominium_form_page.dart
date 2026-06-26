import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CondominiumFormPage extends ConsumerStatefulWidget {
  const CondominiumFormPage({super.key, this.condominiumId});

  final String? condominiumId;

  bool get isEditing => condominiumId != null;

  @override
  ConsumerState<CondominiumFormPage> createState() => _CondominiumFormPageState();
}

class _CondominiumFormPageState extends ConsumerState<CondominiumFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _syndicNameController = TextEditingController();
  final _syndicPhoneController = TextEditingController();
  final _syndicEmailController = TextEditingController();
  final _managerCompanyController = TextEditingController();
  final _managerCnpjController = TextEditingController();
  final _managerContactController = TextEditingController();
  final _managerPhoneController = TextEditingController();
  final _managerEmailController = TextEditingController();
  final _managerStreetController = TextEditingController();
  final _managerNumberController = TextEditingController();
  final _managerComplementController = TextEditingController();
  final _managerNeighborhoodController = TextEditingController();
  final _managerCityController = TextEditingController();
  final _managerStateController = TextEditingController();
  final _managerZipController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _loaded = false;

  late final AddressFields _condoAddress;
  late final AddressFields _managerAddress;

  @override
  void initState() {
    super.initState();
    _condoAddress = AddressFields(
      zip: _zipController,
      street: _streetController,
      number: _numberController,
      complement: _complementController,
      neighborhood: _neighborhoodController,
      city: _cityController,
      state: _stateController,
    );
    _managerAddress = AddressFields(
      zip: _managerZipController,
      street: _managerStreetController,
      number: _managerNumberController,
      complement: _managerComplementController,
      neighborhood: _managerNeighborhoodController,
      city: _managerCityController,
      state: _managerStateController,
    );
  }

  void _goBack(BuildContext context) {
    if (widget.isEditing) {
      context.go('/condominiums/${widget.condominiumId}');
      return;
    }
    context.go(resolveReturnPath(context, fallback: '/condominiums'));
  }

  void _fillFromCondominium(Condominium c) {
    _nameController.text = c.name;
    _legalNameController.text = c.legalName ?? '';
    ClayMaskedField.setCnpj(_cnpjController, c.cnpj);
    _condoAddress.pauseCepLookup();
    ClayMaskedField.setCep(_zipController, c.zipCode);
    _streetController.text = c.street ?? '';
    _numberController.text = c.number ?? '';
    _complementController.text = c.complement ?? '';
    _neighborhoodController.text = c.neighborhood ?? '';
    _cityController.text = c.city;
    _stateController.text = c.state;
    _condoAddress.resumeCepLookup();
    _syndicNameController.text = c.syndicName ?? '';
    ClayMaskedField.setPhone(_syndicPhoneController, c.syndicPhone);
    _syndicEmailController.text = c.syndicEmail ?? '';
    _managerCompanyController.text = c.managerCompany ?? '';
    ClayMaskedField.setCnpj(_managerCnpjController, c.managerCnpj);
    _managerContactController.text = c.managerContactName ?? '';
    ClayMaskedField.setPhone(_managerPhoneController, c.managerPhone);
    _managerEmailController.text = c.managerEmail ?? '';
    _managerAddress.pauseCepLookup();
    ClayMaskedField.setCep(_managerZipController, c.managerZipCode);
    _managerStreetController.text = c.managerStreet ?? '';
    _managerNumberController.text = c.managerNumber ?? '';
    _managerComplementController.text = c.managerComplement ?? '';
    _managerNeighborhoodController.text = c.managerNeighborhood ?? '';
    _managerCityController.text = c.managerCity ?? '';
    _managerStateController.text = c.managerState ?? '';
    _managerAddress.resumeCepLookup();
    _loaded = true;
  }

  CondominiumCreateInput _buildInput() {
    return CondominiumCreateInput(
      name: _nameController.text,
      legalName: _legalNameController.text,
      cnpj: _cnpjController.text,
      street: _streetController.text,
      number: _numberController.text,
      complement: _complementController.text,
      neighborhood: _neighborhoodController.text,
      city: _cityController.text,
      state: _stateController.text,
      zipCode: _zipController.text,
      syndicName: _syndicNameController.text,
      syndicPhone: _syndicPhoneController.text,
      syndicEmail: _syndicEmailController.text,
      managerCompany: _managerCompanyController.text,
      managerCnpj: _managerCnpjController.text,
      managerContactName: _managerContactController.text,
      managerPhone: _managerPhoneController.text,
      managerEmail: _managerEmailController.text,
      managerStreet: _managerStreetController.text,
      managerNumber: _managerNumberController.text,
      managerComplement: _managerComplementController.text,
      managerNeighborhood: _managerNeighborhoodController.text,
      managerCity: _managerCityController.text,
      managerState: _managerStateController.text,
      managerZipCode: _managerZipController.text,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _cnpjController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _syndicNameController.dispose();
    _syndicPhoneController.dispose();
    _syndicEmailController.dispose();
    _managerCompanyController.dispose();
    _managerCnpjController.dispose();
    _managerContactController.dispose();
    _managerPhoneController.dispose();
    _managerEmailController.dispose();
    _managerStreetController.dispose();
    _managerNumberController.dispose();
    _managerComplementController.dispose();
    _managerNeighborhoodController.dispose();
    _managerCityController.dispose();
    _managerStateController.dispose();
    _managerZipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final input = _buildInput();
    final repo = ref.read(condominiumRepositoryProvider);

    final result = widget.isEditing
        ? await repo.update(widget.condominiumId!, input)
        : await repo.create(input);

    if (!mounted) return;

    result.when(
      success: (condo) {
        ref.invalidate(condominiumsListProvider);
        ref.invalidate(accessibleCondominiumsProvider);
        if (widget.isEditing) {
          ref.invalidate(condominiumDetailProvider(widget.condominiumId!));
          context.go('/condominiums/${widget.condominiumId}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Condomínio atualizado com sucesso!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ref.invalidate(currentProfileProvider);
          final returnPath = resolveReturnPath(context, fallback: '/condominiums');
          context.go(returnPath);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Condomínio cadastrado com sucesso!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      failure: (e) => setState(() => _error = e.message),
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final perms = profile.permissions;
    final canCreate = profile?.isPlatformAdmin == true;
    final canEdit = widget.isEditing &&
        widget.condominiumId != null &&
        perms.canEditCondominium(widget.condominiumId!);

    if (widget.isEditing) {
      if (!canEdit) {
        return _LockedView(
          message: 'Apenas administrador ou gerente podem editar este condomínio.',
          onBack: () => _goBack(context),
        );
      }

      final condoAsync = ref.watch(condominiumDetailProvider(widget.condominiumId!));
      return condoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
        error: (e, _) => _LockedView(
          message: e.toString(),
          onBack: () => _goBack(context),
        ),
        data: (condo) {
          if (!_loaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_loaded) {
                setState(() => _fillFromCondominium(condo));
              }
            });
          }
          return _buildForm(context, title: 'Editar condomínio', saveLabel: 'Salvar alterações');
        },
      );
    }

    if (!canCreate) {
      return _LockedView(
        message: 'Apenas administrador da plataforma pode cadastrar condomínios.',
        onBack: () => _goBack(context),
      );
    }

    return _buildForm(context, title: 'Novo condomínio', saveLabel: 'Salvar condomínio');
  }

  Widget _buildForm(
    BuildContext context, {
    required String title,
    required String saveLabel,
  }) {
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
                        onPressed: () => _goBack(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  ClaySurface(
                    depth: ClayDepth.pressed,
                    color: ClayTokens.error.withValues(alpha: 0.1),
                    radius: ClayTokens.radiusSm,
                    padding: const EdgeInsets.all(14),
                    child: Text(_error!, style: const TextStyle(color: ClayTokens.error)),
                  ),
                  const SizedBox(height: 16),
                ],
                FormGridSection(
                  title: 'Dados gerais',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayTextField(
                        controller: _nameController,
                        label: 'Nome do condomínio *',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _legalNameController,
                        label: 'Razão social',
                      ),
                    ),
                    FormGridField(
                      child: ClayMaskedField.cnpj(
                        controller: _cnpjController,
                        label: 'CNPJ',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                buildAddressFormSection(
                  title: 'Endereço do condomínio',
                  fields: _condoAddress,
                  cityRequired: true,
                  stateRequired: true,
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Síndico',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayTextField(
                        controller: _syndicNameController,
                        label: 'Nome',
                      ),
                    ),
                    FormGridField(
                      child: ClayMaskedField.phone(
                        controller: _syndicPhoneController,
                        label: 'Telefone',
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _syndicEmailController,
                        label: 'E-mail',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Empresa administradora',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayTextField(
                        controller: _managerCompanyController,
                        label: 'Empresa',
                      ),
                    ),
                    FormGridField(
                      child: ClayMaskedField.cnpj(
                        controller: _managerCnpjController,
                        label: 'CNPJ',
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _managerContactController,
                        label: 'Contato',
                      ),
                    ),
                    FormGridField(
                      child: ClayMaskedField.phone(
                        controller: _managerPhoneController,
                        label: 'Telefone',
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _managerEmailController,
                        label: 'E-mail',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                buildAddressFormSection(
                  title: 'Endereço da administradora',
                  fields: _managerAddress,
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: columns >= 3 ? 280 : double.infinity,
                    child: ClayButton(
                      label: saveLabel,
                      icon: Icons.check_rounded,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
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

class _LockedView extends StatelessWidget {
  const _LockedView({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClaySurface(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: ClayTokens.warning, size: 40),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ClayButton(
                label: 'Voltar',
                variant: ClayButtonVariant.secondary,
                onPressed: onBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
