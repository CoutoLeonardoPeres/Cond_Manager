import 'package:cond_manager/shared/widgets/form/clay_form_grid.dart';
import 'package:cond_manager/shared/widgets/form/filter_carousel_layout.dart';
import 'package:flutter/material.dart';

/// Carrossel de filtros no mobile; [FormGrid] em telas largas.
class ResponsiveFilterLayout extends StatelessWidget {
  const ResponsiveFilterLayout({
    super.key,
    required this.fields,
    this.wideBreakpoint = FilterCarouselLayout.mobileBreakpoint,
    this.wideColumns = 3,
    this.mobileItemHeight = 84,
    this.trailing,
  });

  final List<Widget> fields;
  final double wideBreakpoint;
  final int wideColumns;
  final double mobileItemHeight;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= wideBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormGrid(
                columns: wideColumns,
                items: fields.map((f) => FormGridField(child: f)).toList(),
              ),
              if (trailing != null) ...[
                const SizedBox(height: 8),
                trailing!,
              ],
            ],
          );
        }

        return FilterCarouselLayout(
          items: fields,
          itemHeight: mobileItemHeight,
          trailing: trailing,
        );
      },
    );
  }
}
