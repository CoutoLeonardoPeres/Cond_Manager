import 'package:cond_manager/shared/widgets/form/responsive_filter_layout.dart';
import 'package:flutter/material.dart';

/// Carrossel horizontal de filtros do módulo financeiro (mobile) e grade em telas largas.
class FinancialListFiltersBar extends StatelessWidget {
  const FinancialListFiltersBar({
    super.key,
    required this.fields,
    this.wideColumns = 3,
    this.mobileItemHeight = 92,
    this.trailing,
  });

  final List<Widget> fields;
  final int wideColumns;
  final double mobileItemHeight;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ResponsiveFilterLayout(
      wideColumns: wideColumns.clamp(1, fields.length),
      mobileItemHeight: mobileItemHeight,
      fields: fields,
      trailing: trailing,
    );
  }
}
