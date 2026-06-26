import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

enum ClayButtonVariant { primary, secondary, ghost, danger, outline }

class ClayButton extends StatefulWidget {
  const ClayButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ClayButtonVariant.primary,
    this.expand = true,
    this.size = ClayButtonSize.defaultSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ClayButtonVariant variant;
  final bool expand;
  final ClayButtonSize size;

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

enum ClayButtonSize { sm, defaultSize, lg }

class _ClayButtonState extends State<ClayButton> {
  bool _pressed = false;
  bool _hovered = false;

  double get _height => switch (widget.size) {
        ClayButtonSize.sm => 44,
        ClayButtonSize.defaultSize => 56,
        ClayButtonSize.lg => 64,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final pressed = _pressed && enabled;

    final decoration = switch (widget.variant) {
      ClayButtonVariant.primary => BoxDecoration(
          gradient: _hovered && enabled
              ? ClayTokens.primaryGradientHover
              : ClayTokens.primaryGradient,
          borderRadius: BorderRadius.circular(ClayTokens.radiusButton),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: pressed
              ? ClayDecorations.clayPressedShadows()
              : ClayDecorations.clayButtonShadows(hover: _hovered && enabled),
        ),
      ClayButtonVariant.secondary => ClayDecorations.surface(
          depth: pressed ? ClayDepth.pressed : ClayDepth.button,
          color: ClayTokens.surfaceRaised,
          radius: ClayTokens.radiusButton,
        ),
      ClayButtonVariant.outline => BoxDecoration(
          borderRadius: BorderRadius.circular(ClayTokens.radiusButton),
          border: Border.all(
            color: ClayTokens.accent.withValues(alpha: _hovered ? 1 : 0.25),
            width: 2,
          ),
          color: _hovered ? ClayTokens.accent.withValues(alpha: 0.05) : Colors.transparent,
        ),
      ClayButtonVariant.danger => BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF87171), ClayTokens.error],
          ),
          borderRadius: BorderRadius.circular(ClayTokens.radiusButton),
          boxShadow: ClayDecorations.clayButtonShadows(),
        ),
      ClayButtonVariant.ghost => null,
    };

    final textColor = switch (widget.variant) {
      ClayButtonVariant.primary || ClayButtonVariant.danger => ClayTokens.textOnPrimary,
      ClayButtonVariant.secondary => ClayTokens.foreground,
      ClayButtonVariant.outline || ClayButtonVariant.ghost => ClayTokens.accent,
    };

    final child = MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _height,
        width: widget.expand ? double.infinity : null,
        padding: widget.expand ? null : const EdgeInsets.symmetric(horizontal: 28),
        decoration: decoration,
        transform: Matrix4.identity()
          ..translate(0.0, _hovered && enabled && !pressed ? -4.0 : 0.0)
          ..scale(pressed ? 0.92 : 1.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? widget.onPressed : null,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
            borderRadius: BorderRadius.circular(ClayTokens.radiusButton),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: textColor),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20, color: textColor),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.label,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    if (widget.variant == ClayButtonVariant.ghost) {
      return TextButton(onPressed: enabled ? widget.onPressed : null, child: child);
    }

    return child;
  }
}
