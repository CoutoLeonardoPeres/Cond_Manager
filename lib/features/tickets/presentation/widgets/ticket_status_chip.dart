import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/domain/enums/priority_level.dart';
import 'package:cond_manager/shared/domain/enums/ticket_status.dart';
import 'package:flutter/material.dart';

class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip({super.key, required this.status});

  final TicketStatus status;

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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static (Color, Color) _colors(TicketStatus status) => switch (status) {
        TicketStatus.open => (ClayTokens.primary, ClayTokens.primary.withValues(alpha: 0.12)),
        TicketStatus.inAnalysis => (const Color(0xFF7C3AED), const Color(0xFF7C3AED).withValues(alpha: 0.12)),
        TicketStatus.waitingInfo => (ClayTokens.warning, ClayTokens.warning.withValues(alpha: 0.15)),
        TicketStatus.convertedToOs => (const Color(0xFF0891B2), const Color(0xFF0891B2).withValues(alpha: 0.12)),
        TicketStatus.resolved => (ClayTokens.success, ClayTokens.success.withValues(alpha: 0.12)),
        TicketStatus.cancelled => (ClayTokens.textSecondary, ClayTokens.textSecondary.withValues(alpha: 0.12)),
      };
}

class TicketPriorityBadge extends StatelessWidget {
  const TicketPriorityBadge({super.key, required this.priority});

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
