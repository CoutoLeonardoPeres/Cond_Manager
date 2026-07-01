import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_booking_edit_sheet.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_lease_edit_sheet.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_chart.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_occupancy_view.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_quick_booking_sheet.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RentalCalendarPage extends ConsumerWidget {
  const RentalCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(rentalOccupancyViewModeProvider);
    final anchor = ref.watch(rentalOccupancyAnchorProvider);
    final horizonMonths = ref.watch(rentalOccupancyHorizonMonthsProvider);
    final range = ref.watch(rentalOccupancyRangeProvider);
    final propertiesAsync = ref.watch(rentalPropertiesListProvider);
    final bookingsAsync = ref.watch(rentalGanttBookingsProvider);
    final leasesAsync = ref.watch(rentalGanttLeasesProvider);
    final periodLabel = rentalOccupancyPeriodLabel(
      viewMode,
      anchor,
      monthHorizon: horizonMonths,
    );
    final canManage = ref.watch(currentProfileProvider).value?.permissions.canManageRental ?? false;
    final isMobile = MediaQuery.sizeOf(context).width < 640;

    void goToToday() {
      final now = rentalGanttDateOnly(DateTime.now());
      ref.read(rentalOccupancyAnchorProvider.notifier).state =
          DateTime(now.year, now.month, 1);
    }

    void stepPeriod(int delta) {
      ref.read(rentalOccupancyAnchorProvider.notifier).state =
          rentalOccupancyStepAnchor(viewMode, anchor, delta);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, isMobile ? 8 : 12, isMobile ? 12 : 20, 6),
          child: isMobile
              ? _MobileOccupancyHeader(
                  horizonMonths: horizonMonths,
                  viewMode: viewMode,
                  periodLabel: periodLabel,
                  onHorizonChanged: (m) =>
                      ref.read(rentalOccupancyHorizonMonthsProvider.notifier).state = m,
                  onViewModeChanged: (m) =>
                      ref.read(rentalOccupancyViewModeProvider.notifier).state = m,
                  onStepPeriod: stepPeriod,
                  onGoToToday: goToToday,
                  onShowLegend: () => _showOccupancyLegendSheet(context),
                )
              : _DesktopOccupancyHeader(
                  horizonMonths: horizonMonths,
                  viewMode: viewMode,
                  periodLabel: periodLabel,
                  onHorizonChanged: (m) =>
                      ref.read(rentalOccupancyHorizonMonthsProvider.notifier).state = m,
                  onViewModeChanged: (m) =>
                      ref.read(rentalOccupancyViewModeProvider.notifier).state = m,
                  onStepPeriod: stepPeriod,
                  onGoToToday: goToToday,
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
                    final chartProperties = rentalPropertiesWithVacancyInHorizon(
                      properties: properties,
                      bookings: bookings,
                      leases: leases,
                      horizonMonths: horizonMonths,
                    );

                    if (chartProperties.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Nenhum imóvel com dias livres nos próximos $horizonMonths meses.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: ClayTokens.textSecondary),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.fromLTRB(isMobile ? 8 : 12, 0, isMobile ? 8 : 12, isMobile ? 8 : 12),
                      child: ClayCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            Expanded(
                              child: RentalGanttChart(
                                key: ValueKey('${viewMode.name}-${range.start}-$horizonMonths'),
                                properties: chartProperties,
                                bookings: bookings,
                                leases: leases,
                                range: range,
                                viewMode: viewMode,
                                propertyColumnWidth: isMobile ? 108 : 200,
                                rowHeight: isMobile ? 44 : 52,
                                onCellTap: canManage
                                    ? (property, date) => showRentalQuickBookingSheet(
                                          context,
                                          ref,
                                          property: property,
                                          checkIn: date,
                                        )
                                    : null,
                                onSegmentTap: canManage
                                    ? (segment) {
                                        if (segment.kind == RentalGanttSegmentKind.booking) {
                                          showRentalBookingEditSheet(
                                            context,
                                            ref,
                                            bookingId: segment.id,
                                          );
                                        } else if (segment.kind == RentalGanttSegmentKind.lease) {
                                          showRentalLeaseEditSheet(
                                            context,
                                            ref,
                                            leaseId: segment.id,
                                          );
                                        }
                                      }
                                    : null,
                              ),
                            ),
                            if (!isMobile) const _GanttLegend(),
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

void _showOccupancyLegendSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: ClayTokens.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ClayTokens.radiusLg)),
    ),
    builder: (ctx) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Legenda',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            SizedBox(height: 12),
            _GanttLegend(compact: true),
          ],
        ),
      ),
    ),
  );
}

class _MobileOccupancyHeader extends StatelessWidget {
  const _MobileOccupancyHeader({
    required this.horizonMonths,
    required this.viewMode,
    required this.periodLabel,
    required this.onHorizonChanged,
    required this.onViewModeChanged,
    required this.onStepPeriod,
    required this.onGoToToday,
    required this.onShowLegend,
  });

  final int horizonMonths;
  final RentalOccupancyViewMode viewMode;
  final String periodLabel;
  final ValueChanged<int> onHorizonChanged;
  final ValueChanged<RentalOccupancyViewMode> onViewModeChanged;
  final ValueChanged<int> onStepPeriod;
  final VoidCallback onGoToToday;
  final VoidCallback onShowLegend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mapa de ocupação',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Legenda',
              visualDensity: VisualDensity.compact,
              onPressed: onShowLegend,
              icon: const Icon(Icons.info_outline_rounded, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _CompactSegmentedRow<int>(
          values: rentalOccupancyHorizonOptions,
          selected: horizonMonths,
          label: (m) => '$m m',
          onChanged: onHorizonChanged,
        ),
        const SizedBox(height: 6),
        _CompactSegmentedRow<RentalOccupancyViewMode>(
          values: rentalOccupancySelectableViewModes,
          selected: viewMode,
          label: (m) => m.label,
          onChanged: onViewModeChanged,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              tooltip: rentalOccupancyNavTooltip(viewMode, -1),
              onPressed: () => onStepPeriod(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                periodLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              tooltip: rentalOccupancyNavTooltip(viewMode, 1),
              onPressed: () => onStepPeriod(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        Center(
          child: TextButton(
            onPressed: onGoToToday,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Ir para hoje'),
          ),
        ),
      ],
    );
  }
}

class _DesktopOccupancyHeader extends StatelessWidget {
  const _DesktopOccupancyHeader({
    required this.horizonMonths,
    required this.viewMode,
    required this.periodLabel,
    required this.onHorizonChanged,
    required this.onViewModeChanged,
    required this.onStepPeriod,
    required this.onGoToToday,
  });

  final int horizonMonths;
  final RentalOccupancyViewMode viewMode;
  final String periodLabel;
  final ValueChanged<int> onHorizonChanged;
  final ValueChanged<RentalOccupancyViewMode> onViewModeChanged;
  final ValueChanged<int> onStepPeriod;
  final VoidCallback onGoToToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mapa de ocupação',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Imóveis com dias livres no período selecionado. Dois meses cabem na tela — use a barra inferior para navegar.',
          style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: rentalOccupancyHorizonOptions
              .map((m) => ButtonSegment(value: m, label: Text('$m meses')))
              .toList(),
          selected: {horizonMonths},
          onSelectionChanged: (s) => onHorizonChanged(s.first),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 520;
            final segments = rentalOccupancySelectableViewModes
                .map(
                  (m) => ButtonSegment(
                    value: m,
                    label: Text(m.label),
                    icon: isWide ? Icon(m.icon, size: 18) : null,
                  ),
                )
                .toList();
            final button = SegmentedButton<RentalOccupancyViewMode>(
              segments: segments,
              selected: {viewMode},
              onSelectionChanged: (s) => onViewModeChanged(s.first),
            );
            if (isWide) return button;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: button,
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              tooltip: rentalOccupancyNavTooltip(viewMode, -1),
              onPressed: () => onStepPeriod(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                periodLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(onPressed: onGoToToday, child: const Text('Hoje')),
            IconButton(
              tooltip: rentalOccupancyNavTooltip(viewMode, 1),
              onPressed: () => onStepPeriod(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactSegmentedRow<T extends Object> extends StatelessWidget {
  const _CompactSegmentedRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final value = values[i];
          final isSelected = value == selected;
          return Material(
            color: isSelected
                ? ClayTokens.accent.withValues(alpha: 0.18)
                : ClayTokens.surfacePressed.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
            child: InkWell(
              onTap: () => onChanged(value),
              borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  label(value),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? ClayTokens.accent : ClayTokens.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GanttLegend extends StatelessWidget {
  const _GanttLegend({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = compact
        ? <Widget>[
            const _LegendSwatch(
              gradient: LinearGradient(colors: [ClayTokens.tertiary, ClayTokens.accent]),
              label: 'Reserva',
              compact: true,
            ),
            const _LegendSwatch(
              gradient: LinearGradient(colors: [Color(0xFF34D399), ClayTokens.success]),
              label: 'Contrato',
              compact: true,
            ),
            const _LegendDot(color: ClayTokens.primary, label: 'Hoje', compact: true),
            const _LegendFree(label: 'Livre', compact: true),
            const _LegendWeekend(compact: true),
          ]
        : <Widget>[
            const _LegendSwatch(
              gradient: LinearGradient(colors: [ClayTokens.tertiary, ClayTokens.accent]),
              label: 'Reserva (curta temporada)',
            ),
            const _LegendSwatch(
              gradient: LinearGradient(colors: [Color(0xFF34D399), ClayTokens.success]),
              label: 'Contrato com término definido',
            ),
            const _LegendDot(color: ClayTokens.primary, label: 'Hoje'),
            const _LegendFree(label: 'Livre — toque na célula para reservar'),
            const _LegendWeekend(),
            const _LegendTap(label: 'Toque na barra para editar reserva ou contrato'),
          ];

    if (compact) {
      return Wrap(
        spacing: 12,
        runSpacing: 10,
        children: items,
      );
    }

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
        children: items,
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({
    required this.gradient,
    required this.label,
    this.compact = false,
  });

  final Gradient gradient;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 22 : 28,
          height: compact ? 8 : 10,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: compact ? 4 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            color: ClayTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.compact = false,
  });

  final Color color;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 3, height: compact ? 12 : 14, color: color.withValues(alpha: 0.55)),
        SizedBox(width: compact ? 4 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            color: ClayTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LegendFree extends StatelessWidget {
  const _LegendFree({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 22 : 28,
          height: compact ? 8 : 10,
          decoration: BoxDecoration(
            color: ClayTokens.surfaceRaised,
            border: Border.all(color: ClayTokens.textMuted.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: compact ? 4 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            color: ClayTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LegendWeekend extends StatelessWidget {
  const _LegendWeekend({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 22 : 28,
          height: compact ? 8 : 10,
          decoration: BoxDecoration(
            color: ClayTokens.accentAlt.withValues(alpha: 0.07),
            border: Border.all(color: ClayTokens.accentAlt.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: compact ? 4 : 6),
        Text(
          compact ? 'Fim de semana' : 'Fim de semana — disponível para locação',
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            color: ClayTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LegendTap extends StatelessWidget {
  const _LegendTap({required this.label});

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
            gradient: const LinearGradient(colors: [ClayTokens.tertiary, ClayTokens.accent]),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary)),
      ],
    );
  }
}
