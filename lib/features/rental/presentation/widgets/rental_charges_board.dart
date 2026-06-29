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
        const minColumnWidth = 240.0;
        final useRow = constraints.maxWidth >= minColumnWidth * 3 + 32;

        final columns = RentalChargeBoardColumn.values
            .map(
              (column) => _ChargesBoardColumn(
                column: column,
                charges: grouped[column]!,
                currency: currency,
                dateFmt: dateFmt,
                canManage: canManage,
                onOpenCharge: onOpenCharge,
                onConfirmPayment: onConfirmPayment,
                width: useRow ? null : minColumnWidth,
              ),
            )
            .toList();

        if (useRow) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: columns[i]),
              ],
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                columns[i],
              ],
            ],
          ),
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
    this.width,
  });

  final RentalChargeBoardColumn column;
  final List<RentalCharge> charges;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final bool canManage;
  final void Function(RentalCharge charge) onOpenCharge;
  final void Function(RentalCharge charge) onConfirmPayment;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final color = boardColumnColor(column);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClaySurface(
          depth: ClayDepth.pressed,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  column.label,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              Text(
                '${charges.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (charges.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nenhuma cobrança',
              textAlign: TextAlign.center,
              style: TextStyle(color: ClayTokens.muted.withValues(alpha: 0.8), fontSize: 12),
            ),
          )
        else
          ...charges.map(
            (charge) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RentalChargeTile(
                charge: charge,
                currency: currency,
                dateFmt: dateFmt,
                compact: true,
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

    if (width != null) {
      return SizedBox(width: width, child: content);
    }
    return content;
  }
}
