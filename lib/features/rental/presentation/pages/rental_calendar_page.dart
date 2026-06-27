import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_chart.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_occupancy_view.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RentalCalendarPage extends ConsumerWidget {
  const RentalCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(rentalOccupancyViewModeProvider);
    final anchor = ref.watch(rentalOccupancyAnchorProvider);
    final range = ref.watch(rentalOccupancyRangeProvider);
    final propertiesAsync = ref.watch(rentalPropertiesListProvider);
    final bookingsAsync = ref.watch(rentalGanttBookingsProvider);
    final leasesAsync = ref.watch(rentalGanttLeasesProvider);
    final periodLabel = rentalOccupancyPeriodLabel(viewMode, anchor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mapa de ocupação',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Visualize a ocupação por imóvel. Escolha dia, semana, mês ou ano e navegue pelo período.',
                style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 520;
                  if (isWide) {
                    return SegmentedButton<RentalOccupancyViewMode>(
                      segments: RentalOccupancyViewMode.values
                          .map(
                            (m) => ButtonSegment(
                              value: m,
                              label: Text(m.label),
                              icon: Icon(m.icon, size: 18),
                            ),
                          )
                          .toList(),
                      selected: {viewMode},
                      onSelectionChanged: (selected) {
                        ref.read(rentalOccupancyViewModeProvider.notifier).state = selected.first;
                      },
                    );
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<RentalOccupancyViewMode>(
                      segments: RentalOccupancyViewMode.values
                          .map((m) => ButtonSegment(value: m, label: Text(m.label)))
                          .toList(),
                      selected: {viewMode},
                      onSelectionChanged: (selected) {
                        ref.read(rentalOccupancyViewModeProvider.notifier).state = selected.first;
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: rentalOccupancyNavTooltip(viewMode, -1),
                    onPressed: () {
                      ref.read(rentalOccupancyAnchorProvider.notifier).state =
                          rentalOccupancyStepAnchor(viewMode, anchor, -1);
                    },
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      periodLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ClayButton(
                    label: 'Hoje',
                    expand: false,
                    onPressed: () {
                      ref.read(rentalOccupancyAnchorProvider.notifier).state =
                          rentalGanttDateOnly(DateTime.now());
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: rentalOccupancyNavTooltip(viewMode, 1),
                    onPressed: () {
                      ref.read(rentalOccupancyAnchorProvider.notifier).state =
                          rentalOccupancyStepAnchor(viewMode, anchor, 1);
                    },
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: propertiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
            error: (e, _) => Center(child: Text('$e')),
            data: (properties) {
              if (properties.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Cadastre imóveis para visualizar o mapa de ocupação.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ClayTokens.textSecondary),
                    ),
                  ),
                );
              }

              return bookingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (bookings) => leasesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (leases) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: ClayCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            Expanded(
                              child: RentalGanttChart(
                                key: ValueKey('${viewMode.name}-${range.start}'),
                                properties: properties,
                                bookings: bookings,
                                leases: leases,
                                range: range,
                                viewMode: viewMode,
                              ),
                            ),
                            const _GanttLegend(),
                          ],
                        ),
                      ),
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
}

class _GanttLegend extends StatelessWidget {
  const _GanttLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ClayTokens.surfacePressed.withValues(alpha: 0.4),
        border: Border(
          top: BorderSide(color: ClayTokens.textMuted.withValues(alpha: 0.25)),
        ),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: const [
          _LegendSwatch(
            gradient: LinearGradient(colors: [ClayTokens.tertiary, ClayTokens.accent]),
            label: 'Reserva (curta temporada)',
          ),
          _LegendSwatch(
            gradient: LinearGradient(colors: [Color(0xFF34D399), ClayTokens.success]),
            label: 'Contrato ativo (longo prazo)',
          ),
          _LegendDot(color: ClayTokens.primary, label: 'Hoje'),
          _LegendFree(label: 'Livre — célula sem barra'),
        ],
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.gradient, required this.label});

  final Gradient gradient;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 10,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 3, height: 14, color: color.withValues(alpha: 0.55)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary)),
      ],
    );
  }
}

class _LegendFree extends StatelessWidget {
  const _LegendFree({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 10,
          decoration: BoxDecoration(
            color: ClayTokens.surfaceRaised,
            border: Border.all(color: ClayTokens.textMuted.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary)),
      ],
    );
  }
}
