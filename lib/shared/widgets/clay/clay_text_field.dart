import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClayTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: ClayTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: ClayTokens.surface,
            borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
            boxShadow: ClayDecorations.insetShadows(),
            border: Border.all(
              color: ClayTokens.highlight.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
            maxLines: maxLines,
            readOnly: readOnly,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: ClayTokens.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
