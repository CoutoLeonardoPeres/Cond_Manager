import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/domain/enums/priority_level.dart';
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
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  static (Color, Color) _colors(WorkOrderStatus status) => switch (status) {
        WorkOrderStatus.open => (ClayTokens.primary, ClayTokens.primary.withValues(alpha: 0.12)),
        WorkOrderStatus.triage => (const Color(0xFF7C3AED), const Color(0xFF7C3AED).withValues(alpha: 0.12)),
        WorkOrderStatus.inProgress => (ClayTokens.secondary, ClayTokens.secondary.withValues(alpha: 0.15)),
        WorkOrderStatus.waitingApproval || WorkOrderStatus.waitingBudget => (
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
        _ => (ClayTokens.textSecondary, ClayTokens.textSecondary.withValues(alpha: 0.12)),
      };
}

class WorkOrderPriorityBadge extends StatelessWidget {
  const WorkOrderPriorityBadge({super.key, required this.priority});

  final PriorityLevel priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      PriorityLevel.low => ClayTokens.textSecondary,
      PriorityLevel.medium => ClayTokens.primary,
      PriorityLevel.high => ClayTokens.warning,
      PriorityLevel.urgent => ClayTokens.error,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          priority.label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
