import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/utils/work_order_permissions.dart';
import 'package:cond_manager/features/work_orders/presentation/widgets/work_order_status_chip.dart';
import 'package:cond_manager/shared/domain/priority_level_style.dart';
import 'package:cond_manager/shared/widgets/priority_badge.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:cond_manager/shared/widgets/form/filter_carousel_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class WorkOrdersListPage extends ConsumerWidget {
  const WorkOrdersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(workOrdersListProvider);
    final filter = ref.watch(workOrderListFilterProvider);
    final condosAsync = ref.watch(condominiumsListProvider);
    final canCreate = ref.watch(currentProfileProvider).value?.canCreateWorkOrdersAnywhere ?? false;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FiltersBar(
              filter: filter,
              condosAsync: condosAsync,
              onFilterChanged: (f) => ref.read(workOrderListFilterProvider.notifier).state = f,
            ),
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(workOrdersListProvider),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return _EmptyState(
                      canCreate: canCreate,
                      onCreate: () => context.go('/work-orders/new'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(workOrdersListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final wo = orders[index];
                        return _WorkOrderTile(
                          workOrder: wo,
                          dateLabel: dateFmt.format(wo.createdAt.toLocal()),
                          onTap: () => context.go('/work-orders/${wo.id}'),
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
              label: 'Nova OS',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go('/work-orders/new'),
            ),
          ),
      ],
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.filter,
    required this.condosAsync,
    required this.onFilterChanged,
  });

  final WorkOrderListFilter filter;
  final AsyncValue<List<Condominium>> condosAsync;
  final void Function(WorkOrderListFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final statusRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: workOrderFilterStatuses.map((status) {
          final label = status?.label ?? 'Todos status';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: label,
              selected: filter.status == status,
              onTap: () => onFilterChanged(
                status == null
                    ? filter.copyWith(clearStatus: true)
                    : filter.copyWith(status: status),
              ),
            ),
          );
        }).toList(),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useCarousel = constraints.maxWidth < FilterCarouselLayout.mobileBreakpoint;

          return condosAsync.when(
            data: (condos) {
              Widget? condoRow;
              if (condos.length > 1) {
                condoRow = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Todos condomínios',
                        selected: filter.condominiumId == null,
                        onTap: () => onFilterChanged(filter.copyWith(clearCondominium: true)),
                      ),
                      ...condos.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: c.name,
                            selected: filter.condominiumId == c.id,
                            onTap: () => onFilterChanged(filter.copyWith(condominiumId: c.id)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (useCarousel && condoRow != null) {
                return FilterCarouselLayout(
                  items: [condoRow, statusRow],
                  itemHeight: 48,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (condoRow != null) ...[
                    condoRow,
                    const SizedBox(height: 10),
                  ],
                  statusRow,
                ],
              );
            },
            loading: () => statusRow,
            error: (_, _) => statusRow,
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
      child: ClaySurface(
        depth: selected ? ClayDepth.floating : ClayDepth.raised,
        radius: ClayTokens.radiusFull,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? ClayTokens.primary : ClayTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _WorkOrderTile extends StatelessWidget {
  const _WorkOrderTile({
    required this.workOrder,
    required this.dateLabel,
    required this.onTap,
  });

  final WorkOrder workOrder;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priorityColors = PriorityLevelStyle.colors(workOrder.priority);

    return ClayCard(
      onTap: onTap,
      radius: ClayTokens.radiusCard,
      padding: const EdgeInsets.all(16),
      backgroundColor: priorityColors.cardBackground,
      glass: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: priorityColors.iconBackground,
              borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
              border: Border.all(color: priorityColors.accent.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.assignment_rounded, color: priorityColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${workOrder.displayNumber} · ${workOrder.title}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (workOrder.condominiumName != null) workOrder.condominiumName!,
                    workOrder.assigneeLabel,
                    if (workOrder.ticketNumber != null)
                      'CH-${workOrder.ticketNumber!.toString().padLeft(5, '0')}',
                    dateLabel,
                  ].join(' · '),
                  style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    WorkOrderStatusChip(status: workOrder.status),
                    const SizedBox(width: 12),
                    PriorityBadge(priority: workOrder.priority),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: priorityColors.accent.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canCreate, required this.onCreate});

  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClaySurface(
          depth: ClayDepth.floating,
          radius: ClayTokens.radiusXl,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_outlined, size: 48, color: ClayTokens.primary),
              const SizedBox(height: 16),
              Text(
                'Nenhuma ordem de serviço',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crie uma OS para designar funcionário interno ou prestador.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ClayTokens.textSecondary),
              ),
              if (canCreate) ...[
                const SizedBox(height: 24),
                ClayButton(label: 'Nova OS', icon: Icons.add_rounded, onPressed: onCreate),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClaySurface(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ClayButton(
              label: 'Tentar novamente',
              variant: ClayButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
