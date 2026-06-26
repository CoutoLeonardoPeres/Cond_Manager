import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/utils/work_order_permissions.dart';
import 'package:cond_manager/features/work_orders/presentation/widgets/add_work_order_labor_sheet.dart';
import 'package:cond_manager/features/work_orders/presentation/widgets/add_work_order_material_sheet.dart';
import 'package:cond_manager/features/work_orders/presentation/widgets/work_order_labor_section.dart';
import 'package:cond_manager/features/work_orders/presentation/widgets/work_order_materials_section.dart';
import 'package:cond_manager/features/tickets/presentation/widgets/status_audit_section.dart';
import 'package:cond_manager/features/work_orders/presentation/widgets/work_order_status_chip.dart';
import 'package:cond_manager/shared/widgets/priority_badge.dart';
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
    final statusChangesAsync = ref.watch(workOrderStatusChangesProvider(widget.workOrderId));
    final profile = ref.watch(currentProfileProvider).value;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return woAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (wo) {
        final canManage = profile?.canManageWorkOrderIn(wo.condominiumId) ?? false;
        final canChangeStatus =
            profile?.canChangeWorkOrderStatus(wo.status, wo.condominiumId) ?? false;
        final canDelete =
            canManage && (profile?.permissions.canDeleteRecordsInCondominium(wo.condominiumId) ?? false);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final inlineStatus = constraints.maxWidth >= 600;
                  final statusCard = canChangeStatus
                      ? _WorkOrderStatusUpdateCard(
                          workOrder: wo,
                          updating: _updatingStatus,
                          onStatusSelected: _updateStatus,
                          compact: inlineStatus,
                        )
                      : wo.status.isLockedForNonManagers && canManage
                          ? _WorkOrderStatusLockedNotice()
                          : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => context.go('/work-orders'),
                            icon: const Icon(Icons.arrow_back_rounded),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            wo.displayNumber,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          if (inlineStatus && statusCard != null) ...[
                            const SizedBox(width: 12),
                            Expanded(child: statusCard),
                          ] else
                            const Spacer(),
                          const SizedBox(width: 12),
                          WorkOrderStatusChip(status: wo.status),
                        ],
                      ),
                      if (!inlineStatus && statusCard != null) ...[
                        const SizedBox(height: 12),
                        statusCard,
                      ],
                      const SizedBox(height: 8),
                      Text(
                        wo.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          PriorityBadge(priority: wo.priority),
                          const SizedBox(width: 16),
                          Text(
                            wo.serviceType.label,
                            style: const TextStyle(color: ClayTokens.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final infoCard = ClaySurface(
                    depth: ClayDepth.raised,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow('Condomínio', wo.condominiumName ?? '—'),
                        _InfoRow('Responsável', wo.assigneeLabel),
                        if (wo.ticketId != null)
                          _InfoRow(
                            'Chamado vinculado',
                            wo.ticketNumber != null
                                ? 'CH-${wo.ticketNumber!.toString().padLeft(5, '0')}'
                                : 'Sim',
                          ),
                        if (wo.ticketTitle != null)
                          _InfoRow('Título do chamado', wo.ticketTitle!),
                        _InfoRow('Local', wo.locationType.label),
                        if (wo.locationDescription?.isNotEmpty == true)
                          _InfoRow('Detalhes', wo.locationDescription!),
                        _InfoRow(
                          'Criada em',
                          dateFmt.format(wo.createdAt.toLocal()),
                        ),
                        if (wo.createdByName != null)
                          _InfoRow('Criada por', wo.createdByName!),
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
                          Text(wo.description!, style: const TextStyle(height: 1.45, fontSize: 13)),
                        ],
                      ],
                    ),
                  );

                  final auditLog = statusChangesAsync.when(
                    data: (changes) => changes.isEmpty
                        ? const SizedBox.shrink()
                        : ClaySurface(
                            depth: ClayDepth.raised,
                            padding: const EdgeInsets.all(16),
                            child: StatusAuditSection(
                              changes: changes,
                              title: 'Log de alterações',
                              newestFirst: true,
                              embedded: true,
                            ),
                          ),
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  );

                  final actions = _WorkOrderQuickActions(
                    workOrder: wo,
                    canManage: canManage,
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: infoCard),
                        const SizedBox(width: 16),
                        Expanded(child: auditLog),
                        const SizedBox(width: 16),
                        SizedBox(width: 220, child: actions),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      infoCard,
                      const SizedBox(height: 12),
                      auditLog,
                      const SizedBox(height: 12),
                      actions,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final materials = WorkOrderMaterialsSection(
                    workOrder: wo,
                    canManage: canManage,
                    canDelete: canDelete,
                    showLaunchButton: false,
                  );
                  final labor = WorkOrderLaborSection(
                    workOrder: wo,
                    canManage: canManage,
                    canDelete: canDelete,
                    showLaunchButton: false,
                  );

                  if (constraints.maxWidth >= 720) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: materials),
                          const SizedBox(width: 16),
                          Expanded(child: labor),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      materials,
                      const SizedBox(height: 16),
                      labor,
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkOrderStatusLockedNotice extends StatelessWidget {
  const _WorkOrderStatusLockedNotice();

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: const Text(
        'OS concluída ou cancelada — alteração de status apenas para Admin ou Gerente.',
        style: TextStyle(fontSize: 11, color: ClayTokens.textMuted, height: 1.35),
      ),
    );
  }
}

class _WorkOrderStatusUpdateCard extends StatelessWidget {
  const _WorkOrderStatusUpdateCard({
    required this.workOrder,
    required this.updating,
    required this.onStatusSelected,
    this.compact = false,
  });

  final WorkOrder workOrder;
  final bool updating;
  final ValueChanged<WorkOrderStatus> onStatusSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WorkOrderStatus.operationalStatuses
          .where((s) => s != workOrder.status)
          .map(
            (status) => ActionChip(
              label: Text(status.label),
              onPressed: updating ? null : () => onStatusSelected(status),
            ),
          )
          .toList(),
    );

    return ClaySurface(
      depth: ClayDepth.raised,
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            const Text(
              'Atualizar status',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aberta → Aguardando Material → Em execução → Concluída',
              style: TextStyle(fontSize: 12, color: ClayTokens.textSecondary),
            ),
            const SizedBox(height: 12),
          ],
          chips,
          if (updating) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _WorkOrderQuickActions extends StatelessWidget {
  const _WorkOrderQuickActions({
    required this.workOrder,
    required this.canManage,
  });

  final WorkOrder workOrder;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final wo = workOrder;
    final buttons = <Widget>[];

    if (wo.ticketId != null) {
      buttons.add(
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
      );
    }

    if (canManage) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 10));
      buttons.add(
        ClayButton(
          label: 'Lançar material',
          icon: Icons.add_shopping_cart_rounded,
          onPressed: () => AddWorkOrderMaterialSheet.show(context, wo),
        ),
      );
      buttons.add(const SizedBox(height: 10));
      buttons.add(
        ClayButton(
          label: 'Lançar mão de obra',
          icon: Icons.engineering_rounded,
          onPressed: () => AddWorkOrderLaborSheet.show(context, wo),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons,
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
