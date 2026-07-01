import 'package:cond_manager/features/dashboard/domain/dashboard_financial_metrics.dart';
import 'package:cond_manager/features/dashboard/presentation/providers/dashboard_financial_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardFinancialKpiSection extends ConsumerWidget {
  const DashboardFinancialKpiSection({
    super.key,
    this.compact = false,
    this.pairOccupancyProfitability = false,
  });

  final bool compact;
  final bool pairOccupancyProfitability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardFinancialMetricsProvider);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final percent = NumberFormat.decimalPattern('pt_BR');

    return metricsAsync.when(
      loading: () => Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 24),
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => ClaySurface(
        depth: ClayDepth.pressed,
        padding: EdgeInsets.all(compact ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indicadores financeiros',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: compact ? 10 : 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Não foi possível carregar: $e',
              style: TextStyle(color: ClayTokens.error, fontSize: compact ? 9 : 13),
            ),
            TextButton(
              onPressed: () => ref.invalidate(dashboardFinancialMetricsProvider),
              child: Text('Tentar novamente', style: TextStyle(fontSize: compact ? 10 : 14)),
            ),
          ],
        ),
      ),
      data: (m) => _KpiGrid(
        metrics: m,
        currency: currency,
        percent: percent,
        compact: compact,
        pairOccupancyProfitability: pairOccupancyProfitability,
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.metrics,
    required this.currency,
    required this.percent,
    required this.compact,
    required this.pairOccupancyProfitability,
  });

  final DashboardFinancialMetrics metrics;
  final NumberFormat currency;
  final NumberFormat percent;
  final bool compact;
  final bool pairOccupancyProfitability;

  String _money(double v) => compact
      ? NumberFormat.compactCurrency(locale: 'pt_BR', symbol: r'R$').format(v)
      : currency.format(v);
  String _pct(double? v) => v == null ? '—' : '${percent.format(v)}%';

  ClayStatCard _occupancyCard(BuildContext context) => ClayStatCard(
        compact: compact,
        title: 'Taxa de ocupação',
        value: _pct(metrics.occupancyRate),
        icon: Icons.hotel_rounded,
        accentColor: ClayTokens.accentAlt,
        gradientIndex: 4,
        onTap: metrics.hasRentalModule ? () => context.go('/rental/calendar') : null,
      );

  ClayStatCard _profitabilityCard(BuildContext context) => ClayStatCard(
        compact: compact,
        title: 'Margem rentabilidade',
        value: _pct(metrics.overallProfitMargin),
        icon: Icons.insights_rounded,
        accentColor: ClayTokens.tertiary,
        gradientIndex: 5,
        onTap: () => context.go('/financial'),
      );

  List<ClayStatCard> _financialCards(BuildContext context) => [
        ClayStatCard(
          compact: compact,
          title: 'Saldo mensal',
          value: _money(metrics.monthlyBalance),
          icon: Icons.account_balance_wallet_rounded,
          accentColor: metrics.monthlyBalance >= 0 ? ClayTokens.success : ClayTokens.error,
          gradientIndex: 0,
          onTap: () => context.go('/financial'),
        ),
        ClayStatCard(
          compact: compact,
          title: 'Saldo anual',
          value: _money(metrics.annualBalance),
          icon: Icons.savings_rounded,
          accentColor: metrics.annualBalance >= 0 ? ClayTokens.primary : ClayTokens.error,
          gradientIndex: 1,
          onTap: () => context.go('/financial'),
        ),
        ClayStatCard(
          compact: compact,
          title: 'Despesas mensais',
          value: _money(metrics.monthlyExpenses),
          icon: Icons.trending_down_rounded,
          accentColor: ClayTokens.warning,
          gradientIndex: 2,
          onTap: () => context.go('/financial'),
        ),
        ClayStatCard(
          compact: compact,
          title: 'Despesas anuais',
          value: _money(metrics.annualExpenses),
          icon: Icons.receipt_long_rounded,
          accentColor: ClayTokens.error,
          gradientIndex: 3,
          onTap: () => context.go('/financial'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (pairOccupancyProfitability) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final financialColumns = constraints.maxWidth > 700 ? 4 : 2;
          final spacing = compact ? 6.0 : 14.0;
          final financialWidth =
              (constraints.maxWidth - spacing * (financialColumns - 1)) / financialColumns;

          return Column(
            children: [
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _financialCards(context)
                    .map((card) => SizedBox(width: financialWidth, child: card))
                    .toList(),
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(child: _occupancyCard(context)),
                  SizedBox(width: spacing),
                  Expanded(child: _profitabilityCard(context)),
                ],
              ),
            ],
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = compact
            ? (constraints.maxWidth > 1100
                ? 6
                : constraints.maxWidth > 700
                    ? 3
                    : 2)
            : (constraints.maxWidth > 1100
                ? 3
                : constraints.maxWidth > 720
                    ? 2
                    : 1);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: compact ? 6 : 14,
          crossAxisSpacing: compact ? 6 : 14,
          childAspectRatio: compact ? 3.4 : (crossAxisCount == 1 ? 2.4 : 1.65),
          children: [
            ..._financialCards(context),
            _occupancyCard(context),
            _profitabilityCard(context),
          ],
        );
      },
    );
  }
}
