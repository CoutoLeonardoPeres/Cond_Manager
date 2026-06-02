import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

enum ClayButtonVariant { primary, secondary, ghost, danger }

class ClayButton extends StatefulWidget {
  const ClayButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ClayButtonVariant.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ClayButtonVariant variant;
  final bool expand;

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    final decoration = switch (widget.variant) {
      ClayButtonVariant.primary => ClayDecorations.primaryButton(),
      ClayButtonVariant.secondary => ClayDecorations.surface(
          depth: _pressed ? ClayDepth.pressed : ClayDepth.raised,
          color: ClayTokens.surfaceRaised,
        ),
      ClayButtonVariant.ghost => null,
      ClayButtonVariant.danger => BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A80), ClayTokens.error],
          ),
          borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
          boxShadow: ClayDecorations.raisedShadows(depth: 0.8),
        ),
    };

    final textColor = switch (widget.variant) {
      ClayButtonVariant.primary || ClayButtonVariant.danger => ClayTokens.textOnPrimary,
      ClayButtonVariant.secondary => ClayTokens.textPrimary,
      ClayButtonVariant.ghost => ClayTokens.primary,
    };

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 54,
      width: widget.expand ? double.infinity : null,
      padding: widget.expand ? null : const EdgeInsets.symmetric(horizontal: 28),
      decoration: decoration,
      transform: Matrix4.identity()..scale(_pressed && enabled ? 0.98 : 1.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: textColor,
                    ),
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
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
