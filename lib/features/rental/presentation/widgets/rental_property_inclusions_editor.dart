import 'package:cond_manager/features/rental/domain/entities/rental_inclusion_catalog_item.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_inclusion.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/rental_inclusion_category.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tabela estilo planilha para itens inclusos na locação.
class RentalPropertyInclusionsEditor extends ConsumerWidget {
  const RentalPropertyInclusionsEditor({
    super.key,
    required this.companyId,
    required this.items,
    required this.onChanged,
    required this.columns,
  });

  final String companyId;
  final List<RentalPropertyInclusionInput> items;
  final ValueChanged<List<RentalPropertyInclusionInput>> onChanged;
  final int columns;

  static const _utilities = [
    RentalInclusionCategory.condominiumFee,
    RentalInclusionCategory.water,
    RentalInclusionCategory.electricity,
    RentalInclusionCategory.internet,
    RentalInclusionCategory.gas,
  ];

  static final _tableBorder = TableBorder.all(
    color: ClayTokens.shadowDark.withValues(alpha: 0.35),
    width: 1,
  );

  void _updateItem(int index, RentalPropertyInclusionInput item) {
    final next = [...items];
    next[index] = item;
    onChanged(next);
  }

  void _removeItem(int index) {
    onChanged([...items]..removeAt(index));
  }

  void _addBlankRow() {
    onChanged([
      ...items,
      RentalPropertyInclusionInput(
        category: RentalInclusionCategory.other,
        customName: '',
        sortOrder: items.length,
      ),
    ]);
  }

  void _addItem(RentalPropertyInclusionInput item) {
    onChanged([...items, item.copyWith(sortOrder: items.length)]);
  }

  Future<void> _showPickItemSheet(
    BuildContext context,
    List<RentalInclusionCatalogItem> catalog,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClaySurface(
        depth: ClayDepth.raised,
        radius: ClayTokens.radiusLg,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Inserir item pré-cadastrado',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Text(
                  'Utilidades',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ClayTokens.accent,
                      ),
                ),
                const SizedBox(height: 8),
                ..._utilities.map(
                  (cat) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(cat.label),
                    trailing: const Icon(Icons.add_rounded, size: 20),
                    onTap: () {
                      Navigator.pop(ctx);
                      _addItem(RentalPropertyInclusionInput(category: cat));
                    },
                  ),
                ),
                if (catalog.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Catálogo da empresa',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ClayTokens.accent,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...catalog.map(
                    (c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(c.name),
                      subtitle: Text(c.category.label, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.add_rounded, size: 20),
                      onTap: () {
                        Navigator.pop(ctx);
                        _addItem(
                          RentalPropertyInclusionInput(
                            category: c.category,
                            catalogItemId: c.id,
                            customName: c.name,
                            amount: c.defaultAmount,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCatalogDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    var category = RentalInclusionCategory.appliance;
    final amountController = TextEditingController();
    String? error;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Cadastrar item no catálogo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Itens do catálogo ficam disponíveis em todos os imóveis da empresa.',
                  style: TextStyle(fontSize: 13, color: ClayTokens.textSecondary),
                ),
                const SizedBox(height: 14),
                ClayTextField(
                  controller: nameController,
                  label: 'Nome *',
                  hint: 'Ex.: AirFryer, Video Game',
                ),
                const SizedBox(height: 12),
                ClayDropdownField<RentalInclusionCategory>(
                  label: 'Categoria',
                  value: category,
                  items: RentalInclusionCategory.values,
                  itemLabel: (c) => c.label,
                  onChanged: (v) {
                    if (v != null) setDialogState(() => category = v);
                  },
                ),
                const SizedBox(height: 12),
                ClayTextField(
                  controller: amountController,
                  label: 'Valor padrão (R\$)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: ClayTokens.error, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => error = 'Informe o nome do item.');
                  return;
                }
                final amountText = amountController.text.trim();
                final amount = amountText.isEmpty
                    ? null
                    : double.tryParse(amountText.replaceAll(',', '.'));

                final result = await ref.read(rentalRepositoryProvider).createInclusionCatalogItem(
                      RentalInclusionCatalogInput(
                        companyId: companyId,
                        name: name,
                        category: category,
                        defaultAmount: amount,
                      ),
                    );

                result.when(
                  success: (_) => Navigator.pop(ctx, true),
                  failure: (e) => setDialogState(() => error = e.message),
                );
              },
              child: const Text('Salvar no catálogo'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    amountController.dispose();

    if (saved == true) {
      ref.invalidate(rentalInclusionCatalogProvider(companyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item adicionado ao catálogo da empresa.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(rentalInclusionCatalogProvider(companyId));
    final catalog = catalogAsync.value ?? [];

    return FormGridSection(
      title: 'Itens inclusos na locação',
      columns: columns,
      items: [
        FormGridField(
          span: columns,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Monte a lista como uma planilha: descrição, valor e se está incluso no aluguel.',
                style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                child: Table(
                  border: _tableBorder,
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FixedColumnWidth(120),
                    2: FixedColumnWidth(150),
                    3: FixedColumnWidth(44),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: ClayTokens.surfacePressed),
                      children: [
                        _headerCell('Item / Descrição'),
                        _headerCell('Valor (R\$)', align: TextAlign.center),
                        _headerCell('Incluso na locação?', align: TextAlign.center),
                        _headerCell('', align: TextAlign.center),
                      ],
                    ),
                    if (items.isEmpty)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
                            child: Text(
                              'Clique em + Adicionar linha para começar a montar a tabela.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: ClayTokens.textMuted,
                                  ),
                            ),
                          ),
                          const SizedBox.shrink(),
                          const SizedBox.shrink(),
                          const SizedBox.shrink(),
                        ],
                      )
                    else
                      ...items.asMap().entries.map(
                            (e) => TableRow(
                              children: [
                                _InclusionDescriptionCell(
                                  item: e.value,
                                  onChanged: (v) => _updateItem(e.key, v),
                                ),
                                _InclusionAmountCell(
                                  item: e.value,
                                  onChanged: (v) => _updateItem(e.key, v),
                                ),
                                _InclusionIncludedCell(
                                  item: e.value,
                                  onChanged: (v) => _updateItem(e.key, v),
                                ),
                                _InclusionDeleteCell(onRemove: () => _removeItem(e.key)),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Material(
                    color: ClayTokens.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                    child: InkWell(
                      onTap: _addBlankRow,
                      borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 22, color: ClayTokens.accent),
                            SizedBox(width: 6),
                            Text(
                              'Adicionar linha',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ClayTokens.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () => _showPickItemSheet(context, catalog),
                    icon: const Icon(Icons.playlist_add_rounded, size: 18),
                    label: const Text('Inserir pré-cadastrado'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showCatalogDialog(context, ref),
                    icon: const Icon(Icons.library_add_outlined, size: 18),
                    label: const Text('Catálogo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: ClayTokens.textSecondary,
        ),
      ),
    );
  }
}

class _InclusionDescriptionCell extends StatefulWidget {
  const _InclusionDescriptionCell({required this.item, required this.onChanged});

  final RentalPropertyInclusionInput item;
  final ValueChanged<RentalPropertyInclusionInput> onChanged;

  @override
  State<_InclusionDescriptionCell> createState() => _InclusionDescriptionCellState();
}

class _InclusionDescriptionCellState extends State<_InclusionDescriptionCell> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _text(widget.item));
  }

  @override
  void didUpdateWidget(covariant _InclusionDescriptionCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _text(widget.item);
    if (_controller.text != next) _controller.text = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _text(RentalPropertyInclusionInput item) {
    if (item.descriptionEditable) return item.customName ?? '';
    return item.displayName;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.item.descriptionEditable) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          widget.item.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Descrição do item',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        onChanged: (v) => widget.onChanged(
          widget.item.copyWith(
            customName: v.trim().isEmpty ? null : v.trim(),
          ),
        ),
      ),
    );
  }
}

class _InclusionAmountCell extends StatefulWidget {
  const _InclusionAmountCell({required this.item, required this.onChanged});

  final RentalPropertyInclusionInput item;
  final ValueChanged<RentalPropertyInclusionInput> onChanged;

  @override
  State<_InclusionAmountCell> createState() => _InclusionAmountCellState();
}

class _InclusionAmountCellState extends State<_InclusionAmountCell> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.item.amount != null ? widget.item.amount.toString() : '',
    );
  }

  @override
  void didUpdateWidget(covariant _InclusionAmountCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.item.amount != null ? widget.item.amount.toString() : '';
    if (_controller.text != next) _controller.text = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          hintText: '0,00',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        onChanged: (v) {
          final amount = double.tryParse(v.replaceAll(',', '.'));
          widget.onChanged(
            widget.item.copyWith(
              amount: amount != null && amount >= 0 ? amount : null,
              clearAmount: amount == null,
            ),
          );
        },
      ),
    );
  }
}

class _InclusionIncludedCell extends StatelessWidget {
  const _InclusionIncludedCell({required this.item, required this.onChanged});

  final RentalPropertyInclusionInput item;
  final ValueChanged<RentalPropertyInclusionInput> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          isExpanded: true,
          value: item.includedInRent,
          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
          items: const [
            DropdownMenuItem(value: true, child: Text('Sim', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: false, child: Text('Não', style: TextStyle(fontSize: 13))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(item.copyWith(includedInRent: v));
          },
        ),
      ),
    );
  }
}

class _InclusionDeleteCell extends StatelessWidget {
  const _InclusionDeleteCell({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: 'Remover linha',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        onPressed: onRemove,
        icon: const Icon(Icons.close_rounded, size: 18, color: ClayTokens.error),
      ),
    );
  }
}
