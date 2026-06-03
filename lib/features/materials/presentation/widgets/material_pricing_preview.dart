import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/utils/material_pricing.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MaterialPricingPreview extends StatelessWidget {
  const MaterialPricingPreview({
    super.key,
    required this.unitCost,
    required this.purchaseTaxPercent,
    required this.resaleUnitPrice,
    required this.resaleTaxPercent,
  });

  final double unitCost;
  final double purchaseTaxPercent;
  final double resaleUnitPrice;
  final double resaleTaxPercent;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final costWithTax = MaterialPricing.withTax(unitCost, purchaseTaxPercent);
    final resaleWithTax = MaterialPricing.withTax(resaleUnitPrice, resaleTaxPercent);
    final margin = MaterialPricing.marginAmount(resaleWithTax, costWithTax);
    final marginPct = MaterialPricing.marginPercent(resaleWithTax, costWithTax);

    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo de preços (unitário)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _Row('Custo de compra', currency.format(unitCost)),
          _Row('Custo c/ impostos (${purchaseTaxPercent.toStringAsFixed(1)}%)',
              currency.format(costWithTax)),
          const Divider(height: 20),
          _Row('Repasse ao condomínio', currency.format(resaleUnitPrice)),
          _Row('Repasse c/ impostos (${resaleTaxPercent.toStringAsFixed(1)}%)',
              currency.format(resaleWithTax)),
          const Divider(height: 20),
          _Row(
            'Margem estimada',
            '${currency.format(margin)}${marginPct != null ? ' (${marginPct.toStringAsFixed(1)}%)' : ''}',
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? ClayTokens.success : null,
            ),
          ),
        ],
      ),
    );
  }
}
