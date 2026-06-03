import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/utils/work_order_permissions.dart';
import 'package:cond_manager/features/work_orders/presentation/widgets/work_order_labor_section.dart';
import 'package:cond_manager/features/work_orders/presentation/widgets/work_order_materials_section.dart';
import 'package:cond_manager/features/work_orders/presentation/widgets/work_order_status_chip.dart';
import 'package:cond_manager/shared/domain/enums/work_order_status.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class WorkOrderDetailPage extends ConsumerStatefulWidget {
  const WorkOrderDetailPage({super.key, required this.workOrderId});

  final String workOrderId;

  @override
  ConsumerState<WorkOrderDetailPage> createState() => _WorkOrderDetailPageState();
}

class _WorkOrderDetailPageState extends ConsumerState<WorkOrderDetailPage> {
  bool _updatingStatus = false;

  Future<void> _updateStatus(WorkOrderStatus status) async {
    setState(() => _updatingStatus = true);
    final result = await ref
        .read(workOrderRepositoryProvider)
        .updateStatus(widget.workOrderId, status);

    if (!mounted) return;
    setState(() => _updatingStatus = false);

    result.when(
      success: (_) {
        ref.invalidate(workOrderDetailProvider(widget.workOrderId));
        ref.invalidate(workOrdersListProvider);
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final woAsync = ref.watch(workOrderDetailProvider(widget.workOrderId));
    final profile = ref.watch(currentProfileProvider).value;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return woAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (wo) {
        final canManage = profile?.canManageWorkOrderIn(wo.condominiumId) ?? false;
        final canDelete =
            canManage && (profile?.permissions.canDeleteRecordsInCondominium(wo.condominiumId) ?? false);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/work-orders'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      wo.displayNumber,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  WorkOrderStatusChip(status: wo.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                wo.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  WorkOrderPriorityBadge(priority: wo.priority),
                  const SizedBox(width: 16),
                  Text(wo.serviceType.label, style: const TextStyle(color: ClayTokens.textSecondary)),
                ],
              ),
              const SizedBox(height: 20),
              ClaySurface(
                depth: ClayDepth.raised,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow('Condomínio', wo.condominiumName ?? '—'),
                    _InfoRow('Responsável', wo.assigneeLabel),
                    if (wo.ticketId != null) ...[
                      _InfoRow(
                        'Chamado vinculado',
                        wo.ticketNumber != null
                            ? 'CH-${wo.ticketNumber!.toString().padLeft(5, '0')}'
                            : 'Sim',
                      ),
                      _InfoRow('ID do chamado', wo.ticketId!),
                    ],
                    if (wo.ticketTitle != null) _InfoRow('Título do chamado', wo.ticketTitle!),
                    _InfoRow('Local', wo.locationType.label),
                    if (wo.locationDescription?.isNotEmpty == true)
                      _InfoRow('Detalhes', wo.locationDescription!),
                    _InfoRow('Criada em', dateFmt.format(wo.createdAt.toLocal())),
                    if (wo.createdByName != null) _InfoRow('Criada por', wo.createdByName!),
                    if (wo.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Descrição',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ClayTokens.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(wo.description!, style: const TextStyle(height: 1.45)),
                    ],
                  ],
                ),
              ),
              if (wo.ticketId != null) ...[
                const SizedBox(height: 12),
                ClayButton(
                  label: 'Ver chamado vinculado',
                  variant: ClayButtonVariant.secondary,
                  icon: Icons.support_agent_rounded,
                  onPressed: () => goWithReturn(
                    context,
                    '/tickets/${wo.ticketId}',
                    returnTo: '/work-orders/${wo.id}',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              WorkOrderMaterialsSection(
                workOrder: wo,
                canManage: canManage,
                canDelete: canDelete,
              ),
              const SizedBox(height: 16),
              WorkOrderLaborSection(
                workOrder: wo,
                canManage: canManage,
                canDelete: canDelete,
              ),
              if (canManage) ...[
                const SizedBox(height: 16),
                ClaySurface(
                  depth: ClayDepth.raised,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Atualizar status', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: WorkOrderStatus.values
                            .where((s) => s != wo.status)
                            .map(
                              (status) => ActionChip(
                                label: Text(status.label),
                                onPressed: _updatingStatus
                                    ? null
                                    : () => _updateStatus(status),
                              ),
                            )
                            .toList(),
                      ),
                      if (_updatingStatus) const LinearProgressIndicator(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: ClayTokens.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
