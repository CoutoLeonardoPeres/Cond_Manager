import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FinancialReportView extends StatelessWidget {
  const FinancialReportView({
    super.key,
    required this.summaryAsync,
    required this.onRefresh,
    this.title,
  });

  final AsyncValue<FinancialReportSummary> summaryAsync;
  final Future<void> Function() onRefresh;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (e, _) => Center(child: Text('$e')),
      data: (s) => RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (title != null) ...[
              Text(title!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              if (s.condominiumName != null) ...[
                const SizedBox(height: 4),
                Text(s.condominiumName!, style: const TextStyle(color: ClayTokens.textSecondary)),
              ],
              const SizedBox(height: 16),
            ],
            _MetricCard(
              label: 'Receitas',
              value: currency.format(s.totalIncome),
              icon: Icons.arrow_downward_rounded,
              color: ClayTokens.success,
            ),
            const SizedBox(height: 10),
            _MetricCard(
              label: 'Despesas',
              value: currency.format(s.totalExpenses),
              icon: Icons.arrow_upward_rounded,
              color: ClayTokens.error,
            ),
            const SizedBox(height: 10),
            _MetricCard(
              label: 'Saldo',
              value: currency.format(s.balance),
              icon: Icons.account_balance_wallet_rounded,
              color: s.balance >= 0 ? ClayTokens.primary : ClayTokens.error,
            ),
            const SizedBox(height: 20),
            const Text('Custos operacionais', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _SmallRow('Pessoal / folha', currency.format(s.totalPersonnel)),
            _SmallRow('Mão de obra (HH)', currency.format(s.totalLabor)),
            _SmallRow('Materiais', currency.format(s.totalMaterials)),
            _SmallRow('Frete', currency.format(s.totalFreight)),
            _SmallRow('Serviços contratados', currency.format(s.totalContractedServices)),
            _SmallRow('Impostos (componente)', currency.format(s.totalTaxes)),
            const SizedBox(height: 20),
            Text(
              'Por categoria (${s.recordCount} lançamentos)',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (s.byCategory.isEmpty)
              const Text('Sem lançamentos no período.', style: TextStyle(color: ClayTokens.textMuted))
            else
              ...s.byCategory.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClaySurface(
                    depth: ClayDepth.pressed,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(b.category.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Desp: ${currency.format(b.expenses)}', style: const TextStyle(fontSize: 12)),
                            if (b.income > 0)
                              Text('Rec: ${currency.format(b.income)}', style: const TextStyle(fontSize: 12, color: ClayTokens.success)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.raised,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: ClayTokens.textSecondary))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _SmallRow extends StatelessWidget {
  const _SmallRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: ClayTokens.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
