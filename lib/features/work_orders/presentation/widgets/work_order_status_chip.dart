import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/domain/enums/work_order_status.dart';
import 'package:flutter/material.dart';

class WorkOrderStatusChip extends StatelessWidget {
  const WorkOrderStatusChip({super.key, required this.status});

  final WorkOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  static (Color, Color) _colors(WorkOrderStatus status) => switch (status) {
        WorkOrderStatus.open => (ClayTokens.accent, ClayTokens.accent.withValues(alpha: 0.12)),
        WorkOrderStatus.triage => (
            const Color(0xFF7C3AED),
            const Color(0xFF7C3AED).withValues(alpha: 0.12),
          ),
        WorkOrderStatus.inProgress => (
            ClayTokens.tertiary,
            ClayTokens.tertiary.withValues(alpha: 0.15),
          ),
        WorkOrderStatus.waitingApproval || WorkOrderStatus.waitingBudget => (
            ClayTokens.warning,
            ClayTokens.warning.withValues(alpha: 0.15),
          ),
        WorkOrderStatus.waitingMaterial => (
            ClayTokens.warning,
            ClayTokens.warning.withValues(alpha: 0.15),
          ),
        WorkOrderStatus.completed || WorkOrderStatus.closed => (
            ClayTokens.success,
            ClayTokens.success.withValues(alpha: 0.12),
          ),
        WorkOrderStatus.cancelled || WorkOrderStatus.rejected => (
            ClayTokens.error,
            ClayTokens.error.withValues(alpha: 0.12),
          ),
        _ => (ClayTokens.muted, ClayTokens.muted.withValues(alpha: 0.12)),
      };
}
