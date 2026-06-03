import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/widgets/clay/clay_surface.dart';
import 'package:flutter/material.dart';

/// Quantidade de colunas do formulário conforme a largura disponível (máx. 3).
int formColumnsForWidth(double width) {
  if (width >= 1000) return 3;
  if (width >= 640) return 2;
  return 1;
}

/// Campo posicionado na grade do formulário. [span] ocupa até [columns] colunas.
class FormGridField {
  const FormGridField({required this.child, this.span = 1});

  final Widget child;
  final int span;
}

/// Seção agrupada com título e campos em grade responsiva.
class FormGridSection extends StatelessWidget {
  const FormGridSection({
    super.key,
    required this.title,
    required this.columns,
    required this.items,
  });

  final String title;
  final int columns;
  final List<FormGridField> items;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.raised,
      radius: ClayTokens.radiusLg,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ClayTokens.primary,
            ),
          ),
          const SizedBox(height: 16),
          FormGrid(columns: columns, items: items),
        ],
      ),
    );
  }
}

/// Grade de campos com até 3 colunas (valor passado em [columns]).
class FormGrid extends StatelessWidget {
  const FormGrid({super.key, required this.columns, required this.items});

  final int columns;
  final List<FormGridField> items;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var index = 0;

    while (index < items.length) {
      var colUsed = 0;
      final rowCells = <Widget>[];

      while (index < items.length && colUsed < columns) {
        final item = items[index];
        var span = item.span.clamp(1, columns);

        if (span > columns - colUsed) {
          if (rowCells.isNotEmpty) break;
          span = columns - colUsed;
        }

        rowCells.add(_cell(item.child, span, rowCells.isEmpty));
        colUsed += span;
        index++;
      }

      while (colUsed < columns) {
        rowCells.add(_cell(const SizedBox(), 1, rowCells.isEmpty));
        colUsed++;
      }

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowCells,
        ),
      );
      if (index < items.length) {
        rows.add(const SizedBox(height: 14));
      }
    }

    return Column(children: rows);
  }

  Widget _cell(Widget child, int flex, bool isFirst) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.only(left: isFirst ? 0 : 12),
        child: child,
      ),
    );
  }
}
