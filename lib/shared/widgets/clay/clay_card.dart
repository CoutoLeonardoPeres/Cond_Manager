import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/widgets/clay/clay_surface.dart';
import 'package:flutter/material.dart';

class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
    this.depth = ClayDepth.card,
    this.accentColor,
    this.backgroundColor,
    this.glass = false,
    this.liftOnHover = true,
    this.radius = ClayTokens.radiusCard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final ClayDepth depth;
  final Color? accentColor;
  final Color? backgroundColor;
  final bool glass;
  final bool liftOnHover;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: depth,
      radius: radius,
      padding: padding,
      onTap: onTap,
      color: backgroundColor ?? ClayTokens.cardBg,
      glass: glass,
      liftOnHover: liftOnHover && onTap != null,
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
    this.gradientIndex = 0,
    this.compact = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final int gradientIndex;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconBox = compact ? 26.0 : 48.0;
    final iconSize = compact ? 14.0 : 24.0;

    return ClayCard(
      onTap: onTap,
      padding: compact ? const EdgeInsets.all(8) : const EdgeInsets.all(22),
      radius: compact ? ClayTokens.radiusSm : ClayTokens.radiusCard,
      child: compact
          ? Row(
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: ClayTokens.accentSurface,
                    borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                  ),
                  child: Icon(icon, color: accentColor, size: iconSize),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: ClayTokens.foreground,
                        ),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: ClayTokens.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: ClayTokens.accentSurface,
                    borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                  ),
                  child: Icon(icon, color: ClayTokens.accent, size: iconSize),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: ClayTokens.foreground,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ClayTokens.muted,
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
    this.iconColor = ClayTokens.accent,
    this.gradientIndex = 0,
    this.onTap,
    this.trailing,
    this.showDivider = true,
    this.avatarLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final int gradientIndex;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;
  final String? avatarLabel;

  @override
  Widget build(BuildContext context) {
    final row = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: ClayTokens.accentSurface,
                child: avatarLabel != null
                    ? Text(
                        avatarLabel!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: ClayTokens.accent,
                              fontWeight: FontWeight.w600,
                            ),
                      )
                    : Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ClayTokens.foreground,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ClayTokens.muted,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.more_vert_rounded,
                    color: ClayTokens.textMuted,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );

    if (!showDivider) return row;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        const Divider(height: 1, thickness: 1, indent: 76),
      ],
    );
  }
}

/// Card container for grouped list rows (tickets, chamados, etc.).
class ClayListCard extends StatelessWidget {
  const ClayListCard({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}
