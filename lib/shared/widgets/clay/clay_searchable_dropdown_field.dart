import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

/// Dropdown com busca por texto e lista em ordem alfabética.
class ClaySearchableDropdownField<T extends Object> extends StatelessWidget {
  const ClaySearchableDropdownField({
    super.key,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.label,
    this.hint,
    this.value,
    this.validator,
  });

  final List<T> items;
  final String Function(T item) itemLabel;
  final void Function(T?) onChanged;
  final String? label;
  final String? hint;
  final T? value;
  final String? Function(T?)? validator;

  List<T> get _sortedItems {
    final list = [...items];
    list.sort(
      (a, b) => itemLabel(a).toLowerCase().compareTo(itemLabel(b).toLowerCase()),
    );
    return list;
  }

  Iterable<T> _filter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _sortedItems;
    return _sortedItems.where((item) => itemLabel(item).toLowerCase().contains(q));
  }

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
        FormField<T>(
          initialValue: value,
          validator: validator,
          builder: (fieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: ClayTokens.surface,
                    borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                    boxShadow: ClayDecorations.insetShadows(),
                    border: Border.all(
                      color: fieldState.hasError
                          ? ClayTokens.error
                          : ClayTokens.highlight.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Autocomplete<T>(
                    key: ValueKey(value == null ? 'empty' : itemLabel(value as T)),
                    initialValue: value != null
                        ? TextEditingValue(text: itemLabel(value as T))
                        : const TextEditingValue(),
                    displayStringForOption: itemLabel,
                    optionsBuilder: (query) => _filter(query.text),
                    onSelected: (option) {
                      fieldState.didChange(option);
                      onChanged(option);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ClayTokens.foreground,
                            ),
                        decoration: InputDecoration(
                          hintText: hint ?? 'Digite para buscar…',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          suffixIcon: value != null
                              ? IconButton(
                                  tooltip: 'Limpar',
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  color: ClayTokens.textMuted,
                                  onPressed: () {
                                    controller.clear();
                                    fieldState.didChange(null);
                                    onChanged(null);
                                  },
                                )
                              : const Icon(Icons.search_rounded, size: 20, color: ClayTokens.textMuted),
                        ),
                        onChanged: (text) {
                          if (text.trim().isEmpty) {
                            fieldState.didChange(null);
                            onChanged(null);
                          }
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 12,
                          color: ClayTokens.surfaceRaised,
                          borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280, minWidth: 280),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Text(
                                      itemLabel(option),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (fieldState.hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    fieldState.errorText!,
                    style: const TextStyle(color: ClayTokens.error, fontSize: 12),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
