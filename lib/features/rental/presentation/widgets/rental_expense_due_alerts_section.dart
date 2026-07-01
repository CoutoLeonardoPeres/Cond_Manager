import 'package:cond_manager/features/rental/domain/utils/rental_expense_due_alerts.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RentalExpenseDueAlertsSection extends ConsumerWidget {
  const RentalExpenseDueAlertsSection({
    super.key,
    this.maxItems = 5,
    this.compact = false,
    this.badgeOnly = false,
  });

  final int maxItems;
  final bool compact;
  final bool badgeOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(rentalExpenseDueAlertsProvider);

    return alertsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();

        final overdue = alerts.where((a) => a.kind == RentalExpenseDueAlertKind.overdue).length;
        final dueSoon = alerts.where((a) => a.kind == RentalExpenseDueAlertKind.dueSoon).length;
        final generate = alerts.where((a) => a.kind == RentalExpenseDueAlertKind.generateRequired).length;

        if (badgeOnly) {
          final summary = [
            if (overdue > 0) '$overdue atraso',
            if (dueSoon > 0) '$dueSoon vencendo',
            if (generate > 0) '$generate a gerar',
          ].join(' · ');
          final iconSize = compact ? 12.0 : 16.0;
          final fontSize = compact ? 8.0 : 11.0;
          final hPad = compact ? 7.0 : 10.0;
          final vPad = compact ? 4.0 : 6.0;
          final gap = compact ? 4.0 : 6.0;
          return Tooltip(
            message: summary.isEmpty ? '${alerts.length} alerta(s)' : summary,
            child: ClaySurface(
              depth: ClayDepth.pressed,
              onTap: () {},
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: iconSize,
                    color: overdue > 0 ? ClayTokens.error : ClayTokens.warning,
                  ),
                  SizedBox(width: gap),
                  Text(
                    summary.isEmpty ? '${alerts.length}' : summary,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: overdue > 0 ? ClayTokens.error : ClayTokens.warning,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final shown = alerts.take(maxItems).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_rounded, size: 20, color: ClayTokens.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contas fixas — vencimentos',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                ClaySurface(
                  depth: ClayDepth.pressed,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '${alerts.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: overdue > 0 ? ClayTokens.error : ClayTokens.warning,
                    ),
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (overdue > 0) '$overdue em atraso',
                  if (dueSoon > 0) '$dueSoon vencendo',
                  if (generate > 0) '$generate a gerar',
                ].join(' · '),
                style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            ...shown.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AlertTile(alert: alert),
                )),
            if (alerts.length > maxItems)
              TextButton(
                onPressed: () => context.go('/rental/expenses'),
                child: Text('Ver todas (${alerts.length}) em Despesas'),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.go('/rental/expenses'),
                  child: const Text('Ir para Despesas'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final RentalExpenseDueAlert alert;

  Color get _accent => switch (alert.kind) {
        RentalExpenseDueAlertKind.overdue => ClayTokens.error,
        RentalExpenseDueAlertKind.generateRequired => ClayTokens.warning,
        RentalExpenseDueAlertKind.dueSoon => ClayTokens.primary,
      };

  IconData get _icon => switch (alert.kind) {
        RentalExpenseDueAlertKind.overdue => Icons.error_outline_rounded,
        RentalExpenseDueAlertKind.generateRequired => Icons.event_repeat_rounded,
        RentalExpenseDueAlertKind.dueSoon => Icons.schedule_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.pressed,
      onTap: () {
        if (alert.expenseId != null) {
          context.go('/rental/expenses/${alert.expenseId}');
        } else {
          context.go('/rental/expenses');
        }
      },
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  alert.subtitle,
                  style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('dd/MM').format(alert.dueDate),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _accent),
          ),
        ],
      ),
    );
  }
}
