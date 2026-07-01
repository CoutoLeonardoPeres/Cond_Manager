import 'package:cond_manager/features/dashboard/domain/dashboard_financial_metrics.dart';
import 'package:cond_manager/features/dashboard/presentation/providers/dashboard_financial_providers.dart';
import 'package:cond_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:cond_manager/features/dashboard/presentation/widgets/clay_chart_widgets.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DashboardChartsSection extends ConsumerWidget {
  const DashboardChartsSection({
    super.key,
    this.compact = false,
    this.showHeader = true,
    this.pairOccupancyProfitabilityCharts = false,
  });

  final bool compact;
  final bool showHeader;
  final bool pairOccupancyProfitabilityCharts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardFinancialMetricsProvider);
    final year = ref.watch(dashboardFilterProvider).effectiveYear;
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 0);

    return metricsAsync.when(
      loading: () => SizedBox(
        height: compact ? 48 : 120,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (m) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Text(
              'Gráficos',
              style: TextStyle(
                fontSize: compact ? 12 : 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                'Ano $year · receitas, despesas, ocupação e custos por unidade',
                style: const TextStyle(fontSize: 13, color: ClayTokens.textSecondary),
              ),
            ],
            SizedBox(height: compact ? 6 : 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = compact
                  ? (constraints.maxWidth > 1000
                      ? 3
                      : constraints.maxWidth > 640
                          ? 2
                          : 1)
                  : (constraints.maxWidth > 900 ? 2 : 1);
              final spacing = compact ? 6.0 : 16.0;
              final chartWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing * (columns - 1)) / columns;
              final chartHeight = compact ? 72.0 : 170.0;

              final expensesChart = SizedBox(
                width: chartWidth,
                child: _ExpensesTrendChart(
                  metrics: m,
                  currency: currency,
                  compact: compact,
                  chartHeight: chartHeight,
                ),
              );
              final annualChart = SizedBox(
                width: chartWidth,
                child: _AnnualComparisonChart(
                  metrics: m,
                  year: year,
                  compact: compact,
                  chartHeight: chartHeight,
                ),
              );
              final occupancyTrendChart = m.hasRentalModule && m.monthlyOccupancyTrend.isNotEmpty
                  ? SizedBox(
                      width: chartWidth,
                      child: _OccupancyTrendChart(
                        metrics: m,
                        compact: compact,
                        chartHeight: chartHeight,
                      ),
                    )
                  : null;
              final occupancyByPropertyChart = m.occupancyByProperty.isNotEmpty
                  ? _OccupancyByPropertyChart(metrics: m, compact: compact)
                  : null;
              final unitProfitabilityChart = _UnitProfitabilityChart(
                metrics: m,
                currency: currency,
                compact: compact,
              );

              if (pairOccupancyProfitabilityCharts) {
                final topCharts = <Widget>[
                  expensesChart,
                  annualChart,
                  if (occupancyTrendChart != null) occupancyTrendChart,
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: topCharts,
                    ),
                    if (occupancyByPropertyChart != null || m.unitProfitability.isNotEmpty) ...[
                      SizedBox(height: spacing),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (occupancyByPropertyChart != null)
                            Expanded(child: occupancyByPropertyChart),
                          if (occupancyByPropertyChart != null &&
                              m.unitProfitability.isNotEmpty)
                            SizedBox(width: spacing),
                          if (m.unitProfitability.isNotEmpty)
                            Expanded(child: unitProfitabilityChart),
                        ],
                      ),
                    ],
                  ],
                );
              }

              final charts = <Widget>[
                expensesChart,
                annualChart,
                if (occupancyTrendChart != null) occupancyTrendChart,
                if (occupancyByPropertyChart != null)
                  SizedBox(width: chartWidth, child: occupancyByPropertyChart),
                SizedBox(
                  width: compact && columns > 1 ? constraints.maxWidth : chartWidth,
                  child: unitProfitabilityChart,
                ),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: charts,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExpensesTrendChart extends StatelessWidget {
  const _ExpensesTrendChart({
    required this.metrics,
    required this.currency,
    required this.compact,
    required this.chartHeight,
  });

  final DashboardFinancialMetrics metrics;
  final NumberFormat currency;
  final bool compact;
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    final expenses = metrics.monthlyTrend.map((p) => p.expenses).toList();
    final maxExpense = expenses.isEmpty ? 0.0 : expenses.reduce((a, b) => a > b ? a : b);

    return ClayChartCard(
      compact: compact,
      title: 'Despesas mensais',
      subtitle: compact ? null : 'Evolução das despesas ao longo do ano',
      legend: compact
          ? null
          : Text(
              'Pico: ${currency.format(maxExpense)}',
              style: const TextStyle(fontSize: 11, color: ClayTokens.textSecondary),
            ),
      child: ClayBarChart(
        labels: kMonthLabelsShort,
        values: expenses,
        barColor: ClayTokens.warning,
        height: chartHeight,
      ),
    );
  }
}

class _AnnualComparisonChart extends StatelessWidget {
  const _AnnualComparisonChart({
    required this.metrics,
    required this.year,
    required this.compact,
    required this.chartHeight,
  });

  final DashboardFinancialMetrics metrics;
  final int year;
  final bool compact;
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    final current = metrics.monthlyTrend.map((p) => p.expenses).toList();
    final previous = metrics.previousYearMonthlyExpenses;

    return ClayChartCard(
      compact: compact,
      title: compact ? 'Despesas $year vs ${year - 1}' : 'Comparativo anual de despesas',
      subtitle: compact ? null : '$year vs ${year - 1}',
      legend: compact
          ? null
          : const ClayChartLegend(
              items: [
                (color: ClayTokens.primary, label: 'Ano atual'),
                (color: ClayTokens.textMuted, label: 'Ano anterior'),
              ],
            ),
      child: ClayBarChart(
        labels: kMonthLabelsShort,
        values: current,
        barColor: ClayTokens.primary,
        secondaryValues: previous,
        secondaryColor: ClayTokens.textMuted.withValues(alpha: 0.55),
        height: chartHeight,
      ),
    );
  }
}

class _OccupancyTrendChart extends StatelessWidget {
  const _OccupancyTrendChart({
    required this.metrics,
    required this.compact,
    required this.chartHeight,
  });

  final DashboardFinancialMetrics metrics;
  final bool compact;
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    return ClayChartCard(
      compact: compact,
      title: 'Ocupação no ano',
      subtitle: compact
          ? null
          : metrics.totalActiveProperties != null
              ? '${metrics.occupiedProperties ?? 0} de ${metrics.totalActiveProperties} imóveis ocupados hoje'
              : null,
      child: ClayLineChart(
        labels: kMonthLabelsShort,
        values: metrics.monthlyOccupancyTrend,
        lineColor: ClayTokens.accentAlt,
        fillColor: ClayTokens.accentAlt.withValues(alpha: 0.15),
        height: chartHeight,
      ),
    );
  }
}

class _OccupancyByPropertyChart extends StatelessWidget {
  const _OccupancyByPropertyChart({required this.metrics, required this.compact});

  final DashboardFinancialMetrics metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClayChartCard(
      compact: compact,
      title: 'Ocupação por imóvel',
      subtitle: compact ? null : 'Média anual (%)',
      child: ClayHorizontalBarChart(
        labels: metrics.occupancyByProperty.map((p) => p.label).toList(),
        values: metrics.occupancyByProperty.map((p) => p.occupancyRate).toList(),
        barColor: ClayTokens.accent,
        maxItems: compact ? 4 : 8,
        compact: compact,
      ),
    );
  }
}

class _UnitProfitabilityChart extends StatelessWidget {
  const _UnitProfitabilityChart({
    required this.metrics,
    required this.currency,
    required this.compact,
  });

  final DashboardFinancialMetrics metrics;
  final NumberFormat currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final units = metrics.unitProfitability;
    if (units.isEmpty) {
      return ClayChartCard(
        compact: compact,
        title: 'Rentabilidade por unidade',
        subtitle: compact ? null : 'Receita vs custos de manutenção/reparo',
        child: Text(
          'Sem lançamentos vinculados a unidades no período.',
          style: TextStyle(color: ClayTokens.textMuted, fontSize: compact ? 9 : 13),
        ),
      );
    }

    final totalRevenue = units.fold(0.0, (s, u) => s + u.revenue);
    final totalMaintenance = units.fold(0.0, (s, u) => s + u.maintenanceCost);
    final totalNet = totalRevenue - totalMaintenance;
    final displayUnits = units.take(compact ? 4 : 8).toList();

    return ClayChartCard(
      compact: compact,
      title: 'Rentabilidade por unidade',
      subtitle: compact ? null : 'Custos: OS, materiais, mão de obra e serviços técnicos',
      legend: compact
          ? null
          : Text(
              'Resultado líquido estimado: ${currency.format(totalNet)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: totalNet >= 0 ? ClayTokens.success : ClayTokens.error,
              ),
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = !compact && constraints.maxWidth > 560;
          final table = _ProfitabilityTable(
            units: displayUnits,
            currency: currency,
            compact: compact,
          );

          if (!sideBySide) {
            return Column(
              children: [
                if (!compact)
                  _ProfitabilityDonut(
                    revenue: totalRevenue,
                    maintenance: totalMaintenance,
                    currency: currency,
                    compact: compact,
                  ),
                if (!compact) const SizedBox(height: 12),
                table,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfitabilityDonut(
                revenue: totalRevenue,
                maintenance: totalMaintenance,
                currency: currency,
                compact: compact,
              ),
              const SizedBox(width: 16),
              Expanded(child: table),
            ],
          );
        },
      ),
    );
  }
}

class _ProfitabilityDonut extends StatelessWidget {
  const _ProfitabilityDonut({
    required this.revenue,
    required this.maintenance,
    required this.currency,
    required this.compact,
  });

  final double revenue;
  final double maintenance;
  final NumberFormat currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final net = revenue - maintenance;
    return Column(
      children: [
        ClayDonutChart(
          size: compact ? 64 : 130,
          centerValue: currency.format(net),
          centerLabel: 'Líquido',
          segments: [
            if (maintenance > 0)
              (label: 'Manutenção', value: maintenance, color: ClayTokens.warning),
            if (net > 0)
              (label: 'Lucro', value: net, color: ClayTokens.success)
            else if (net < 0)
              (label: 'Prejuízo', value: -net, color: ClayTokens.error),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          const ClayChartLegend(
            items: [
              (color: ClayTokens.success, label: 'Lucro'),
              (color: ClayTokens.warning, label: 'Manutenção'),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProfitabilityTable extends StatelessWidget {
  const _ProfitabilityTable({
    required this.units,
    required this.currency,
    required this.compact,
  });

  final List<UnitProfitabilityPoint> units;
  final NumberFormat currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: units.map((u) {
        return Padding(
          padding: EdgeInsets.only(bottom: compact ? 4 : 8),
          child: ClaySurface(
            depth: ClayDepth.pressed,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 12,
              vertical: compact ? 4 : 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 9 : 12,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Rec. ${currency.format(u.revenue)} · Manut. ${currency.format(u.maintenanceCost)}',
                          style: const TextStyle(fontSize: 11, color: ClayTokens.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${u.marginPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: compact ? 10 : 14,
                    fontWeight: FontWeight.w800,
                    color: u.netProfit >= 0 ? ClayTokens.success : ClayTokens.error,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
