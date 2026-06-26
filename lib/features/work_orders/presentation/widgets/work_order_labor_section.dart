import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order_labor.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_labor_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/widgets/add_work_order_labor_sheet.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WorkOrderLaborSection extends ConsumerWidget {
  const WorkOrderLaborSection({
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
    final laborAsync = ref.watch(workOrderLaborProvider(workOrder.id));
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return laborAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text('Erro ao carregar mão de obra: $e'),
      data: (totals) => ClaySurface(
        depth: ClayDepth.raised,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mão de obra e deslocamento',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            if (canManage && showLaunchButton) ...[
              const SizedBox(height: 12),
              ClayButton(
                label: 'Lançar mão de obra',
                icon: Icons.engineering_rounded,
                expand: false,
                onPressed: () => AddWorkOrderLaborSheet.show(context, workOrder),
              ),
            ],
            const SizedBox(height: 4),
            const Text(
              'Homem hora por categoria (ex.: eletricista, pedreiro), quantidade de '
              'profissionais, valor/hora e deslocamento — terceiros ou equipe própria.',
              style: TextStyle(color: ClayTokens.textSecondary, fontSize: 12, height: 1.35),
            ),
            if (totals.lines.isEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Nenhum lançamento de mão de obra nesta OS.',
                style: TextStyle(color: ClayTokens.textMuted),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ...totals.lines.map(
                (line) => _LaborLineTile(
                  line: line,
                  currency: currency,
                  canDelete: canDelete,
                  onRemove: () => _removeLine(context, ref, line),
                ),
              ),
              const Divider(height: 24),
              _TotalsRow('Total homem hora', '${totals.totalManHours.toStringAsFixed(1)} h'),
              _TotalsRow('Subtotal HH', currency.format(totals.totalLaborSubtotal)),
              _TotalsRow('Deslocamento', currency.format(totals.totalTravel)),
              _TotalsRow('Terceirizados', currency.format(totals.thirdPartyTotal)),
              _TotalsRow('Equipe própria', currency.format(totals.internalTotal)),
              _TotalsRow('Total mão de obra', currency.format(totals.grandTotal), highlight: true),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _removeLine(
    BuildContext context,
    WidgetRef ref,
    WorkOrderLaborLine line,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover lançamento?'),
        content: Text(
          'Remover mão de obra de ${line.serviceType.label} (${line.workerName})?',
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
        .removeLabor(line.id, workOrder.id);

    if (!context.mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(workOrderLaborProvider(workOrder.id));
        ref.invalidate(workOrderDetailProvider(workOrder.id));
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }
}

class _LaborLineTile extends StatelessWidget {
  const _LaborLineTile({
    required this.line,
    required this.currency,
    required this.canDelete,
    required this.onRemove,
  });

  final WorkOrderLaborLine line;
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
                  Text(
                    '${line.serviceType.label} · ${line.sourceLabel}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    line.workerName,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${line.workerCount} prof. × ${line.hours} h × ${currency.format(line.hourlyRate)}/h '
                    '· HH: ${currency.format(line.laborSubtotal)}'
                    '${line.travelCost > 0 ? ' · Desloc.: ${currency.format(line.travelCost)}' : ''}',
                    style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary),
                  ),
                  Text(
                    'Total: ${currency.format(line.totalCost)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
