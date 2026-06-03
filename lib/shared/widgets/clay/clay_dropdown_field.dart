import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

class ClayDropdownField<T> extends StatelessWidget {
  const ClayDropdownField({
    super.key,
    required this.items,
    required this.itemLabel,
    this.label,
    this.hint,
    this.value,
    this.onChanged,
    this.validator,
  });

  final List<T> items;
  final String Function(T item) itemLabel;
  final String? label;
  final String? hint;
  final T? value;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: validator,
          ),
        ),
      ],
    );
  }
}
