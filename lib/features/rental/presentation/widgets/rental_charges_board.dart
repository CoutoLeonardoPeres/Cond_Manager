import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_charge_tile.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Color boardColumnColor(RentalChargeBoardColumn column) => switch (column) {
      RentalChargeBoardColumn.newCharges => ClayTokens.warning,
      RentalChargeBoardColumn.overdue => ClayTokens.error,
      RentalChargeBoardColumn.paid => ClayTokens.success,
    };

class RentalChargesBoard extends StatelessWidget {
  const RentalChargesBoard({
    super.key,
    required this.charges,
    required this.currency,
    required this.dateFmt,
    required this.canManage,
    required this.onOpenCharge,
    required this.onConfirmPayment,
  });

  final List<RentalCharge> charges;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final bool canManage;
  final void Function(RentalCharge charge) onOpenCharge;
  final void Function(RentalCharge charge) onConfirmPayment;

  Map<RentalChargeBoardColumn, List<RentalCharge>> _groupCharges() {
    final grouped = {
      for (final c in RentalChargeBoardColumn.values) c: <RentalCharge>[],
    };
    for (final charge in charges) {
      final column = charge.boardColumn;
      if (column != null) grouped[column]!.add(charge);
    }
    for (final column in RentalChargeBoardColumn.values) {
      grouped[column]!.sort((a, b) {
        if (column == RentalChargeBoardColumn.paid) {
          final aDate = a.paidAt ?? a.dueDate ?? DateTime(1970);
          final bDate = b.paidAt ?? b.dueDate ?? DateTime(1970);
          return bDate.compareTo(aDate);
        }
        final aDue = a.dueDate ?? DateTime(2100);
        final bDue = b.dueDate ?? DateTime(2100);
        return aDue.compareTo(bDue);
      });
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupCharges();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;
        final gap = isMobile ? 6.0 : 12.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < RentalChargeBoardColumn.values.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                child: _ChargesBoardColumn(
                  column: RentalChargeBoardColumn.values[i],
                  charges: grouped[RentalChargeBoardColumn.values[i]]!,
                  currency: currency,
                  dateFmt: dateFmt,
                  canManage: canManage,
                  onOpenCharge: onOpenCharge,
                  onConfirmPayment: onConfirmPayment,
                  isMobile: isMobile,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ChargesBoardColumn extends StatelessWidget {
  const _ChargesBoardColumn({
    required this.column,
    required this.charges,
    required this.currency,
    required this.dateFmt,
    required this.canManage,
    required this.onOpenCharge,
    required this.onConfirmPayment,
    required this.isMobile,
  });

  final RentalChargeBoardColumn column;
  final List<RentalCharge> charges;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final bool canManage;
  final void Function(RentalCharge charge) onOpenCharge;
  final void Function(RentalCharge charge) onConfirmPayment;
  final bool isMobile;

  String get _headerLabel => switch (column) {
        RentalChargeBoardColumn.newCharges => isMobile ? 'Novas' : column.label,
        RentalChargeBoardColumn.overdue => isMobile ? 'Atraso' : column.label,
        RentalChargeBoardColumn.paid => column.label,
      };

  @override
  Widget build(BuildContext context) {
    final color = boardColumnColor(column);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClaySurface(
          depth: ClayDepth.pressed,
          radius: isMobile ? ClayTokens.radiusSm : ClayTokens.radiusMd,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 12,
            vertical: isMobile ? 6 : 10,
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 6 : 8,
                height: isMobile ? 6 : 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: isMobile ? 4 : 8),
              Expanded(
                child: Text(
                  _headerLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isMobile ? 10 : 13,
                  ),
                ),
              ),
              Text(
                '${charges.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 10 : 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        if (charges.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 24),
            child: Text(
              '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ClayTokens.muted.withValues(alpha: 0.8),
                fontSize: isMobile ? 10 : 12,
              ),
            ),
          )
        else
          ...charges.map(
            (charge) => Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 6 : 8),
              child: RentalChargeTile(
                charge: charge,
                currency: currency,
                dateFmt: dateFmt,
                compact: !isMobile,
                ultraCompact: isMobile,
                canManage: canManage,
                onTap: () => onOpenCharge(charge),
                onConfirmPayment: charge.canConfirmPayment
                    ? () => onConfirmPayment(charge)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
