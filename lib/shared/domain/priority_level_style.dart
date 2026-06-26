import 'package:cond_manager/shared/domain/enums/priority_level.dart';
import 'package:flutter/material.dart';

/// Cores suaves dos cards e badges por prioridade.
abstract final class PriorityLevelStyle {
  static PriorityCardColors colors(PriorityLevel priority) => switch (priority) {
        PriorityLevel.low => const PriorityCardColors(
          accent: Color(0xFF16A34A),
          cardBackground: Color(0xFFDCFCE7),
          iconBackground: Color(0xFFBBF7D0),
        ),
        PriorityLevel.medium => const PriorityCardColors(
          accent: Color(0xFFCA8A04),
          cardBackground: Color(0xFFFEF9C3),
          iconBackground: Color(0xFFFEF08A),
        ),
        PriorityLevel.high => const PriorityCardColors(
          accent: Color(0xFFEA580C),
          cardBackground: Color(0xFFFFEDD5),
          iconBackground: Color(0xFFFED7AA),
        ),
        PriorityLevel.urgent => const PriorityCardColors(
          accent: Color(0xFFDC2626),
          cardBackground: Color(0xFFFEE2E2),
          iconBackground: Color(0xFFFECACA),
        ),
      };
}

class PriorityCardColors {
  const PriorityCardColors({
    required this.accent,
    required this.cardBackground,
    required this.iconBackground,
  });

  final Color accent;
  final Color cardBackground;
  final Color iconBackground;

  Color get badgeBackground => iconBackground;
}
