import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/domain/enums/priority_level.dart';
import 'package:cond_manager/shared/domain/priority_level_style.dart';
import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final PriorityLevel priority;

  @override
  Widget build(BuildContext context) {
    final colors = PriorityLevelStyle.colors(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.badgeBackground,
        borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
        border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12, color: colors.accent),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
