import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order_material.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_material_providers.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/widgets/add_work_order_material_sheet.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WorkOrderMaterialsSection extends ConsumerWidget {
  const WorkOrderMaterialsSection({
    super.key,
    required this.workOrder,
    required this.canManage,
    this.canDelete = false,
    this.showLaunchButton = true,
  });

  final WorkOrder workOrder;
  final bool canManage;
  final bool canDelete;
  final bool showLaunchButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(workOrderMaterialsProvider(workOrder.id));
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return totalsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text('Erro ao carregar materiais: $e'),
      data: (totals) => ClaySurface(
        depth: ClayDepth.raised,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Materiais e equipamentos',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            if (canManage && showLaunchButton) ...[
              const SizedBox(height: 12),
              ClayButton(
                label: 'Lançar material',
                icon: Icons.add_shopping_cart_rounded,
                expand: false,
                onPressed: () => AddWorkOrderMaterialSheet.show(context, workOrder),
              ),
            ],
            const SizedBox(height: 4),
            const Text(
              'Custos operacionais (compra + impostos) e repasse ao condomínio.',
              style: TextStyle(color: ClayTokens.textSecondary, fontSize: 12, height: 1.35),
            ),
            if (totals.lines.isEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Nenhum material lançado nesta OS.',
                style: TextStyle(color: ClayTokens.textMuted),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ...totals.lines.map(
                (line) => _MaterialLineTile(
                  line: line,
                  currency: currency,
                  canDelete: canDelete,
                  onRemove: () => _removeLine(context, ref, line),
                ),
              ),
              const Divider(height: 24),
              _TotalsRow('Custo total (s/ imp.)', currency.format(totals.totalCost)),
              _TotalsRow('Custo total c/ impostos', currency.format(totals.totalCostWithTax)),
              _TotalsRow('Repasse total (s/ imp.)', currency.format(totals.totalResale)),
              _TotalsRow('Repasse total c/ impostos', currency.format(totals.totalResaleWithTax)),
              _TotalsRow(
                'Margem estimada',
                currency.format(totals.marginWithTax),
                highlight: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _removeLine(
    BuildContext context,
    WidgetRef ref,
    WorkOrderMaterialLine line,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover lançamento?'),
        content: Text(
          'O material "${line.materialName}" será removido da OS. '
          'Se houve baixa de estoque, o saldo será restaurado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ref
        .read(workOrderRepositoryProvider)
        .removeMaterial(line.id, workOrder.id);

    if (!context.mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(workOrderMaterialsProvider(workOrder.id));
        ref.invalidate(workOrderDetailProvider(workOrder.id));
        if (line.materialId != null) {
          ref.invalidate(materialDetailProvider(line.materialId!));
        }
        ref.invalidate(materialsListProvider);
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }
}

class _MaterialLineTile extends StatelessWidget {
  const _MaterialLineTile({
    required this.line,
    required this.currency,
    required this.canDelete,
    required this.onRemove,
  });

  final WorkOrderMaterialLine line;
  final NumberFormat currency;
  final bool canDelete;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClaySurface(
        depth: ClayDepth.pressed,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.materialName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${line.quantity} ${line.unitOfMeasure} · '
                    'Custo: ${currency.format(line.totalCostWithTax)} · '
                    'Repasse: ${currency.format(line.totalResaleWithTax)}',
                    style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary),
                  ),
                ],
              ),
            ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: ClayTokens.error,
                onPressed: onRemove,
                tooltip: 'Remover',
              ),
          ],
        ),
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: highlight ? null : ClayTokens.textSecondary,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: highlight ? ClayTokens.success : null,
            ),
          ),
        ],
      ),
    );
  }
}
