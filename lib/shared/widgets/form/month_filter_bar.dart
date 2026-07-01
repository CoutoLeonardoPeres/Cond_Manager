import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Navegação por mês para filtros de listas e relatórios.
class MonthFilterBar extends StatelessWidget {
  const MonthFilterBar({
    super.key,
    required this.month,
    required this.onChanged,
    this.compact = false,
    this.width,
    this.minHeight,
  });

  final DateTime? month;
  final ValueChanged<DateTime?> onChanged;
  final bool compact;
  final double? width;
  final double? minHeight;

  static final _monthFmt = DateFormat('MMM/yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final label = month == null ? 'Todos os meses' : _monthFmt.format(month!);

    final bar = ClaySurface(
      depth: ClayDepth.pressed,
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 8, vertical: compact ? 2 : 6),
      child: Row(
        mainAxisSize: width != null || !compact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
            padding: compact ? EdgeInsets.zero : null,
            constraints: compact ? const BoxConstraints(minWidth: 32, minHeight: 32) : null,
            onPressed: month == null
                ? null
                : () {
                    final m = month!;
                    onChanged(DateTime(m.year, m.month - 1));
                  },
            icon: Icon(Icons.chevron_left_rounded, size: compact ? 20 : 24),
          ),
          if (compact)
            Expanded(
              child: InkWell(
                onTap: () => _pickMonth(context),
                borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: ClayTokens.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: InkWell(
                onTap: () => _pickMonth(context),
                borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: ClayTokens.primary),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Próximo mês',
            visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
            padding: compact ? EdgeInsets.zero : null,
            constraints: compact ? const BoxConstraints(minWidth: 32, minHeight: 32) : null,
            onPressed: month == null
                ? () => onChanged(DateTime(DateTime.now().year, DateTime.now().month))
                : () {
                    final m = month!;
                    onChanged(DateTime(m.year, m.month + 1));
                  },
            icon: Icon(Icons.chevron_right_rounded, size: compact ? 20 : 24),
          ),
          if (!compact)
            TextButton(
              onPressed: month == null ? null : () => onChanged(null),
              child: const Text('Limpar'),
            )
          else if (month != null)
            IconButton(
              tooltip: 'Limpar mês',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close_rounded, size: 16),
            ),
        ],
      ),
    );

    if (minHeight != null) {
      return SizedBox(
        height: minHeight,
        child: Center(child: bar),
      );
    }
    return bar;
  }

  Future<void> _pickMonth(BuildContext context) async {
    final initial = month ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    onChanged(DateTime(picked.year, picked.month));
  }
}
