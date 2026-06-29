import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

class ClaySurface extends StatefulWidget {
  const ClaySurface({
    super.key,
    required this.child,
    this.depth = ClayDepth.card,
    this.color,
    this.radius = ClayTokens.radiusCard,
    this.padding,
    this.margin,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
    this.borderless = false,
    this.glass = false,
    this.liftOnHover = false,
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
  final bool glass;
  final bool liftOnHover;
  final double? width;
  final double? height;

  @override
  State<ClaySurface> createState() => _ClaySurfaceState();
}

class _ClaySurfaceState extends State<ClaySurface> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final lifted = widget.liftOnHover && _hovered && !_pressed;
    final depth = _pressed ? ClayDepth.pressed : (lifted ? ClayDepth.floating : widget.depth);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      transform: Matrix4.identity()
        ..translate(0.0, lifted ? -2.0 : 0.0)
        ..scale(_pressed ? 0.99 : 1.0),
      decoration: ClayDecorations.surface(
        depth: depth,
        color: widget.color ?? ClayTokens.cardBg,
        radius: widget.radius,
        gradient: widget.gradient,
        glass: widget.glass,
        border: widget.borderless
            ? null
            : Border.all(
                color: ClayTokens.divider,
                width: 1,
              ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Padding(padding: widget.padding ?? EdgeInsets.zero, child: widget.child),
      ),
    );

    if (widget.onTap != null) {
      content = MouseRegion(
        onEnter: widget.liftOnHover ? (_) => setState(() => _hovered = true) : null,
        onExit: widget.liftOnHover ? (_) => setState(() => _hovered = false) : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(widget.radius),
            splashColor: ClayTokens.accent.withValues(alpha: 0.08),
            highlightColor: ClayTokens.accentSurface.withValues(alpha: 0.5),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
