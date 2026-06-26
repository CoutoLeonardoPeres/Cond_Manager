import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClayTextField extends StatefulWidget {
  const ClayTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<ClayTextField> createState() => _ClayTextFieldState();
}

class _ClayTextFieldState extends State<ClayTextField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ClayTokens.muted,
                ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _focused ? ClayTokens.surfaceRaised : ClayTokens.inputBg,
            borderRadius: BorderRadius.circular(ClayTokens.radiusButton),
            boxShadow: _focused ? ClayDecorations.clayCardShadows() : ClayDecorations.clayPressedShadows(),
            border: _focused
                ? Border.all(color: ClayTokens.accent.withValues(alpha: 0.25), width: 2)
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            readOnly: widget.readOnly,
            inputFormatters: widget.inputFormatters,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: ClayTokens.foreground,
                ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: ClayTokens.muted.withValues(alpha: 0.85)),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
