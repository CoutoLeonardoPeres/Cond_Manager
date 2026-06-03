import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/widgets/clay/clay_surface.dart';
import 'package:flutter/material.dart';

class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.depth = ClayDepth.raised,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final ClayDepth depth;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: depth,
      radius: ClayTokens.radiusMd,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

class ClayStatCard extends StatelessWidget {
  const ClayStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      depth: ClayDepth.floating,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: ClayTokens.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ClayListTileCard extends StatelessWidget {
  const ClayListTileCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = ClayTokens.primary,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withValues(alpha: 0.25),
                  iconColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: ClayTokens.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: ClayTokens.textMuted),
        ],
      ),
    );
  }
}
