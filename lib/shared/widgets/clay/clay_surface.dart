import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

class ClaySurface extends StatelessWidget {
  const ClaySurface({
    super.key,
    required this.child,
    this.depth = ClayDepth.raised,
    this.color,
    this.radius = ClayTokens.radiusMd,
    this.padding,
    this.margin,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
    this.borderless = false,
  });

  final Widget child;
  final ClayDepth depth;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool borderless;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: ClayDecorations.surface(
        depth: depth,
        color: color,
        radius: radius,
        gradient: gradient,
        border: borderless
            ? null
            : Border.all(
                color: ClayTokens.highlight.withValues(alpha: 0.65),
                width: 1.5,
              ),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: ClayTokens.primary.withValues(alpha: 0.08),
        highlightColor: ClayTokens.primary.withValues(alpha: 0.04),
        child: content,
      ),
    );
  }
}
