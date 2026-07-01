import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_charge_payment_dialog.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RentalChargeTile extends StatelessWidget {
  const RentalChargeTile({
    super.key,
    required this.charge,
    required this.currency,
    required this.dateFmt,
    this.compact = false,
    this.ultraCompact = false,
    this.canManage = false,
    this.onTap,
    this.onConfirmPayment,
  });

  final RentalCharge charge;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final bool compact;
  final bool ultraCompact;
  final bool canManage;
  final VoidCallback? onTap;
  final VoidCallback? onConfirmPayment;

  Color get _accentColor {
    if (charge.isPaid) return ClayTokens.success;
    if (charge.isOverdue) return ClayTokens.error;
    return ClayTokens.warning;
  }

  Color? get _backgroundColor {
    if (charge.isPaid) return ClayTokens.success.withValues(alpha: 0.12);
    if (charge.isOverdue) return ClayTokens.error.withValues(alpha: 0.1);
    return ClayTokens.warning.withValues(alpha: 0.08);
  }

  @override
  Widget build(BuildContext context) {
    if (ultraCompact) return _buildUltraCompact(context);
    if (compact) return _buildCompact(context);
    return _buildFull(context);
  }

  Widget _buildUltraCompact(BuildContext context) {
    return ClayCard(
      onTap: onTap,
      backgroundColor: _backgroundColor,
      glass: false,
      padding: const EdgeInsets.all(6),
      radius: ClayTokens.radiusSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            height: 3,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            charge.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  height: 1.2,
                  color: charge.isOverdue ? ClayTokens.error : null,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            currency.format(charge.amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 10,
              color: ClayTokens.foreground,
            ),
          ),
          if (charge.dueDate != null) ...[
            const SizedBox(height: 2),
            Text(
              dateFmt.format(charge.dueDate!),
              maxLines: 1,
              style: const TextStyle(fontSize: 8, color: ClayTokens.muted, height: 1.1),
            ),
          ],
          if (canManage && charge.canConfirmPayment && onConfirmPayment != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton.icon(
                onPressed: onConfirmPayment,
                icon: Icon(Icons.payments_rounded, size: 18, color: _accentColor),
                label: Text(
                  'Pagar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _accentColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  backgroundColor: _accentColor.withValues(alpha: 0.14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final meta = <String>[
      currency.format(charge.amount),
      if (charge.dueDate != null) dateFmt.format(charge.dueDate!),
      if (charge.propertyTitle != null) charge.propertyTitle!,
    ].join(' · ');

    return ClayCard(
      onTap: onTap,
      backgroundColor: _backgroundColor,
      glass: false,
      padding: const EdgeInsets.all(10),
      radius: ClayTokens.radiusSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      charge.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            height: 1.25,
                            color: charge.isOverdue ? ClayTokens.error : null,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ClayTokens.muted,
                            fontSize: 11,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canManage && charge.canConfirmPayment && onConfirmPayment != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: TextButton.icon(
                onPressed: onConfirmPayment,
                icon: const Icon(Icons.payments_rounded, size: 16),
                label: const Text('Confirmar pagamento', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: _accentColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final subtitle = [
      charge.chargeType.label,
      charge.displayStatusLabel,
      currency.format(charge.amount),
      if (charge.propertyTitle != null) charge.propertyTitle,
      if (charge.partyName != null) charge.partyName,
      if (charge.dueDate != null) 'Venc.: ${dateFmt.format(charge.dueDate!)}',
      if (charge.paidPaymentMethod != null) 'Pago via ${charge.paidPaymentMethod!.label}',
      if (charge.financialRecordId != null) 'No financeiro',
    ].whereType<String>().join(' · ');

    return ClayCard(
      onTap: onTap,
      backgroundColor: _backgroundColor,
      glass: _backgroundColor == null,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
              boxShadow: ClayDecorations.clayButtonShadows(),
            ),
            child: Icon(
              charge.isPaid ? Icons.check_circle_rounded : Icons.payments_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  charge.description,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: charge.isOverdue ? ClayTokens.error : null,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ClayTokens.muted,
                        height: 1.4,
                      ),
                ),
                if (canManage && charge.canConfirmPayment && onConfirmPayment != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClayButton(
                      label: 'Confirmar pagamento',
                      expand: false,
                      icon: Icons.payments_rounded,
                      variant: ClayButtonVariant.secondary,
                      onPressed: onConfirmPayment,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, color: ClayTokens.muted.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

Future<void> confirmRentalChargePayment(
  BuildContext context, {
  required RentalCharge charge,
  required Future<void> Function(RentalChargePaymentConfirmation confirmation) onPaid,
}) async {
  final confirmation = await RentalChargePaymentDialog.show(context, charge: charge);
  if (confirmation == null || !context.mounted) return;
  await onPaid(confirmation);
}
