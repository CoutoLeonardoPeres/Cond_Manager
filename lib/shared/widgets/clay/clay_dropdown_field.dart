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
    this.compact = false,
  });

  final List<T> items;
  final String Function(T item) itemLabel;
  final String? label;
  final String? hint;
  final T? value;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ClayTokens.foreground,
          fontSize: compact ? 13 : null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (compact
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.labelMedium)
                ?.copyWith(
              fontWeight: FontWeight.w600,
              color: ClayTokens.textSecondary,
            ),
          ),
          SizedBox(height: compact ? 4 : ClayTokens.gap(8)),
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
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
          child: DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            isDense: compact,
            borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
            dropdownColor: ClayTokens.surfaceRaised,
            elevation: 12,
            menuMaxHeight: 320,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: ClayTokens.muted,
              size: compact ? 20 : 24,
            ),
            style: bodyStyle,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              isDense: compact,
              contentPadding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
            ),
            selectedItemBuilder: (context) => items
                .map(
                  (item) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      itemLabel(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle,
                    ),
                  ),
                )
                .toList(),
            items: items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        itemLabel(item),
                        overflow: TextOverflow.ellipsis,
                        maxLines: compact ? 2 : 1,
                        style: bodyStyle,
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
