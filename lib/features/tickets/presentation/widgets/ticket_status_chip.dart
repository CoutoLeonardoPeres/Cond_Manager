import 'package:cond_manager/core/theme/clay_tokens.dart';
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
        TicketStatus.open => (ClayTokens.accent, ClayTokens.accent.withValues(alpha: 0.12)),
        TicketStatus.inAnalysis => (
            ClayTokens.accent,
            ClayTokens.accent.withValues(alpha: 0.12),
          ),
        TicketStatus.waitingMaterial => (
            ClayTokens.warning,
            ClayTokens.warning.withValues(alpha: 0.15),
          ),
        TicketStatus.inProgress => (
            ClayTokens.tertiary,
            ClayTokens.tertiary.withValues(alpha: 0.12),
          ),
        TicketStatus.completed => (ClayTokens.success, ClayTokens.success.withValues(alpha: 0.12)),
        TicketStatus.cancelled => (ClayTokens.muted, ClayTokens.muted.withValues(alpha: 0.12)),
      };
}
