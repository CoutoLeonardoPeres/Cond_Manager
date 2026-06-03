import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/preventive/domain/entities/preventive_plan.dart';
import 'package:cond_manager/features/preventive/presentation/providers/preventive_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/features/preventive/presentation/utils/preventive_permissions.dart';
import 'package:cond_manager/shared/domain/enums/preventive_execution_status.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PreventiveBacklogTab extends ConsumerStatefulWidget {
  const PreventiveBacklogTab({super.key, this.condominiumId});

  final String? condominiumId;

  @override
  ConsumerState<PreventiveBacklogTab> createState() => _PreventiveBacklogTabState();
}

class _PreventiveBacklogTabState extends ConsumerState<PreventiveBacklogTab> {
  bool _syncing = false;

  Future<void> _syncAgenda() async {
    setState(() => _syncing = true);
    final result = await ref
        .read(preventiveRepositoryProvider)
        .syncAgenda(condominiumId: widget.condominiumId);

    if (!mounted) return;
    setState(() => _syncing = false);

    result.when(
      success: (r) {
        ref.invalidate(preventiveBacklogProvider);
        ref.invalidate(preventivePlansListProvider);
        ref.invalidate(workOrdersListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Agenda processada: ${r.executionsCreated} itens no backlog, '
              '${r.workOrdersCreated} OS geradas.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    final backlogAsync = ref.watch(preventiveBacklogProvider(widget.condominiumId));
    final profile = ref.watch(currentProfileProvider).value;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: ClayButton(
                  label: _syncing ? 'Processando...' : 'Processar agenda',
                  variant: ClayButtonVariant.secondary,
                  expand: false,
                  icon: Icons.notifications_active_rounded,
                  isLoading: _syncing,
                  onPressed: _syncing ? null : _syncAgenda,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Gera alertas no backlog e OS automáticas (quando configurado) para prestador ou equipe.',
            style: TextStyle(color: ClayTokens.textSecondary, fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: backlogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
            error: (e, _) => Center(child: Text('$e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Backlog vazio. Toque em "Processar agenda" para verificar planos no período de alerta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ClayTokens.textSecondary),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(preventiveBacklogProvider(widget.condominiumId)),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final canManage = profile != null &&
                        profile.canManagePreventiveIn(item.condominiumId);
                    return _BacklogCard(
                      item: item,
                      dateFmt: dateFmt,
                      canManage: canManage,
                      onGenerateOs: () => _generateOs(item.id),
                      onComplete: () => _complete(item.id),
                      onSkip: () => _skip(item.id),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _generateOs(String executionId) async {
    final result =
        await ref.read(preventiveRepositoryProvider).generateWorkOrder(executionId);
    if (!mounted) return;
    result.when(
      success: (woId) {
        ref.invalidate(preventiveBacklogProvider);
        ref.invalidate(workOrdersListProvider);
        context.go('/work-orders/$woId');
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      ),
    );
  }

  Future<void> _complete(String executionId) async {
    final result = await ref
        .read(preventiveRepositoryProvider)
        .completeExecution(executionId);
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(preventiveBacklogProvider);
        ref.invalidate(preventivePlansListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preventiva concluída. Próxima data atualizada.')),
        );
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      ),
    );
  }

  Future<void> _skip(String executionId) async {
    final result =
        await ref.read(preventiveRepositoryProvider).skipExecution(executionId);
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(preventiveBacklogProvider);
        ref.invalidate(preventivePlansListProvider);
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      ),
    );
  }
}

class _BacklogCard extends StatelessWidget {
  const _BacklogCard({
    required this.item,
    required this.dateFmt,
    required this.canManage,
    required this.onGenerateOs,
    required this.onComplete,
    required this.onSkip,
  });

  final PreventiveBacklogItem item;
  final DateFormat dateFmt;
  final bool canManage;
  final VoidCallback onGenerateOs;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isOverdue = item.status == PreventiveExecutionStatus.overdue;

    return ClaySurface(
      depth: ClayDepth.raised,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.planName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOverdue ? ClayTokens.error : ClayTokens.warning)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOverdue ? ClayTokens.error : ClayTokens.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (item.condominiumName != null) item.condominiumName!,
              item.serviceType.label,
              'Previsto: ${dateFmt.format(item.scheduledDate)}',
              if (item.assigneeLabel != null) item.assigneeLabel!,
            ].join(' · '),
            style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
          ),
          if (item.hasWorkOrder) ...[
            const SizedBox(height: 8),
            Text(
              'OS: ${item.osDisplayNumber ?? item.workOrderId}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          if (canManage) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!item.hasWorkOrder)
                  ClayButton(
                    label: 'Gerar OS',
                    expand: false,
                    icon: Icons.assignment_rounded,
                    onPressed: onGenerateOs,
                  )
                else
                  ClayButton(
                    label: 'Abrir OS',
                    variant: ClayButtonVariant.secondary,
                    expand: false,
                    icon: Icons.open_in_new_rounded,
                    onPressed: () => context.go('/work-orders/${item.workOrderId}'),
                  ),
                ClayButton(
                  label: 'Concluir',
                  variant: ClayButtonVariant.secondary,
                  expand: false,
                  icon: Icons.check_rounded,
                  onPressed: onComplete,
                ),
                TextButton(onPressed: onSkip, child: const Text('Ignorar ciclo')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
