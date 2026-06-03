import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:flutter/material.dart';

class ProviderStatusChip extends StatelessWidget {
  const ProviderStatusChip({super.key, required this.status});

  final EntityStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      EntityStatus.active => (ClayTokens.success, ClayTokens.success.withValues(alpha: 0.15)),
      EntityStatus.pending => (ClayTokens.warning, ClayTokens.warning.withValues(alpha: 0.15)),
      EntityStatus.blocked => (ClayTokens.error, ClayTokens.error.withValues(alpha: 0.15)),
      EntityStatus.inactive => (ClayTokens.textMuted, ClayTokens.textMuted.withValues(alpha: 0.12)),
    };

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
}
