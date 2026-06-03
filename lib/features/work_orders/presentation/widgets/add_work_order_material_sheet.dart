import 'package:cond_manager/features/materials/domain/entities/material.dart' as mat;
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order_material.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_material_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/shared/utils/material_pricing.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddWorkOrderMaterialSheet extends ConsumerStatefulWidget {
  const AddWorkOrderMaterialSheet({super.key, required this.workOrder});

  final WorkOrder workOrder;

  static Future<void> show(BuildContext context, WorkOrder workOrder) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: AddWorkOrderMaterialSheet(workOrder: workOrder),
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
    final query = WorkOrderAvailableMaterialsQuery(
      condominiumId: widget.workOrder.condominiumId,
      serviceType: widget.workOrder.serviceType,
    );
    final materialsAsync = ref.watch(workOrderAvailableMaterialsProvider(query));
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return ClaySurface(
      depth: ClayDepth.floating,
      radius: ClayTokens.radiusLg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Lançar material / equipamento',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Serviço da OS: ${widget.workOrder.serviceType.label}',
              style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            materialsAsync.when(
              data: (materials) {
                if (materials.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Nenhum material ativo para este serviço.',
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
                      label: 'Material *',
                      value: _selected,
                      items: materials,
                      itemLabel: (m) => m.name,
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
              label: 'Quantidade *',
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
            const SizedBox(height: 20),
            ClayButton(
              label: 'Confirmar lançamento',
              icon: Icons.check_rounded,
              isLoading: _loading,
              onPressed: _loading || _selected == null || _qty <= 0 ? null : _submit,
            ),
          ],
        ),
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
