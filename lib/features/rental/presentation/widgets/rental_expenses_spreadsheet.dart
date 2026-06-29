import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium_block.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/materials/domain/entities/material.dart' as mat;
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_expense_list_filter.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_expense_location.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_expense_mapping.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/condominium_bill_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:cond_manager/shared/domain/enums/rental_expense_entry_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _spreadsheetDateFmt = DateFormat('dd/MM/yyyy');
final _spreadsheetCurrency = NumberFormat.simpleCurrency(locale: 'pt_BR');

/// Planilha editável para despesas de locação (estilo Excel).
class RentalExpensesSpreadsheet extends ConsumerStatefulWidget {
  const RentalExpensesSpreadsheet({
    super.key,
    required this.expenses,
    required this.condominiums,
    required this.filter,
    required this.canEdit,
  });

  final List<FinancialRecord> expenses;
  final List<Condominium> condominiums;
  final RentalExpenseListFilter filter;
  final bool canEdit;

  @override
  ConsumerState<RentalExpensesSpreadsheet> createState() => _RentalExpensesSpreadsheetState();
}

class _RentalExpensesSpreadsheetState extends ConsumerState<RentalExpensesSpreadsheet> {
  static const _tableWidth = 1340.0;

  static final _tableBorder = TableBorder.all(
    color: ClayTokens.shadowDark.withValues(alpha: 0.35),
    width: 1,
  );

  final List<_ExpenseRowData> _rows = [];
  int _draftCounter = 0;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _syncFromExpenses();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RentalExpensesSpreadsheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final expensesChanged = !_expenseListsEquivalent(oldWidget.expenses, widget.expenses);
    if (expensesChanged || oldWidget.condominiums != widget.condominiums) {
      _syncFromExpenses();
    }
  }

  bool _expenseListsEquivalent(List<FinancialRecord> a, List<FinancialRecord> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  _ExpenseRowData _mergePreservedRow(_ExpenseRowData row, FinancialRecord expense) {
    Condominium? condo = row.condominium;
    if (condo == null && expense.condominiumId != null) {
      for (final c in widget.condominiums) {
        if (c.id == expense.condominiumId) {
          condo = c;
          break;
        }
      }
    }
    return row.copyWith(
      condominium: condo,
      condominiumId: row.condominiumId ?? expense.condominiumId,
      condominiumName: row.condominiumName ?? expense.condominiumName,
    );
  }

  void _syncFromExpenses() {
    final expenseById = {for (final e in widget.expenses) e.id: e};
    final drafts = _rows.where((r) => r.isDraft).toList();
    final preservedById = {
      for (final r in _rows.where((r) => !r.isDraft && (r.isDirty || r.isSaving)))
        r.expenseId!: r,
    };

    final merged = <_ExpenseRowData>[];
    final seen = <String>{};

    for (final row in _rows) {
      if (row.isDraft) continue;
      final id = row.expenseId!;
      final expense = expenseById[id];
      if (expense == null) continue;
      seen.add(id);
      merged.add(
        preservedById.containsKey(id)
            ? _mergePreservedRow(preservedById[id]!, expense)
            : _ExpenseRowData.fromRecord(expense, widget.condominiums),
      );
    }

    final sortedNew = widget.expenses.where((e) => !seen.contains(e.id)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final expense in sortedNew) {
      merged.add(_ExpenseRowData.fromRecord(expense, widget.condominiums));
    }

    setState(() {
      _rows
        ..clear()
        ..addAll(merged)
        ..addAll(drafts);
    });
  }

  void _updateRow(
    int index,
    _ExpenseRowData Function(_ExpenseRowData current) transform, {
    bool commit = true,
    bool notifyValidation = false,
    bool quiet = true,
  }) {
    final next = transform(_rows[index]);
    if (commit) {
      _commitRow(index, next, notifyValidation: notifyValidation, quiet: quiet);
    } else {
      _patchRow(index, next);
    }
  }

  void _addDraftRow() {
    setState(() {
      _rows.add(
        _ExpenseRowData.draft(
          key: 'draft_${_draftCounter++}',
          filter: widget.filter,
          condominiums: widget.condominiums,
        ),
      );
    });
  }

  void _patchRow(int index, _ExpenseRowData next) {
    setState(() => _rows[index] = next.copyWith(isDirty: true));
  }

  void _commitRow(
    int index,
    _ExpenseRowData next, {
    bool notifyValidation = false,
    bool quiet = true,
  }) {
    setState(() => _rows[index] = next.copyWith(isDirty: true));
    _saveRow(index, row: next, notifyValidation: notifyValidation, quiet: quiet);
  }

  String _effectiveDescription(_ExpenseRowData row) {
    final trimmed = row.description.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return switch (row.entryType) {
      RentalExpenseEntryType.fixedBill => row.billType.label,
      RentalExpenseEntryType.service => row.serviceType.label,
      RentalExpenseEntryType.material => row.materialCategoryName ?? 'Material',
    };
  }

  String? _validate(_ExpenseRowData row) {
    if (row.condominium == null && row.condominiumId == null) return 'Selecione o condomínio.';
    if (_effectiveDescription(row).isEmpty) return 'Informe a descrição.';
    if (row.amount <= 0) return 'Informe um valor válido.';
    if (row.entryType == RentalExpenseEntryType.material && row.materialCategoryId == null) {
      return 'Selecione a categoria de material.';
    }
    return null;
  }

  FinancialRecordCreateInput _buildCreateInput(_ExpenseRowData row) {
    final category = financialCategoryForRentalExpense(
      entryType: row.entryType,
      billType: row.entryType == RentalExpenseEntryType.fixedBill ? row.billType : null,
    );
    final condominiumId = row.condominium?.id ?? row.condominiumId;
    return FinancialRecordCreateInput(
      scope: FinancialScope.condominium,
      condominiumId: condominiumId!,
      recordType: FinancialRecordType.expense,
      category: category,
      description: _effectiveDescription(row),
      amount: row.amount,
      referenceDate: row.referenceDate,
      dueDate: row.dueDate,
      paidAt: row.isPaid ? DateTime.now() : null,
      unitId: null,
      blockId: row.location.blockId,
      rentalPropertyId: row.location.rentalPropertyId,
      rentalExpenseEntryType: row.entryType,
      condominiumBillType:
          row.entryType == RentalExpenseEntryType.fixedBill ? row.billType : null,
      expenseServiceType: row.entryType == RentalExpenseEntryType.service ? row.serviceType : null,
      materialCategoryId:
          row.entryType == RentalExpenseEntryType.material ? row.materialCategoryId : null,
      isRecurringTemplate:
          row.entryType == RentalExpenseEntryType.fixedBill && row.isRecurringTemplate,
      recurrenceDayOfMonth: row.isRecurringTemplate ? row.recurrenceDay : null,
    );
  }

  FinancialRecordUpdateInput _buildUpdateInput(_ExpenseRowData row, FinancialRecord existing) {
    final category = financialCategoryForRentalExpense(
      entryType: row.entryType,
      billType: row.entryType == RentalExpenseEntryType.fixedBill ? row.billType : null,
    );
    return FinancialRecordUpdateInput(
      recordType: existing.recordType,
      category: category,
      description: _effectiveDescription(row),
      amount: row.amount,
      referenceDate: row.referenceDate,
      dueDate: row.dueDate,
      paidAt: row.isPaid ? (existing.paidAt ?? DateTime.now()) : null,
      unitId: null,
      blockId: row.location.blockId,
      rentalPropertyId: row.location.rentalPropertyId,
      rentalExpenseEntryType: row.entryType,
      condominiumBillType:
          row.entryType == RentalExpenseEntryType.fixedBill ? row.billType : null,
      expenseServiceType: row.entryType == RentalExpenseEntryType.service ? row.serviceType : null,
      materialCategoryId:
          row.entryType == RentalExpenseEntryType.material ? row.materialCategoryId : null,
      isRecurringTemplate:
          row.entryType == RentalExpenseEntryType.fixedBill && row.isRecurringTemplate,
      recurrenceDayOfMonth: row.isRecurringTemplate ? row.recurrenceDay : null,
    );
  }

  Future<void> _saveRow(
    int index, {
    _ExpenseRowData? row,
    bool notifyValidation = false,
    bool quiet = true,
  }) async {
    if (!widget.canEdit) return;
    final current = row ?? _rows[index];
    if (!current.isDirty || current.isSaving) return;

    final error = _validate(current);
    if (error != null) {
      if (notifyValidation && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    setState(() => _rows[index] = current.copyWith(isSaving: true));

    final repo = ref.read(financialRepositoryProvider);

    if (current.isDraft) {
      final result = await repo.create(_buildCreateInput(current));
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalExpensesListProvider);
          ref.invalidate(rentalExpenseDueAlertsProvider);
          setState(() => _rows.removeAt(index));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Despesa registrada.')),
          );
        },
        failure: (e) {
          setState(() => _rows[index] = current.copyWith(isSaving: false));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        },
      );
      return;
    }

    FinancialRecord? existing;
    for (final e in widget.expenses) {
      if (e.id == current.expenseId) {
        existing = e;
        break;
      }
    }
    if (existing == null) {
      setState(() => _rows[index] = current.copyWith(isSaving: false));
      return;
    }

    final result = await repo.update(current.expenseId!, _buildUpdateInput(current, existing));
    if (!mounted) return;
    result.when(
      success: (updated) {
        ref.invalidate(rentalExpensesListProvider);
        ref.invalidate(rentalExpenseDueAlertsProvider);
        setState(() {
          _rows[index] = _ExpenseRowData.fromRecord(updated, widget.condominiums);
        });
        if (!quiet) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Despesa atualizada.')),
          );
        }
      },
      failure: (e) {
        setState(() => _rows[index] = current.copyWith(isSaving: false));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }

  Future<void> _deleteRow(int index) async {
    if (!widget.canEdit) return;
    final row = _rows[index];
    if (row.isSaving) return;

    if (row.isDraft) {
      setState(() => _rows.removeAt(index));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir despesa?'),
        content: Text('Remover "${_effectiveDescription(row)}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: ClayTokens.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _rows[index] = row.copyWith(isSaving: true));
    final result = await ref.read(financialRepositoryProvider).delete(row.expenseId!);
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(rentalExpensesListProvider);
        ref.invalidate(rentalExpenseDueAlertsProvider);
        ref.invalidate(rentalExpenseDetailProvider(row.expenseId!));
        setState(() => _rows.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Despesa excluída.')),
        );
      },
      failure: (e) {
        setState(() => _rows[index] = row.copyWith(isSaving: false));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Widget _headerCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: ClayTokens.textSecondary,
        ),
      ),
    );
  }

  Widget _cellPadding({required Widget child, bool highlight = false}) {
    return Container(
      color: highlight ? ClayTokens.accent.withValues(alpha: 0.06) : null,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: child,
    );
  }

  TableRow _buildDataRow(int index, _ExpenseRowData row) {
    final editable = widget.canEdit && !row.isSaving;
    final highlight = row.isDraft || row.isDirty;

    return TableRow(
      decoration: row.isRecurringTemplate && !row.isDraft
          ? BoxDecoration(
              color: ClayTokens.tertiary.withValues(alpha: 0.04),
            )
          : null,
      children: [
        _cellPadding(
          highlight: highlight,
          child: _CondoDropdown(
            enabled: editable,
            condominiums: widget.condominiums,
            value: row.condominium,
            condominiumId: row.condominiumId,
            fallbackName: row.condominiumName,
            onChanged: (c) {
              if (_rows[index].isDraft) {
                _updateRow(
                  index,
                  (_ExpenseRowData current) => current.copyWith(
                        condominium: c,
                        condominiumId: c?.id,
                        condominiumName: c?.name,
                        clearLocation: true,
                        clearMaterialCategory: true,
                      ),
                  commit: false,
                );
                final updated = _rows[index];
                _saveRow(index, row: updated);
              } else {
                _updateRow(
                  index,
                  (_ExpenseRowData current) => current.copyWith(
                        condominium: c,
                        condominiumId: c?.id,
                        condominiumName: c?.name,
                        clearLocation: true,
                        clearMaterialCategory: true,
                      ),
                );
              }
            },
          ),
        ),
        _cellPadding(
          highlight: highlight,
          child: _LocationDropdown(
            key: ValueKey('location_${row.key}_${row.condominiumId ?? row.condominium?.id}'),
            enabled: editable,
            condominiumId: row.condominiumId ?? row.condominium?.id,
            value: row.location,
            onChanged: (location) {
              if (_rows[index].isDraft) {
                _updateRow(
                  index,
                  (_ExpenseRowData current) => current.copyWith(location: location),
                  commit: false,
                );
                _saveRow(index, row: _rows[index]);
              } else {
                _updateRow(
                  index,
                  (_ExpenseRowData current) => current.copyWith(location: location),
                );
              }
            },
          ),
        ),
        _cellPadding(
          highlight: highlight,
          child: _EntryTypeDropdown(
            enabled: editable,
            value: row.entryType,
            onChanged: (t) {
              if (_rows[index].isDraft) {
                _updateRow(
                  index,
                  (_ExpenseRowData current) => current.copyWith(
                        entryType: t,
                        isRecurringTemplate:
                            t == RentalExpenseEntryType.fixedBill && current.billType.typicallyRecurring,
                      ),
                  commit: false,
                );
                _saveRow(index, row: _rows[index]);
              } else {
                _updateRow(
                  index,
                  (_ExpenseRowData current) => current.copyWith(
                        entryType: t,
                        isRecurringTemplate:
                            t == RentalExpenseEntryType.fixedBill && current.billType.typicallyRecurring,
                      ),
                );
              }
            },
          ),
        ),
        _cellPadding(
          highlight: highlight,
          child: _CategoryCell(
            enabled: editable,
            row: row,
            onPatch: (patch) {
              if (_rows[index].isDraft) {
                _updateRow(index, patch, commit: false);
                _saveRow(index, row: patch(_rows[index]));
              } else {
                _updateRow(index, patch);
              }
            },
          ),
        ),
        _cellPadding(
          highlight: highlight,
          child: _TextCell(
            enabled: editable,
            value: row.description,
            hint: 'Descrição',
            onCommit: (v) => _updateRow(
              index,
              (current) => current.copyWith(description: v),
              notifyValidation: true,
            ),
          ),
        ),
        _cellPadding(
          highlight: highlight,
          child: _AmountCell(
            enabled: editable,
            value: row.amount,
            onCommit: (v) => _updateRow(
              index,
              (current) => current.copyWith(amount: v),
              notifyValidation: true,
            ),
          ),
        ),
        _cellPadding(
          highlight: highlight,
          child: _DateCell(
            enabled: editable,
            date: row.referenceDate,
            onTap: () => _pickDate(
              initial: row.referenceDate,
              onPicked: (d) => _updateRow(
                index,
                (current) => current.copyWith(referenceDate: d),
              ),
            ),
          ),
        ),
        _cellPadding(
          highlight: highlight,
          child: _DateCell(
            enabled: editable,
            date: row.dueDate,
            placeholder: '—',
            onTap: () => _pickDate(
              initial: row.dueDate ?? row.referenceDate,
              onPicked: (d) => _updateRow(
                index,
                (current) => current.copyWith(dueDate: d),
              ),
            ),
          ),
        ),
        _cellPadding(
          highlight: highlight,
          child: row.entryType == RentalExpenseEntryType.fixedBill
              ? _RecurrenceCell(
                  enabled: editable,
                  isTemplate: row.isRecurringTemplate,
                  day: row.recurrenceDay,
                  onTemplateChanged: (v) => _updateRow(
                        index,
                        (current) => current.copyWith(isRecurringTemplate: v),
                      ),
                  onDayChanged: (d) => _updateRow(
                        index,
                        (current) => current.copyWith(recurrenceDay: d),
                      ),
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Text('—', style: TextStyle(color: ClayTokens.textMuted)),
                ),
        ),
        _cellPadding(
          highlight: highlight,
          child: Center(
            child: row.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Checkbox(
                    value: row.isPaid,
                    onChanged: editable
                        ? (v) => _updateRow(
                              index,
                              (current) => current.copyWith(isPaid: v ?? false),
                            )
                        : null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
          ),
        ),
        _cellPadding(
          child: Center(
            child: row.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (editable && (row.isDraft || row.isDirty))
                        IconButton(
                          icon: const Icon(Icons.save_rounded, size: 18),
                          tooltip: 'Salvar linha',
                          onPressed: () => _saveRow(
                            index,
                            row: _rows[index],
                            notifyValidation: true,
                            quiet: false,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                      if (row.isDraft)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: 'Remover rascunho',
                          onPressed: editable ? () => setState(() => _rows.removeAt(index)) : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        )
                      else ...[
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          tooltip: 'Excluir despesa',
                          onPressed: editable ? () => _deleteRow(index) : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          tooltip: 'Detalhes / rateio',
                          onPressed: () => context.go('/rental/expenses/${row.expenseId}'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollbarTheme = ScrollbarTheme.of(context).copyWith(
      thumbVisibility: WidgetStateProperty.all(true),
      trackVisibility: WidgetStateProperty.all(true),
      thickness: WidgetStateProperty.all(10),
      radius: const Radius.circular(4),
      crossAxisMargin: 2,
    );

    final table = ClipRRect(
      borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
      child: Table(
        border: _tableBorder,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(150),
          1: FixedColumnWidth(120),
          2: FixedColumnWidth(128),
          3: FixedColumnWidth(148),
          4: FixedColumnWidth(200),
          5: FixedColumnWidth(96),
          6: FixedColumnWidth(108),
          7: FixedColumnWidth(108),
          8: FixedColumnWidth(118),
          9: FixedColumnWidth(52),
          10: FixedColumnWidth(112),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: ClayTokens.surfacePressed),
            children: [
              _headerCell('Condomínio'),
                            _headerCell('Destino'),
              _headerCell('Tipo'),
              _headerCell('Categoria'),
              _headerCell('Descrição'),
              _headerCell('Valor', align: TextAlign.right),
              _headerCell('Data ref.'),
              _headerCell('Vencimento'),
              _headerCell('Recorrência'),
              _headerCell('Pago', align: TextAlign.center),
              _headerCell('Ações', align: TextAlign.center),
            ],
          ),
          if (_rows.isEmpty)
            TableRow(
              children: List.generate(
                11,
                (i) => i == 0
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
                        child: Text(
                          widget.canEdit
                              ? 'Nenhuma despesa. Clique em + Adicionar linha.'
                              : 'Nenhuma despesa cadastrada.',
                          style: const TextStyle(color: ClayTokens.textMuted, fontSize: 13),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            )
          else
            ..._rows.asMap().entries.map((entry) => _buildDataRow(entry.key, entry.value)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportWidth = constraints.maxWidth;
                final needsHorizontalScroll = _tableWidth > viewportWidth;

                return ScrollbarTheme(
                  data: scrollbarTheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, scrollConstraints) {
                            final viewportHeight = scrollConstraints.maxHeight;
                            if (!viewportHeight.isFinite || viewportHeight <= 0) {
                              return const SizedBox.shrink();
                            }

                            return ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                              child: Scrollbar(
                                controller: _horizontalScrollController,
                                thumbVisibility: needsHorizontalScroll,
                                trackVisibility: needsHorizontalScroll,
                                notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
                                child: Scrollbar(
                                  controller: _verticalScrollController,
                                  thumbVisibility: true,
                                  trackVisibility: true,
                                  notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
                                  child: SingleChildScrollView(
                                    controller: _horizontalScrollController,
                                    scrollDirection: Axis.horizontal,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      width: _tableWidth,
                                      height: viewportHeight,
                                      child: SingleChildScrollView(
                                        controller: _verticalScrollController,
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        child: table,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (needsHorizontalScroll) ...[
                        const SizedBox(height: 6),
                        _SpreadsheetHorizontalScrollbar(
                          controller: _horizontalScrollController,
                          contentWidth: _tableWidth,
                          viewportWidth: viewportWidth,
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.canEdit)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Material(
                  color: ClayTokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                  child: InkWell(
                    onTap: _addDraftRow,
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
                            style: TextStyle(fontWeight: FontWeight.w700, color: ClayTokens.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_rows.length} linha(s) · Enter ou sair do campo para salvar · use o ícone de salvar',
                  style: const TextStyle(color: ClayTokens.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExpenseRowData {
  const _ExpenseRowData({
    required this.key,
    required this.isDraft,
    this.expenseId,
    this.condominium,
    this.condominiumId,
    this.condominiumName,
    this.location = const RentalExpenseLocation.condominium(),
    required this.entryType,
    required this.billType,
    required this.serviceType,
    this.materialCategoryId,
    this.materialCategoryName,
    required this.description,
    required this.amount,
    required this.referenceDate,
    this.dueDate,
    required this.isRecurringTemplate,
    required this.recurrenceDay,
    required this.isPaid,
    this.isDirty = false,
    this.isSaving = false,
  });

  final String key;
  final bool isDraft;
  final String? expenseId;
  final Condominium? condominium;
  final String? condominiumId;
  final String? condominiumName;
  final RentalExpenseLocation location;
  final RentalExpenseEntryType entryType;
  final CondominiumBillType billType;
  final ServiceType serviceType;
  final String? materialCategoryId;
  final String? materialCategoryName;
  final String description;
  final double amount;
  final DateTime referenceDate;
  final DateTime? dueDate;
  final bool isRecurringTemplate;
  final int recurrenceDay;
  final bool isPaid;
  final bool isDirty;
  final bool isSaving;

  factory _ExpenseRowData.fromRecord(FinancialRecord r, List<Condominium> condos) {
    Condominium? condo;
    for (final c in condos) {
      if (c.id == r.condominiumId) {
        condo = c;
        break;
      }
    }
    return _ExpenseRowData(
      key: r.id,
      isDraft: false,
      expenseId: r.id,
      condominium: condo,
      condominiumId: r.condominiumId,
      condominiumName: r.condominiumName,
      location: RentalExpenseLocation.fromRecord(r),
      entryType: r.rentalExpenseEntryType ?? RentalExpenseEntryType.fixedBill,
      billType: r.condominiumBillType ?? CondominiumBillType.other,
      serviceType: r.expenseServiceType ?? ServiceType.other,
      materialCategoryId: r.materialCategoryId,
      materialCategoryName: r.materialCategoryName,
      description: r.description,
      amount: r.amount,
      referenceDate: r.referenceDate,
      dueDate: r.dueDate,
      isRecurringTemplate: r.isRecurringTemplate,
      recurrenceDay: r.recurrenceDayOfMonth ??
          r.dueDate?.day ??
          r.referenceDate.day,
      isPaid: r.isPaid,
    );
  }

  factory _ExpenseRowData.draft({
    required String key,
    required RentalExpenseListFilter filter,
    required List<Condominium> condominiums,
  }) {
    Condominium? condo;
    if (filter.condominiumId != null) {
      for (final c in condominiums) {
        if (c.id == filter.condominiumId) {
          condo = c;
          break;
        }
      }
    } else if (condominiums.length == 1) {
      condo = condominiums.first;
    }

    final month = filter.month ?? DateTime.now();
    final refDate = DateTime(month.year, month.month, DateTime.now().day);

    return _ExpenseRowData(
      key: key,
      isDraft: true,
      condominium: condo,
      condominiumId: condo?.id ?? filter.condominiumId,
      condominiumName: condo?.name,
      entryType: RentalExpenseEntryType.fixedBill,
      billType: CondominiumBillType.water,
      serviceType: ServiceType.other,
      description: '',
      amount: 0,
      referenceDate: refDate,
      isRecurringTemplate: true,
      recurrenceDay: 10,
      isPaid: false,
      isDirty: true,
    );
  }

  _ExpenseRowData copyWith({
    Condominium? condominium,
    String? condominiumId,
    String? condominiumName,
    RentalExpenseLocation? location,
    bool clearLocation = false,
    RentalExpenseEntryType? entryType,
    CondominiumBillType? billType,
    ServiceType? serviceType,
    String? materialCategoryId,
    String? materialCategoryName,
    bool clearMaterialCategory = false,
    String? description,
    double? amount,
    DateTime? referenceDate,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isRecurringTemplate,
    int? recurrenceDay,
    bool? isPaid,
    bool? isDirty,
    bool? isSaving,
  }) {
    final nextCondo = condominium ?? this.condominium;
    return _ExpenseRowData(
      key: key,
      isDraft: isDraft,
      expenseId: expenseId,
      condominium: nextCondo,
      condominiumId: condominiumId ?? nextCondo?.id ?? this.condominiumId,
      condominiumName: condominiumName ?? nextCondo?.name ?? this.condominiumName,
      location: clearLocation
          ? const RentalExpenseLocation.condominium()
          : (location ?? this.location),
      entryType: entryType ?? this.entryType,
      billType: billType ?? this.billType,
      serviceType: serviceType ?? this.serviceType,
      materialCategoryId:
          clearMaterialCategory ? null : (materialCategoryId ?? this.materialCategoryId),
      materialCategoryName:
          clearMaterialCategory ? null : (materialCategoryName ?? this.materialCategoryName),
      description: description ?? this.description,
      amount: amount ?? this.amount,
      referenceDate: referenceDate ?? this.referenceDate,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isRecurringTemplate: isRecurringTemplate ?? this.isRecurringTemplate,
      recurrenceDay: recurrenceDay ?? this.recurrenceDay,
      isPaid: isPaid ?? this.isPaid,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class _SpreadsheetDropdown<T> extends StatelessWidget {
  const _SpreadsheetDropdown({
    required this.enabled,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint,
  });

  final bool enabled;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? hint;

  T? _resolveValue() {
    if (value == null) {
      for (final item in items) {
        if (item == null) return null;
      }
      return null;
    }
    for (final item in items) {
      if (item == value) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        isExpanded: true,
        isDense: true,
        menuMaxHeight: 280,
        borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
        dropdownColor: ClayTokens.surfaceRaised,
        elevation: 12,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: ClayTokens.muted,
        ),
        value: _resolveValue(),
        hint: Text(hint ?? '—', style: const TextStyle(fontSize: 12, color: ClayTokens.textMuted)),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    itemLabel(item),
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _CondoDropdown extends StatelessWidget {
  const _CondoDropdown({
    required this.enabled,
    required this.condominiums,
    required this.value,
    required this.onChanged,
    this.condominiumId,
    this.fallbackName,
  });

  final bool enabled;
  final List<Condominium> condominiums;
  final Condominium? value;
  final ValueChanged<Condominium?> onChanged;
  final String? condominiumId;
  final String? fallbackName;

  Condominium? _resolveValue() {
    if (value != null) {
      for (final c in condominiums) {
        if (c.id == value!.id) return c;
      }
      return value;
    }
    if (condominiumId != null) {
      for (final c in condominiums) {
        if (c.id == condominiumId) return c;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveValue();
    if (!enabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          resolved?.name ?? fallbackName ?? '—',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _SpreadsheetDropdown<Condominium>(
        enabled: enabled,
        value: resolved,
        items: condominiums,
        itemLabel: (c) => c.name,
        onChanged: onChanged,
        hint: 'Condomínio',
      ),
    );
  }
}

class _LocationDropdown extends ConsumerWidget {
  const _LocationDropdown({
    super.key,
    required this.enabled,
    required this.condominiumId,
    required this.value,
    required this.onChanged,
  });

  final bool enabled;
  final String? condominiumId;
  final RentalExpenseLocation value;
  final ValueChanged<RentalExpenseLocation> onChanged;

  List<RentalExpenseLocation> _buildOptions(
    List<CondominiumBlock> blocks,
    List<RentalProperty> properties,
    RentalExpenseLocation current,
  ) {
    final sortedBlocks = [...blocks]..sort((a, b) => a.name.compareTo(b.name));
    final sortedProperties = [...properties]..sort((a, b) => a.title.compareTo(b.title));

    final options = <RentalExpenseLocation>[
      const RentalExpenseLocation.condominium(),
      ...sortedBlocks.map((b) => RentalExpenseLocation.block(id: b.id, name: b.name)),
      ...sortedProperties.map(
        (p) => RentalExpenseLocation.property(id: p.id, title: p.title),
      ),
    ];

    if (current.kind != RentalExpenseLocationKind.condominium &&
        !options.any((o) => o == current)) {
      options.add(current);
    }

    return options;
  }

  RentalExpenseLocation _resolveValue(
    List<RentalExpenseLocation> options,
    RentalExpenseLocation current,
  ) {
    for (final option in options) {
      if (option == current) return option;
    }
    return const RentalExpenseLocation.condominium();
  }

  Future<void> _openPicker(
    BuildContext context,
    List<CondominiumBlock> blocks,
    List<RentalProperty> properties,
    RentalExpenseLocation selected,
  ) async {
    final sortedBlocks = [...blocks]..sort((a, b) => a.name.compareTo(b.name));
    final sortedProperties = [...properties]..sort((a, b) => a.title.compareTo(b.title));

    final picked = await showModalBottomSheet<RentalExpenseLocation>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.7;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Destino da despesa',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sortedBlocks.length} bloco(s)/torre(s) · ${sortedProperties.length} imóvel(is)',
                      style: const TextStyle(fontSize: 12, color: ClayTokens.textMuted),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _locationSectionHeader('Condomínio'),
                    _locationTile(
                      ctx,
                      const RentalExpenseLocation.condominium(),
                      selected,
                    ),
                    _locationSectionHeader('Blocos / Torres'),
                    if (sortedBlocks.isEmpty)
                      const _LocationEmptyHint('Nenhum bloco ou torre cadastrado neste condomínio.')
                    else
                      ...sortedBlocks.map(
                        (b) => _locationTile(
                          ctx,
                          RentalExpenseLocation.block(id: b.id, name: b.name),
                          selected,
                        ),
                      ),
                    _locationSectionHeader('Imóveis'),
                    if (sortedProperties.isEmpty)
                      const _LocationEmptyHint('Nenhum imóvel cadastrado neste condomínio.')
                    else
                      ...sortedProperties.map(
                        (p) => _locationTile(
                          ctx,
                          RentalExpenseLocation.property(id: p.id, title: p.title),
                          selected,
                        ),
                      ),
                    if (selected.kind != RentalExpenseLocationKind.condominium &&
                        !_isInLists(selected, sortedBlocks, sortedProperties))
                      ...[
                        _locationSectionHeader('Selecionado'),
                        _locationTile(ctx, selected, selected),
                      ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) onChanged(picked);
  }

  bool _isInLists(
    RentalExpenseLocation selected,
    List<CondominiumBlock> blocks,
    List<RentalProperty> properties,
  ) {
    return switch (selected.kind) {
      RentalExpenseLocationKind.condominium => true,
      RentalExpenseLocationKind.block =>
        blocks.any((b) => b.id == selected.referenceId),
      RentalExpenseLocationKind.property =>
        properties.any((p) => p.id == selected.referenceId),
    };
  }

  Widget _locationSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ClayTokens.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _locationTile(
    BuildContext context,
    RentalExpenseLocation option,
    RentalExpenseLocation selected,
  ) {
    final isSelected = option == selected;
    return ListTile(
      dense: true,
      selected: isSelected,
      title: Text(
        option.dropdownLabel,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: ClayTokens.accent, size: 20)
          : null,
      onTap: () => Navigator.pop(context, option),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (condominiumId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          'Selecione o condomínio',
          style: TextStyle(color: ClayTokens.textMuted, fontSize: 11),
        ),
      );
    }

    final propertiesAsync = ref.watch(rentalPropertiesByCondominiumProvider(condominiumId!));
    final blocksAsync = ref.watch(condominiumBlocksProvider(condominiumId!));

    if (propertiesAsync.isLoading || blocksAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (propertiesAsync.hasError || blocksAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Material(
          color: ClayTokens.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
          child: InkWell(
            onTap: () {
              ref.invalidate(rentalPropertiesByCondominiumProvider(condominiumId!));
              ref.invalidate(condominiumBlocksProvider(condominiumId!));
            },
            borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text(
                'Erro ao carregar · toque para tentar',
                style: TextStyle(color: ClayTokens.error, fontSize: 11),
              ),
            ),
          ),
        ),
      );
    }

    final properties = propertiesAsync.value ?? const <RentalProperty>[];
    final blocks = blocksAsync.value ?? const <CondominiumBlock>[];
    final resolved = _resolveValue(_buildOptions(blocks, properties, value), value);
    final summary = '${blocks.length} bloco(s) · ${properties.length} imóvel(is)';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => _openPicker(context, blocks, properties, resolved) : null,
          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolved.dropdownLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: enabled ? ClayTokens.textPrimary : ClayTokens.textSecondary,
                        ),
                      ),
                      if (enabled)
                        Text(
                          summary,
                          style: const TextStyle(fontSize: 10, color: ClayTokens.textMuted),
                        ),
                    ],
                  ),
                ),
                if (enabled)
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: ClayTokens.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationEmptyHint extends StatelessWidget {
  const _LocationEmptyHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: ClayTokens.textMuted, fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _EntryTypeDropdown extends StatelessWidget {
  const _EntryTypeDropdown({
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final bool enabled;
  final RentalExpenseEntryType value;
  final ValueChanged<RentalExpenseEntryType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _SpreadsheetDropdown<RentalExpenseEntryType>(
        enabled: enabled,
        value: value,
        items: RentalExpenseEntryType.values,
        itemLabel: (t) => switch (t) {
          RentalExpenseEntryType.fixedBill => 'Fixa',
          RentalExpenseEntryType.service => 'Serviço',
          RentalExpenseEntryType.material => 'Material',
        },
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _CategoryCell extends ConsumerWidget {
  const _CategoryCell({
    required this.enabled,
    required this.row,
    required this.onPatch,
  });

  final bool enabled;
  final _ExpenseRowData row;
  final ValueChanged<_ExpenseRowData Function(_ExpenseRowData current)> onPatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (row.entryType) {
      RentalExpenseEntryType.fixedBill => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _SpreadsheetDropdown<CondominiumBillType>(
            enabled: enabled,
            value: row.billType,
            items: CondominiumBillType.values,
            itemLabel: (t) => t.label,
            onChanged: (v) {
              if (v == null) return;
              onPatch(
                (current) => current.copyWith(
                  billType: v,
                  isRecurringTemplate: v.typicallyRecurring || current.isRecurringTemplate,
                ),
              );
            },
          ),
        ),
      RentalExpenseEntryType.service => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _SpreadsheetDropdown<ServiceType>(
            enabled: enabled,
            value: row.serviceType,
            items: ServiceType.values,
            itemLabel: (t) => t.label,
            onChanged: (v) {
              if (v != null) onPatch((current) => current.copyWith(serviceType: v));
            },
          ),
        ),
      RentalExpenseEntryType.material => _MaterialCategoryDropdown(
          enabled: enabled,
          condominiumId: row.condominium?.id,
          categoryId: row.materialCategoryId,
          fallbackLabel: row.materialCategoryName,
          onChanged: (id, name) => onPatch(
            (current) => current.copyWith(
              materialCategoryId: id,
              materialCategoryName: name,
            ),
          ),
        ),
    };
  }
}

class _MaterialCategoryDropdown extends ConsumerWidget {
  const _MaterialCategoryDropdown({
    required this.enabled,
    required this.condominiumId,
    required this.categoryId,
    required this.fallbackLabel,
    required this.onChanged,
  });

  final bool enabled;
  final String? condominiumId;
  final String? categoryId;
  final String? fallbackLabel;
  final void Function(String? id, String? name) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (condominiumId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text('—', style: TextStyle(color: ClayTokens.textMuted, fontSize: 12)),
      );
    }

    final categoriesAsync = ref.watch(materialCategoriesProvider(condominiumId!));
    return categoriesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (categories) {
        mat.MaterialCategory? selected;
        for (final c in categories) {
          if (c.id == categoryId) {
            selected = c;
            break;
          }
        }
        if (selected == null && categoryId != null && fallbackLabel != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(fallbackLabel!, style: const TextStyle(fontSize: 12)),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _SpreadsheetDropdown<mat.MaterialCategory>(
            enabled: enabled,
            value: selected,
            items: categories,
            itemLabel: (c) => c.name,
            onChanged: (c) => onChanged(c?.id, c?.name),
            hint: 'Categoria',
          ),
        );
      },
    );
  }
}

class _TextCell extends StatefulWidget {
  const _TextCell({
    required this.enabled,
    required this.value,
    required this.hint,
    required this.onCommit,
  });

  final bool enabled;
  final String value;
  final String hint;
  final ValueChanged<String> onCommit;

  @override
  State<_TextCell> createState() => _TextCellState();
}

class _TextCellState extends State<_TextCell> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      widget.onCommit(_controller.text);
    }
  }

  @override
  void didUpdateWidget(covariant _TextCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && !_focusNode.hasFocus) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(widget.value, style: const TextStyle(fontSize: 12)),
      );
    }
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hint,
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      style: const TextStyle(fontSize: 12),
      textInputAction: TextInputAction.done,
      onEditingComplete: () {
        widget.onCommit(_controller.text);
        _focusNode.unfocus();
      },
      onSubmitted: widget.onCommit,
      onTapOutside: (_) {
        widget.onCommit(_controller.text);
        _focusNode.unfocus();
      },
    );
  }
}

class _AmountCell extends StatefulWidget {
  const _AmountCell({
    required this.enabled,
    required this.value,
    required this.onCommit,
  });

  final bool enabled;
  final double value;
  final ValueChanged<double> onCommit;

  @override
  State<_AmountCell> createState() => _AmountCellState();
}

class _AmountCellState extends State<_AmountCell> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value > 0 ? widget.value.toStringAsFixed(2) : '',
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      widget.onCommit(_parse(_controller.text));
    }
  }

  @override
  void didUpdateWidget(covariant _AmountCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.value > 0 ? widget.value.toStringAsFixed(2) : '';
    if (_controller.text != next && !_focusNode.hasFocus) _controller.text = next;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _commit() => widget.onCommit(_parse(_controller.text));

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          widget.value > 0 ? _spreadsheetCurrency.format(widget.value) : '—',
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      decoration: const InputDecoration(
        hintText: '0,00',
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      textInputAction: TextInputAction.done,
      onEditingComplete: () {
        _commit();
        _focusNode.unfocus();
      },
      onSubmitted: (_) => _commit(),
      onTapOutside: (_) {
        _commit();
        _focusNode.unfocus();
      },
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.enabled,
    required this.date,
    required this.onTap,
    this.placeholder = 'dd/mm/aaaa',
  });

  final bool enabled;
  final DateTime? date;
  final VoidCallback onTap;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final label = date != null
        ? _spreadsheetDateFmt.format(date!)
        : placeholder;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: date != null ? ClayTokens.textPrimary : ClayTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

class _RecurrenceCell extends StatelessWidget {
  const _RecurrenceCell({
    required this.enabled,
    required this.isTemplate,
    required this.day,
    required this.onTemplateChanged,
    required this.onDayChanged,
  });

  final bool enabled;
  final bool isTemplate;
  final int day;
  final ValueChanged<bool> onTemplateChanged;
  final ValueChanged<int> onDayChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Checkbox(
              value: isTemplate,
              onChanged: enabled ? (v) => onTemplateChanged(v ?? false) : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          if (isTemplate)
            Expanded(
              child: _SpreadsheetDropdown<int>(
                enabled: enabled,
                value: day,
                items: List.generate(28, (i) => i + 1),
                itemLabel: (d) => 'Dia $d',
                onChanged: (v) {
                  if (v != null) onDayChanged(v);
                },
              ),
            )
          else
            const Expanded(
              child: Text('—', style: TextStyle(fontSize: 11, color: ClayTokens.textMuted)),
            ),
        ],
      ),
    );
  }
}

/// Barra horizontal fixa no rodapé — sempre visível quando a tabela é mais larga que a tela.
class _SpreadsheetHorizontalScrollbar extends StatefulWidget {
  const _SpreadsheetHorizontalScrollbar({
    required this.controller,
    required this.contentWidth,
    required this.viewportWidth,
  });

  final ScrollController controller;
  final double contentWidth;
  final double viewportWidth;

  @override
  State<_SpreadsheetHorizontalScrollbar> createState() => _SpreadsheetHorizontalScrollbarState();
}

class _SpreadsheetHorizontalScrollbarState extends State<_SpreadsheetHorizontalScrollbar> {
  static const _trackHeight = 14.0;
  static const _minThumbWidth = 40.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _SpreadsheetHorizontalScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() => setState(() {});

  void _jumpToThumbCenter(double localX, double trackWidth, double thumbWidth, double maxScroll) {
    if (!widget.controller.hasClients || maxScroll <= 0) return;
    final usable = trackWidth - thumbWidth;
    if (usable <= 0) return;
    final target = ((localX - thumbWidth / 2) / usable * maxScroll).clamp(0.0, maxScroll);
    widget.controller.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final maxScroll = widget.controller.hasClients ? widget.controller.position.maxScrollExtent : 0.0;
    final offset = widget.controller.hasClients ? widget.controller.offset : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final thumbWidth = (widget.viewportWidth / widget.contentWidth * trackWidth)
            .clamp(_minThumbWidth, trackWidth);
        final usable = (trackWidth - thumbWidth).clamp(0.0, trackWidth);
        final thumbLeft = maxScroll > 0 && usable > 0 ? (offset / maxScroll) * usable : 0.0;

        return Semantics(
          label: 'Rolagem horizontal da planilha',
          slider: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              if (!widget.controller.hasClients || maxScroll <= 0 || usable <= 0) return;
              final delta = details.delta.dx / usable * maxScroll;
              widget.controller.jumpTo((widget.controller.offset + delta).clamp(0.0, maxScroll));
            },
            onTapDown: (details) => _jumpToThumbCenter(details.localPosition.dx, trackWidth, thumbWidth, maxScroll),
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Container(
                height: _trackHeight,
                decoration: BoxDecoration(
                  color: ClayTokens.shadowDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                  border: Border.all(color: ClayTokens.shadowDark.withValues(alpha: 0.2)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: thumbLeft,
                      width: thumbWidth,
                      top: 2,
                      bottom: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: ClayTokens.accent.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                          border: Border.all(color: ClayTokens.accent.withValues(alpha: 0.7)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
