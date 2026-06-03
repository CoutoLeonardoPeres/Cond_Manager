import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/materials/domain/entities/material.dart' as mat;
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/materials/presentation/widgets/material_pricing_preview.dart';
import 'package:cond_manager/features/materials/presentation/widgets/material_suppliers_selector.dart';
import 'package:cond_manager/features/providers/presentation/widgets/service_specialties_selector.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/material_item_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MaterialFormPage extends ConsumerStatefulWidget {
  const MaterialFormPage({super.key, this.materialId});

  final String? materialId;

  bool get isEditing => materialId != null;

  @override
  ConsumerState<MaterialFormPage> createState() => _MaterialFormPageState();
}

class _MaterialFormPageState extends ConsumerState<MaterialFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _unitController = TextEditingController(text: 'un');
  final _unitCostController = TextEditingController();
  final _purchaseTaxController = TextEditingController(text: '0');
  final _resalePriceController = TextEditingController();
  final _resaleTaxController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  Condominium? _condominium;
  mat.MaterialCategory? _category;
  Set<String> _supplierIds = {};
  String? _primarySupplierId;
  MaterialItemType _itemType = MaterialItemType.material;
  EntityStatus _status = EntityStatus.active;
  bool _isStorable = true;
  Set<ServiceType> _services = {};
  String? _servicesError;
  bool _loading = false;
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _unitController.dispose();
    _unitCostController.dispose();
    _purchaseTaxController.dispose();
    _resalePriceController.dispose();
    _resaleTaxController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double _parseNum(String text) =>
      double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _fill(mat.Material m, List<Condominium> condos) {
    _nameController.text = m.name;
    _skuController.text = m.sku ?? '';
    _unitController.text = m.unitOfMeasure;
    _unitCostController.text = m.unitCost.toString();
    _purchaseTaxController.text = m.purchaseTaxPercent.toString();
    _resalePriceController.text = m.resaleUnitPrice.toString();
    _resaleTaxController.text = m.resaleTaxPercent.toString();
    _minStockController.text = m.minStock.toString();
    _descriptionController.text = m.description ?? '';
    _itemType = m.itemType;
    _status = m.status;
    _isStorable = m.isStorable;
    _services = Set<ServiceType>.from(m.applicableServices);
    for (final c in condos) {
      if (c.id == m.condominiumId) _condominium = c;
    }
    _loaded = true;
  }

  Future<void> _addCategory() async {
    if (_condominium == null) return;
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova categoria'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true || nameController.text.trim().isEmpty) return;
    final result = await ref.read(materialRepositoryProvider).createCategory(
          condominiumId: _condominium!.id,
          name: nameController.text,
        );
    if (!mounted) return;
    result.when(
      success: (cat) {
        ref.invalidate(materialCategoriesProvider(_condominium!.id));
        setState(() => _category = cat);
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_condominium == null) {
      setState(() => _error = 'Selecione o condomínio.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final unitCost = _parseNum(_unitCostController.text);
    final purchaseTax = _parseNum(_purchaseTaxController.text);
    final resale = _parseNum(_resalePriceController.text);
    final resaleTax = _parseNum(_resaleTaxController.text);
    final minStock = _isStorable ? _parseNum(_minStockController.text) : 0;

    final repo = ref.read(materialRepositoryProvider);

    if (widget.isEditing) {
      final input = mat.MaterialUpdateInput(
        categoryId: _category?.id,
        providerId: _primarySupplierId,
        name: _nameController.text,
        sku: _skuController.text,
        itemType: _itemType,
        isStorable: _isStorable,
        unitOfMeasure: _unitController.text,
        unitCost: unitCost,
        purchaseTaxPercent: purchaseTax,
        resaleUnitPrice: resale,
        resaleTaxPercent: resaleTax,
        applicableServices: _services.toList(),
        minStock: minStock.toDouble(),
        description: _descriptionController.text,
        status: _status,
      );
      final result = await repo.update(widget.materialId!, input);
      if (!mounted) return;
      result.when(
        success: (_) async {
          await repo.syncMaterialSuppliers(
            materialId: widget.materialId!,
            condominiumId: _condominium!.id,
            providerIds: _supplierIds.toList(),
            primaryProviderId: _primarySupplierId,
          );
          if (!mounted) return;
          ref.invalidate(materialsListProvider);
          ref.invalidate(materialDetailProvider(widget.materialId!));
          ref.invalidate(materialSuppliersProvider(_condominium!.id));
          context.go('/materials/${widget.materialId}');
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final input = mat.MaterialCreateInput(
        condominiumId: _condominium!.id,
        categoryId: _category?.id,
        providerId: _primarySupplierId,
        name: _nameController.text,
        sku: _skuController.text,
        itemType: _itemType,
        isStorable: _isStorable,
        unitOfMeasure: _unitController.text,
        unitCost: unitCost,
        purchaseTaxPercent: purchaseTax,
        resaleUnitPrice: resale,
        resaleTaxPercent: resaleTax,
        applicableServices: _services.toList(),
        minStock: minStock.toDouble(),
        description: _descriptionController.text,
      );
      final result = await repo.create(input);
      if (!mounted) return;
      result.when(
        success: (m) async {
          await repo.syncMaterialSuppliers(
            materialId: m.id,
            condominiumId: m.condominiumId,
            providerIds: _supplierIds.toList(),
            primaryProviderId: _primarySupplierId,
          );
          if (!mounted) return;
          ref.invalidate(materialsListProvider);
          ref.invalidate(materialSuppliersProvider(m.condominiumId));
          context.go('/materials/${m.id}');
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
    final condoId = _condominium?.id;
    final categoriesAsync = condoId != null
        ? ref.watch(materialCategoriesProvider(condoId))
        : const AsyncValue<List<mat.MaterialCategory>>.data([]);
    final suppliersAsync = condoId != null
        ? ref.watch(materialSuppliersProvider(condoId))
        : const AsyncValue<List<mat.ProviderPickerForMaterial>>.data([]);

    if (widget.isEditing) {
      final detail = ref.watch(materialDetailProvider(widget.materialId!));
      detail.whenData((m) {
        if (!_loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) {
              setState(() {
                _fill(m, condos);
                if (m.categoryId != null && m.categoryName != null) {
                  _category = mat.MaterialCategory(
                    id: m.categoryId!,
                    condominiumId: m.condominiumId,
                    name: m.categoryName!,
                  );
                }
                _supplierIds = m.supplierLinks.map((l) => l.providerId).toSet();
                if (_supplierIds.isEmpty && m.providerId != null) {
                  _supplierIds = {m.providerId!};
                }
                _primarySupplierId = m.supplierLinks
                        .where((l) => l.isPrimary)
                        .map((l) => l.providerId)
                        .firstOrNull ??
                    m.providerId;
              });
            }
          });
        }
      });
      if (detail.isLoading && !_loaded) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 3));
      }
    } else if (_condominium == null && condos.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _condominium == null) setState(() => _condominium = condos.first);
      });
    }

    final unitCost = _parseNum(_unitCostController.text);
    final purchaseTax = _parseNum(_purchaseTaxController.text);
    final resale = _parseNum(_resalePriceController.text);
    final resaleTax = _parseNum(_resaleTaxController.text);

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
                        onPressed: () => context.go(
                          resolveReturnPath(context, fallback: '/materials'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Editar material' : 'Novo material / equipamento',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: ClayTokens.error)),
                  ),
                FormGridSection(
                  title: 'Identificação',
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
                                  : (v) => setState(() {
                                        _condominium = v;
                                        _category = null;
                                        _supplierIds = {};
                                        _primarySupplierId = null;
                                      }),
                            ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<MaterialItemType>(
                        label: 'Tipo *',
                        value: _itemType,
                        items: MaterialItemType.values,
                        itemLabel: (t) => t.label,
                        onChanged: (v) =>
                            setState(() => _itemType = v ?? MaterialItemType.material),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _nameController,
                        label: 'Nome *',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(controller: _skuController, label: 'SKU / código'),
                    ),
                    FormGridField(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: categoriesAsync.when(
                              data: (cats) {
                                final items = [null, ...cats];
                                return ClayDropdownField<mat.MaterialCategory?>(
                                  label: 'Categoria',
                                  value: _category,
                                  items: items,
                                  itemLabel: (c) => c?.name ?? 'Sem categoria',
                                  onChanged: (v) => setState(() => _category = v),
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ),
                          if (condoId != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _addCategory,
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Nova categoria',
                            ),
                          ],
                        ],
                      ),
                    ),
                    FormGridField(
                      span: columns,
                      child: suppliersAsync.when(
                        data: (list) => MaterialSuppliersSelector(
                          available: list,
                          selectedIds: _supplierIds,
                          primaryId: _primarySupplierId,
                          onChanged: (ids, primary) => setState(() {
                            _supplierIds = ids;
                            _primarySupplierId = primary;
                          }),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    if (condoId != null)
                      FormGridField(
                        span: columns,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => context.go(
                              Uri(
                                path: '/materials/suppliers/new',
                                queryParameters: {'condominiumId': condoId},
                              ).toString(),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Cadastrar fornecedor'),
                          ),
                        ),
                      ),
                    if (widget.isEditing)
                      FormGridField(
                        child: ClayDropdownField<EntityStatus>(
                          label: 'Status',
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
                  title: 'Serviços em que é utilizado',
                  columns: 1,
                  items: [
                    FormGridField(
                      span: columns,
                      child: ServiceSpecialtiesSelector(
                        selected: _services,
                        errorText: _servicesError,
                        onChanged: (s) => setState(() {
                          _services = s;
                          _servicesError = null;
                        }),
                      ),
                    ),
                    const FormGridField(
                      child: Text(
                        'Vazio = pode ser usado em qualquer tipo de serviço/OS.',
                        style: TextStyle(fontSize: 12, color: ClayTokens.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Preços e impostos',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayTextField(
                        controller: _unitCostController,
                        label: 'Custo unitário compra (R\$) *',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _purchaseTaxController,
                        label: 'Impostos compra (%)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _resalePriceController,
                        label: 'Repasse unitário condomínio (R\$) *',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _resaleTaxController,
                        label: 'Impostos repasse (%)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _unitController,
                        label: 'Unidade de medida *',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                MaterialPricingPreview(
                  unitCost: unitCost,
                  purchaseTaxPercent: purchaseTax,
                  resaleUnitPrice: resale,
                  resaleTaxPercent: resaleTax,
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Estoque',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Controlar estoque'),
                        value: _isStorable,
                        onChanged: (v) => setState(() => _isStorable = v),
                      ),
                    ),
                    if (_isStorable)
                      FormGridField(
                        child: ClayTextField(
                          controller: _minStockController,
                          label: 'Estoque mínimo',
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Descrição',
                  columns: 1,
                  items: [
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
      },
    );
  }
}
