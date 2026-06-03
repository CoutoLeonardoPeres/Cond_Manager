import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/materials/domain/entities/material.dart' as mat;
import 'package:cond_manager/features/materials/domain/entities/material_supplier.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_supplier_providers.dart';
import 'package:cond_manager/features/materials/presentation/widgets/material_ids_selector.dart';
import 'package:cond_manager/features/providers/presentation/widgets/service_specialties_selector.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MaterialSupplierFormPage extends ConsumerStatefulWidget {
  const MaterialSupplierFormPage({
    super.key,
    this.supplierId,
    this.initialCondominiumId,
  });

  final String? supplierId;
  final String? initialCondominiumId;

  bool get isEditing => supplierId != null;

  @override
  ConsumerState<MaterialSupplierFormPage> createState() => _MaterialSupplierFormPageState();
}

class _MaterialSupplierFormPageState extends ConsumerState<MaterialSupplierFormPage> {
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
  String _documentType = 'cnpj';
  EntityStatus _status = EntityStatus.active;
  Set<ServiceType> _specialties = {};
  Set<String> _materialIds = {};
  String? _specialtiesError;
  bool _loading = false;
  String? _error;
  bool _loaded = false;
  bool _addressCepLoading = false;

  late final AddressFields _addressFields;
  late final AddressCepAutofill _addressCepAutofill;

  @override
  void initState() {
    super.initState();
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

  void _fill(MaterialSupplierDetail d, List<Condominium> condos) {
    _legalNameController.text = d.legalName;
    _tradeNameController.text = d.tradeName ?? '';
    _documentType = d.documentType;
    ClayMaskedField.setDocument(
      _documentController,
      d.documentNumber,
      isCnpj: _documentType == 'cnpj',
    );
    _status = d.status;
    _specialties = Set<ServiceType>.from(d.specialties);
    ClayMaskedField.setPhone(_phoneController, d.phones.isNotEmpty ? d.phones.first : null);
    _emailController.text = d.emails.isNotEmpty ? d.emails.first : '';
    _addressCepAutofill.pause();
    ClayMaskedField.setCep(_zipController, d.zipCode);
    _streetController.text = d.street ?? '';
    _numberController.text = d.number ?? '';
    _complementController.text = d.complement ?? '';
    _neighborhoodController.text = d.neighborhood ?? '';
    _cityController.text = d.city ?? '';
    _stateController.text = d.state ?? '';
    _addressCepAutofill.resume();
    _notesController.text = d.notes ?? '';
    _materialIds = Set<String>.from(d.materialIds);
    for (final c in condos) {
      if (c.id == d.condominiumId) _condominium = c;
    }
    _loaded = true;
  }

  MaterialSupplierSaveInput _buildInput() {
    return MaterialSupplierSaveInput(
      condominiumId: _condominium!.id,
      documentType: _documentType,
      documentNumber: _documentController.text,
      legalName: _legalNameController.text,
      tradeName: _tradeNameController.text,
      specialties: _specialties.toList(),
      phones: [_phoneController.text],
      emails: [_emailController.text],
      street: _streetController.text,
      number: _numberController.text,
      complement: _complementController.text,
      neighborhood: _neighborhoodController.text,
      city: _cityController.text,
      state: _stateController.text,
      zipCode: _zipController.text,
      status: _status,
      notes: _notesController.text,
      materialIds: _materialIds.toList(),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_condominium == null) {
      setState(() => _error = 'Selecione o condomínio.');
      return;
    }
    if (_specialties.isEmpty) {
      setState(() => _specialtiesError = 'Selecione ao menos um tipo.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(materialRepositoryProvider);
    final input = _buildInput();

    if (widget.isEditing) {
      final result = await repo.updateMaterialSupplier(widget.supplierId!, input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(materialSuppliersListProvider);
          ref.invalidate(materialSuppliersProvider(_condominium!.id));
          ref.invalidate(materialsListProvider);
          context.go('/materials');
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final result = await repo.createMaterialSupplier(input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(materialSuppliersListProvider);
          ref.invalidate(materialSuppliersProvider(_condominium!.id));
          ref.invalidate(materialsListProvider);
          context.go('/materials');
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
    final condos = condosAsync.value ?? const <Condominium>[];
    final condoId = _condominium?.id ?? widget.initialCondominiumId;

    final materialsAsync = condoId != null
        ? ref.watch(materialsForCondominiumProvider(condoId))
        : const AsyncValue<List<mat.Material>>.data([]);

    if (widget.isEditing) {
      ref.watch(materialSupplierDetailProvider(widget.supplierId!)).whenData((d) {
        if (!_loaded && condos.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) setState(() => _fill(d, condos));
          });
        }
      });
    } else {
      if (_condominium == null && widget.initialCondominiumId != null) {
        for (final c in condos) {
          if (c.id == widget.initialCondominiumId) _condominium = c;
        }
      } else if (_condominium == null && condos.length == 1) {
        _condominium = condos.first;
      }
    }

    final materials = materialsAsync.value ?? const <mat.Material>[];
    final condoMaterials = materials;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go(resolveReturnPath(context, fallback: '/materials')),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    widget.isEditing ? 'Editar fornecedor' : 'Novo fornecedor de materiais',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: ClayTokens.error)),
            const SizedBox(height: 16),
            ClayDropdownField<Condominium>(
              label: 'Condomínio *',
              value: _condominium,
              items: condos,
              itemLabel: (c) => c.name,
              onChanged: widget.isEditing
                  ? null
                  : (v) => setState(() {
                        _condominium = v;
                        _materialIds = {};
                      }),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'cnpj', label: Text('CNPJ')),
                ButtonSegment(value: 'cpf', label: Text('CPF')),
              ],
              selected: {_documentType},
              onSelectionChanged: (s) => setState(() {
                _documentType = s.first;
                ClayMaskedField.onDocumentTypeChanged(
                  _documentController,
                  isCnpj: _documentType == 'cnpj',
                );
              }),
            ),
            const SizedBox(height: 12),
            ClayTextField(
              controller: _legalNameController,
              label: 'Razão social / nome *',
              validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            ClayTextField(controller: _tradeNameController, label: 'Nome fantasia'),
            const SizedBox(height: 12),
            ClayMaskedField.document(
              controller: _documentController,
              isCnpj: _documentType == 'cnpj',
              label: 'Documento *',
              required: true,
            ),
            const SizedBox(height: 12),
            ClayMaskedField.phone(controller: _phoneController, label: 'Telefone'),
            const SizedBox(height: 12),
            ClayTextField(controller: _emailController, label: 'E-mail'),
            const SizedBox(height: 16),
            buildAddressFormSection(
              title: 'Endereço (opcional)',
              fields: _addressFields,
              cepLoading: _addressCepLoading,
            ),
            const SizedBox(height: 16),
            ServiceSpecialtiesSelector(
              selected: _specialties,
              errorText: _specialtiesError,
              onChanged: (s) => setState(() {
                _specialties = s;
                _specialtiesError = null;
              }),
            ),
            const SizedBox(height: 16),
            if (condoId != null)
              MaterialIdsSelector(
                materials: condoMaterials,
                selectedIds: _materialIds,
                onChanged: (ids) => setState(() => _materialIds = ids),
              ),
            const SizedBox(height: 12),
            if (widget.isEditing)
              ClayDropdownField<EntityStatus>(
                label: 'Status',
                value: _status,
                items: EntityStatus.values,
                itemLabel: (s) => s.label,
                onChanged: (v) => setState(() => _status = v ?? EntityStatus.active),
              ),
            const SizedBox(height: 12),
            ClayTextField(controller: _notesController, label: 'Observações', maxLines: 2),
            const SizedBox(height: 24),
            ClayButton(
              label: widget.isEditing ? 'Salvar' : 'Cadastrar',
              icon: Icons.save_rounded,
              isLoading: _loading,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
