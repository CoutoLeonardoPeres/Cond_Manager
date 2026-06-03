import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/preventive/presentation/providers/preventive_providers.dart';
import 'package:cond_manager/features/preventive/presentation/utils/preventive_permissions.dart';
import 'package:cond_manager/features/preventive/utils/preventive_schedule.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PreventivePlansTab extends ConsumerWidget {
  const PreventivePlansTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(preventivePlansListProvider);
    final filter = ref.watch(preventivePlanListFilterProvider);
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final canCreate = profile != null && profile.canCreatePreventivePlan;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final today = PreventiveSchedule.todayLocal();

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: condosAsync.when(
                data: (condos) {
                  if (condos.isEmpty) return const SizedBox.shrink();
                  final items = [
                    const _CondoOpt(id: null, label: 'Todos os condomínios'),
                    ...condos.map((c) => _CondoOpt(id: c.id, label: c.name)),
                  ];
                  final sel = items.firstWhere(
                    (o) => o.id == filter.condominiumId,
                    orElse: () => items.first,
                  );
                  return ClayDropdownField<_CondoOpt>(
                    label: 'Condomínio',
                    value: sel,
                    items: items,
                    itemLabel: (o) => o.label,
                    onChanged: (v) {
                      ref.read(preventivePlanListFilterProvider.notifier).state =
                          filter.copyWith(
                        condominiumId: v?.id,
                        clearCondominium: v?.id == null,
                      );
                      ref.invalidate(preventiveBacklogProvider(v?.id));
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: plansAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (plans) {
                  if (plans.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum plano preventivo cadastrado.',
                        style: TextStyle(color: ClayTokens.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(preventivePlansListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: plans.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = plans[index];
                        final due = PreventiveSchedule.dateOnly(p.nextDueDate);
                        final alert = PreventiveSchedule.shouldAppearInBacklog(
                          due,
                          p.leadTimeDays,
                          today,
                        );
                        return ClayListTileCard(
                          icon: Icons.event_repeat_rounded,
                          iconColor: alert ? ClayTokens.warning : ClayTokens.primary,
                          title: p.name,
                          subtitle: [
                            p.frequency.label,
                            p.serviceType.label,
                            'Próxima: ${dateFmt.format(due)}',
                            p.assigneeLabel,
                          ].join(' · '),
                          onTap: () => context.go('/preventive/${p.id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (canCreate)
          Positioned(
            right: 20,
            bottom: 20,
            child: ClayButton(
              label: 'Novo plano',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go('/preventive/new'),
            ),
          ),
      ],
    );
  }
}

class _CondoOpt {
  const _CondoOpt({required this.id, required this.label});
  final String? id;
  final String label;
}
