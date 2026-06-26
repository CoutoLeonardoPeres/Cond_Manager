import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/widgets/clay/clay_surface.dart';
import 'package:flutter/material.dart';

class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.depth = ClayDepth.card,
    this.accentColor,
    this.backgroundColor,
    this.glass = true,
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
      color: backgroundColor,
      glass: backgroundColor == null && glass,
      liftOnHover: liftOnHover && onTap != null,
      child: child,
    );
  }
}

class ClayStatCard extends StatefulWidget {
  const ClayStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
    this.gradientIndex = 0,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final int gradientIndex;

  @override
  State<ClayStatCard> createState() => _ClayStatCardState();
}

class _ClayStatCardState extends State<ClayStatCard> with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final gradient = ClayTokens.iconGradientAt(widget.gradientIndex);

    return ClayCard(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          reduceMotion
              ? _iconOrb(gradient)
              : AnimatedBuilder(
                  animation: _breathe,
                  builder: (context, child) {
                    final scale = 1.0 + (_breathe.value * 0.02);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: _iconOrb(gradient),
                ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.title,
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

  Widget _iconOrb(Gradient gradient) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
        boxShadow: ClayDecorations.clayButtonShadows(),
      ),
      child: Icon(widget.icon, color: Colors.white, size: 26),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final int gradientIndex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = ClayTokens.iconGradientAt(gradientIndex);

    return ClayCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
              boxShadow: ClayDecorations.clayButtonShadows(),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
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
          Icon(Icons.chevron_right_rounded, color: ClayTokens.muted.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
