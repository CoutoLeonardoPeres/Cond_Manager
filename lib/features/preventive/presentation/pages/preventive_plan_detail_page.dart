import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/preventive/presentation/providers/preventive_providers.dart';
import 'package:cond_manager/features/preventive/presentation/utils/preventive_permissions.dart';
import 'package:cond_manager/features/preventive/utils/preventive_schedule.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PreventivePlanDetailPage extends ConsumerWidget {
  const PreventivePlanDetailPage({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(preventivePlanDetailProvider(planId));
    final profile = ref.watch(currentProfileProvider).value;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return planAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (e, _) => Center(child: Text('$e')),
      data: (p) {
        final canManage = profile != null && profile.canManagePreventiveIn(p.condominiumId);
        final today = PreventiveSchedule.todayLocal();
        final inAlert = PreventiveSchedule.shouldAppearInBacklog(
          PreventiveSchedule.dateOnly(p.nextDueDate),
          p.leadTimeDays,
          today,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/preventive'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      p.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (canManage)
                    IconButton(
                      onPressed: () => context.go('/preventive/$planId/edit'),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                ],
              ),
              if (inAlert) ...[
                const SizedBox(height: 12),
                ClaySurface(
                  depth: ClayDepth.pressed,
                  color: ClayTokens.warning.withValues(alpha: 0.12),
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: ClayTokens.warning),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este plano está no período de alerta. Processe a agenda na aba Backlog OS.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ClaySurface(
                depth: ClayDepth.raised,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Row('Condomínio', p.condominiumName ?? '—'),
                    _Row('Serviço', p.serviceType.label),
                    _Row('Periodicidade', p.frequency.label),
                    _Row('Próxima execução', dateFmt.format(p.nextDueDate)),
                    _Row('Alerta (dias antes)', '${p.leadTimeDays}'),
                    _Row('OS automática', p.autoGenerateOs ? 'Sim' : 'Não'),
                    _Row('Responsável', p.assigneeLabel),
                    _Row('Status', p.status.label),
                    if (p.description?.isNotEmpty == true) _Row('Descrição', p.description!),
                  ],
                ),
              ),
              if (p.checklistItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClaySurface(
                  depth: ClayDepth.raised,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Checklist', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...p.checklistItems.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• ${c.description}'),
                        ),
                      ),
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
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
            width: 140,
            child: Text(label, style: const TextStyle(color: ClayTokens.textSecondary)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
