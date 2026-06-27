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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ClayTokens.textSecondary,
                ),
          ),
          SizedBox(height: ClayTokens.gap(8)),
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
            borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
            dropdownColor: ClayTokens.surfaceRaised,
            elevation: 12,
            menuMaxHeight: 320,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: ClayTokens.muted,
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ClayTokens.foreground,
                ),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        itemLabel(item),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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
