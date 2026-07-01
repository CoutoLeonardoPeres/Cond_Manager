import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:cond_manager/features/tickets/presentation/widgets/ticket_status_chip.dart';
import 'package:cond_manager/shared/domain/priority_level_style.dart';
import 'package:cond_manager/shared/widgets/priority_badge.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:cond_manager/shared/widgets/form/filter_carousel_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TicketsListPage extends ConsumerWidget {
  const TicketsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsListProvider);
    final filter = ref.watch(ticketListFilterProvider);
    final condosAsync = ref.watch(condominiumsListProvider);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FiltersBar(
              filter: filter,
              condosAsync: condosAsync,
              onFilterChanged: (f) => ref.read(ticketListFilterProvider.notifier).state = f,
            ),
            Expanded(
              child: ticketsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(ticketsListProvider),
                ),
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return _EmptyState(
                      onCreate: () => context.go('/tickets/new'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(ticketsListProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                      itemCount: tickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return _TicketTile(
                          ticket: ticket,
                          dateLabel: dateFmt.format(ticket.createdAt.toLocal()),
                          onTap: () => goWithReturn(
                            context,
                            '/tickets/${ticket.id}',
                            returnTo: '/tickets',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: ClayButton(
            label: 'Novo chamado',
            expand: false,
            icon: Icons.add_rounded,
            onPressed: () => context.go('/tickets/new'),
          ),
        ),
      ],
    );
  }
}

class _FiltersBar extends ConsumerWidget {
  const _FiltersBar({
    required this.filter,
    required this.condosAsync,
    required this.onFilterChanged,
  });

  final TicketListFilter filter;
  final AsyncValue<List<Condominium>> condosAsync;
  final void Function(TicketListFilter) onFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ticketFilterStatuses.map((status) {
          final label = status?.label ?? 'Todos status';
          final selected = filter.status == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: label,
              selected: selected,
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
                        onTap: () => onFilterChanged(
                          filter.copyWith(clearCondominium: true),
                        ),
                      ),
                      ...condos.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: c.name,
                            selected: filter.condominiumId == c.id,
                            onTap: () => onFilterChanged(
                              filter.copyWith(condominiumId: c.id),
                            ),
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
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({
    required this.ticket,
    required this.dateLabel,
    required this.onTap,
  });

  final Ticket ticket;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priorityColors = PriorityLevelStyle.colors(ticket.priority);

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
            child: Icon(Icons.support_agent_rounded, color: priorityColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ticket.displayNumber} · ${ticket.title}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (ticket.condominiumName != null) ticket.condominiumName!,
                    ticket.serviceType.label,
                    dateLabel,
                  ].join(' · '),
                  style: const TextStyle(
                    color: ClayTokens.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TicketStatusChip(status: ticket.status),
                    const SizedBox(width: 12),
                    PriorityBadge(priority: ticket.priority),
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
  const _EmptyState({required this.onCreate});

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
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ClayTokens.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 40,
                  color: ClayTokens.secondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nenhum chamado encontrado',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Abra um chamado para reportar uma manutenção ou solicitação.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ClayTokens.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              ClayButton(
                label: 'Abrir chamado',
                icon: Icons.add_rounded,
                onPressed: onCreate,
              ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClaySurface(
          depth: ClayDepth.floating,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: ClayTokens.error, size: 40),
              const SizedBox(height: 12),
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
      ),
    );
  }
}
