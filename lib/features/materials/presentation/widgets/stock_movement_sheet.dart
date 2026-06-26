import 'package:cond_manager/features/materials/domain/entities/material.dart' as mat;
import 'package:cond_manager/features/materials/domain/entities/material_supplier.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/shared/domain/enums/stock_movement_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StockMovementSheet extends ConsumerStatefulWidget {
  const StockMovementSheet({super.key, required this.material});

  final mat.Material material;

  static Future<void> show(BuildContext context, mat.Material material) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: StockMovementSheet(material: material),
      ),
    );
  }

  @override
  ConsumerState<StockMovementSheet> createState() => _StockMovementSheetState();
}

class _StockMovementSheetState extends ConsumerState<StockMovementSheet> {
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  StockMovementType _type = StockMovementType.entry;
  MaterialSupplierLink? _supplier;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _costController.text = widget.material.unitCost.toStringAsFixed(2);
    final links = widget.material.supplierLinks;
    if (links.isNotEmpty) {
      _supplier = links.firstWhere(
        (l) => l.isPrimary,
        orElse: () => links.first,
      );
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.'));
    if (qty == null || qty <= 0) return;

    if (_type == StockMovementType.entry &&
        widget.material.supplierLinks.isNotEmpty &&
        _supplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o fornecedor da compra.')),
      );
      return;
    }

    final unitCost = double.tryParse(_costController.text.replaceAll(',', '.')) ??
        widget.material.unitCost;

    setState(() => _loading = true);

    final result = await ref.read(materialRepositoryProvider).createStockMovement(
          mat.StockMovementInput(
            materialId: widget.material.id,
            condominiumId: widget.material.condominiumId,
            movementType: _type,
            quantity: qty,
            unitCost: unitCost,
            providerId: _type == StockMovementType.entry ? _supplier?.providerId : null,
            notes: _notesController.text,
          ),
        );

    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(materialDetailProvider(widget.material.id));
        ref.invalidate(materialStockMovementsProvider(widget.material.id));
        ref.invalidate(
          materialSupplierPurchasesProvider(
            MaterialSupplierPurchasesQuery(materialId: widget.material.id),
          ),
        );
        ref.invalidate(materialsListProvider);
        ref.invalidate(materialBalanceSummaryProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movimentação registrada.'),
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
    final suppliers = widget.material.supplierLinks;

    return ClaySurface(
      depth: ClayDepth.floating,
      radius: ClayTokens.radiusLg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Movimentação de estoque',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ClayDropdownField<StockMovementType>(
            label: 'Tipo *',
            value: _type,
            items: const [StockMovementType.entry, StockMovementType.exit],
            itemLabel: (t) => t.label,
            onChanged: (v) => setState(() => _type = v ?? StockMovementType.entry),
          ),
          if (_type == StockMovementType.entry && suppliers.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClayDropdownField<MaterialSupplierLink>(
              label: 'Fornecedor da compra *',
              value: _supplier,
              items: suppliers,
              itemLabel: (s) => s.displayName,
              onChanged: (v) => setState(() => _supplier = v),
            ),
            const SizedBox(height: 12),
            ClayTextField(
              controller: _costController,
              label: 'Custo unitário (R\$)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
          const SizedBox(height: 12),
          ClayTextField(
            controller: _qtyController,
            label: 'Quantidade *',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          ClayTextField(
            controller: _notesController,
            label: 'Observações',
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          ClayButton(
            label: 'Registrar',
            icon: Icons.inventory_rounded,
            isLoading: _loading,
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
