import 'package:cond_manager/features/materials/domain/entities/material.dart' as mat;
import 'package:cond_manager/features/materials/domain/entities/material_supplier.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order_material.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_material_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/shared/domain/enums/location_type.dart';
import 'package:cond_manager/shared/domain/enums/material_item_type.dart';
import 'package:cond_manager/shared/utils/material_pricing.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

MaterialItemType? materialItemTypeForLocation(LocationType locationType) {
  if (locationType == LocationType.equipment) return MaterialItemType.equipment;
  return null;
}

class AddWorkOrderMaterialSheet extends ConsumerStatefulWidget {
  const AddWorkOrderMaterialSheet({super.key, required this.workOrder});

  final WorkOrder workOrder;

  static Future<void> show(BuildContext context, WorkOrder workOrder) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
          child: AddWorkOrderMaterialSheet(workOrder: workOrder),
        ),
      ),
    );
  }

  @override
  ConsumerState<AddWorkOrderMaterialSheet> createState() =>
      _AddWorkOrderMaterialSheetState();
}

class _AddWorkOrderMaterialSheetState extends ConsumerState<AddWorkOrderMaterialSheet> {
  final _qtyController = TextEditingController(text: '1');
  mat.Material? _selected;
  bool _loading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  double get _qty => double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0;

  WorkOrderAvailableMaterialsQuery get _query {
    return WorkOrderAvailableMaterialsQuery(
      condominiumId: widget.workOrder.condominiumId,
      serviceType: widget.workOrder.serviceType,
      itemType: materialItemTypeForLocation(widget.workOrder.locationType),
    );
  }

  String get _filterHint {
    final loc = widget.workOrder.locationType.label;
    final itemType = materialItemTypeForLocation(widget.workOrder.locationType);
    if (itemType == MaterialItemType.equipment) {
      return 'Local: $loc · exibindo equipamentos para ${widget.workOrder.serviceType.label}';
    }
    return 'Local: $loc · materiais para ${widget.workOrder.serviceType.label}';
  }

  Future<void> _submit() async {
    if (_selected == null || _qty <= 0) return;

    setState(() => _loading = true);

    final result = await ref.read(workOrderRepositoryProvider).addMaterial(
          AddWorkOrderMaterialInput(
            workOrderId: widget.workOrder.id,
            condominiumId: widget.workOrder.condominiumId,
            materialId: _selected!.id,
            quantity: _qty,
          ),
        );

    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(workOrderMaterialsProvider(widget.workOrder.id));
        ref.invalidate(workOrderDetailProvider(widget.workOrder.id));
        ref.invalidate(materialDetailProvider(_selected!.id));
        ref.invalidate(materialsListProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material lançado na OS.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      failure: (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(workOrderAvailableMaterialsProvider(_query));
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return ClaySurface(
      depth: ClayDepth.floating,
      radius: ClayTokens.radiusLg,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lançar material / equipamento',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Fechar',
              ),
            ],
          ),
          Text(
            _filterHint,
            style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  materialsAsync.when(
                    data: (materials) {
                      if (materials.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Nenhum material ativo para este serviço e local.',
                              style: TextStyle(color: ClayTokens.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            ClayButton(
                              label: 'Cadastrar material',
                              variant: ClayButtonVariant.secondary,
                              expand: false,
                              icon: Icons.add_rounded,
                              onPressed: () {
                                Navigator.pop(context);
                                context.go(
                                  Uri(
                                    path: '/materials/new',
                                    queryParameters: {
                                      'condominiumId': widget.workOrder.condominiumId,
                                      'serviceType': widget.workOrder.serviceType.value,
                                      'returnTo': '/work-orders/${widget.workOrder.id}',
                                    },
                                  ).toString(),
                                );
                              },
                            ),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClayDropdownField<mat.Material>(
                            label: 'Material / equipamento *',
                            value: _selected,
                            items: materials,
                            itemLabel: (m) =>
                                '${m.name} (${m.itemType.label})',
                            onChanged: (v) => setState(() => _selected = v),
                          ),
                          if (_selected != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _selected!.isStorable
                                  ? 'Estoque: ${_selected!.currentStock} ${_selected!.unitOfMeasure}'
                                  : 'Item não estocável',
                              style: TextStyle(
                                fontSize: 12,
                                color: _selected!.isStorable &&
                                        _selected!.currentStock < _qty
                                    ? ClayTokens.error
                                    : ClayTokens.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _MaterialSuppliersPanel(
                              material: _selected!,
                              quantity: _qty,
                              currency: currency,
                              dateFmt: dateFmt,
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                  ),
                  const SizedBox(height: 12),
                  ClayTextField(
                    controller: _qtyController,
                    label: 'Quantidade a lançar *',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_selected != null && _qty > 0) ...[
                    const SizedBox(height: 16),
                    WorkOrderMaterialLinePreview(
                      material: _selected!,
                      quantity: _qty,
                      currency: currency,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClayButton(
            label: 'Confirmar lançamento',
            icon: Icons.check_rounded,
            isLoading: _loading,
            onPressed: _loading || _selected == null || _qty <= 0 ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _MaterialSuppliersPanel extends StatelessWidget {
  const _MaterialSuppliersPanel({
    required this.material,
    required this.quantity,
    required this.currency,
    required this.dateFmt,
  });

  final mat.Material material;
  final double quantity;
  final NumberFormat currency;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final suppliers = _resolveSuppliers(material);

    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fornecedores cadastrados',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Histórico de compra por fornecedor (última compra registrada).',
            style: TextStyle(fontSize: 11, color: ClayTokens.textMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          ...suppliers.map(
            (supplier) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SupplierRow(
                supplier: supplier,
                material: material,
                launchQty: quantity,
                currency: currency,
                dateFmt: dateFmt,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MaterialSupplierLink> _resolveSuppliers(mat.Material material) {
    if (material.supplierLinks.isNotEmpty) return material.supplierLinks;
    if (material.providerId != null && material.providerName != null) {
      return [
        MaterialSupplierLink(
          providerId: material.providerId!,
          displayName: material.providerName!,
          isPrimary: true,
          lastUnitCost: material.unitCost,
          lastResaleUnitPrice: material.resaleUnitPrice,
        ),
      ];
    }
    return const [
      MaterialSupplierLink(
        providerId: '',
        displayName: 'Sem fornecedor vinculado',
      ),
    ];
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({
    required this.supplier,
    required this.material,
    required this.launchQty,
    required this.currency,
    required this.dateFmt,
  });

  final MaterialSupplierLink supplier;
  final mat.Material material;
  final double launchQty;
  final NumberFormat currency;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final lastCost = supplier.lastUnitCost ?? material.unitCost;
    final resale = supplier.lastResaleUnitPrice ?? material.resaleUnitPriceWithTax;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ClayTokens.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  supplier.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              if (supplier.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ClayTokens.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Principal',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ClayTokens.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoCell('Último custo', currency.format(lastCost)),
          _InfoCell(
            'Data última compra',
            supplier.lastPurchaseAt != null
                ? dateFmt.format(supplier.lastPurchaseAt!.toLocal())
                : '—',
          ),
          _InfoCell(
            'Qtd. última compra',
            supplier.lastPurchaseQuantity != null
                ? '${supplier.lastPurchaseQuantity} ${material.unitOfMeasureLabel}'
                : '—',
          ),
          _InfoCell('Qtd. lançamento', '$launchQty ${material.unitOfMeasureLabel}'),
          _InfoCell('Repasse (un.)', currency.format(resale)),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: ClayTokens.textMuted),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class WorkOrderMaterialLinePreview extends StatelessWidget {
  const WorkOrderMaterialLinePreview({
    super.key,
    required this.material,
    required this.quantity,
    required this.currency,
  });

  final mat.Material material;
  final double quantity;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final costTax = MaterialPricing.lineTotal(material.unitCostWithTax, quantity);
    final resaleTax =
        MaterialPricing.lineTotal(material.resaleUnitPriceWithTax, quantity);
    final margin = resaleTax - costTax;

    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Totais do lançamento', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Custo c/ impostos: ${currency.format(costTax)}'),
          Text('Repasse c/ impostos: ${currency.format(resaleTax)}'),
          Text(
            'Margem: ${currency.format(margin)}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: ClayTokens.success),
          ),
        ],
      ),
    );
  }
}
