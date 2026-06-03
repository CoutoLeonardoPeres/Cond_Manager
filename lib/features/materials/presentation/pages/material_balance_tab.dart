import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MaterialBalanceTab extends ConsumerWidget {
  const MaterialBalanceTab({super.key, this.condominiumId});

  final String? condominiumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(materialBalanceSummaryProvider(condominiumId));
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (s) => RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(materialBalanceSummaryProvider(condominiumId)),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Balanço operacional (estoque estocável)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Valores para relatórios da gestora: custo de compra com impostos vs. '
              'repasse aos condomínios. Margem estimada com base no preço cadastrado.',
              style: TextStyle(color: ClayTokens.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            _MetricCard(
              title: 'Itens ativos',
              value: '${s.itemCount}',
              icon: Icons.inventory_2_rounded,
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: 'Alertas estoque baixo',
              value: '${s.lowStockCount}',
              icon: Icons.warning_amber_rounded,
              color: s.lowStockCount > 0 ? ClayTokens.warning : null,
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: 'Valor em estoque (custo + impostos)',
              value: currency.format(s.totalStockCost),
              icon: Icons.shopping_cart_rounded,
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: 'Potencial repasse (preço + impostos)',
              value: currency.format(s.totalStockResale),
              icon: Icons.apartment_rounded,
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: 'Margem estimada em estoque',
              value: currency.format(s.estimatedMargin),
              icon: Icons.trending_up_rounded,
              color: ClayTokens.success,
            ),
            const SizedBox(height: 24),
            ClaySurface(
              depth: ClayDepth.pressed,
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Relatórios detalhados por condomínio e consumo em OS serão consolidados '
                'nas telas Financeiro e nos repasses exportados para cada condomínio.',
                style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13, height: 1.45),
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
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.raised,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: color ?? ClayTokens.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: ClayTokens.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
