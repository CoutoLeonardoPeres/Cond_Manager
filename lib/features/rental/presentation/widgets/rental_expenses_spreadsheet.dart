import 'dart:math' as math;

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
import 'package:cond_manager/features/rental/presentation/widgets/rental_expense_attachments_editor.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_expense_draft_sheet.dart';
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

/// Espaçamento vertical e tipografia das linhas da tabela (desktop).
class SpreadsheetRowMetrics {
  const SpreadsheetRowMetrics({
    required this.padV,
    required this.padVSm,
    required this.cellOuterV,
    required this.emptyPadV,
    required this.fontSize,
    required this.fontSizeSm,
    required this.headerFontSize,
    required this.actionIconSize,
    required this.actionBtn,
    required this.actionSpinner,
    required this.spinner,
    required this.checkbox,
    required this.dropdownMenuItemHeight,
    this.rowHeight,
  });

  final double padV;
  final double padVSm;
  final double cellOuterV;
  final double emptyPadV;
  final double fontSize;
  final double fontSizeSm;
  final double headerFontSize;
  final double actionIconSize;
  final double actionBtn;
  final double actionSpinner;
  final double spinner;
  final double checkbox;
  final double dropdownMenuItemHeight;
  /// Altura fixa da linha (mobile) — conteúdo centralizado verticalmente.
  final double? rowHeight;

  double get fieldPadV => rowHeight != null ? 0 : padV;

  static const desktop = SpreadsheetRowMetrics(
    padV: 4.5,
    padVSm: 2.5,
    cellOuterV: 0.6,
    emptyPadV: 13.0,
    fontSize: 11.0,
    fontSizeSm: 10.0,
    headerFontSize: 10.0,
    actionIconSize: 14.0,
    actionBtn: 21.0,
    actionSpinner: 13.0,
    spinner: 10.0,
    checkbox: 16.0,
    dropdownMenuItemHeight: 34.0,
  );

  static const mobile = SpreadsheetRowMetrics(
    padV: 0.7,
    padVSm: 0.25,
    cellOuterV: 0.0,
    emptyPadV: 5.0,
    fontSize: 10.0,
    fontSizeSm: 9.0,
    headerFontSize: 9.0,
    actionIconSize: 16.0,
    actionBtn: 14.0,
    actionSpinner: 6.0,
    spinner: 5.0,
    checkbox: 8.0,
    dropdownMenuItemHeight: 18.0,
    rowHeight: 17.0,
  );

  static SpreadsheetRowMetrics resolve(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 640 ? mobile : desktop;
  }
}

class _SpreadsheetRowMetricsScope extends InheritedWidget {
  const _SpreadsheetRowMetricsScope({required this.metrics, required super.child});

  final SpreadsheetRowMetrics metrics;

  static SpreadsheetRowMetrics of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_SpreadsheetRowMetricsScope>()
            ?.metrics ??
        SpreadsheetRowMetrics.desktop;
  }

  @override
  bool updateShouldNotify(_SpreadsheetRowMetricsScope oldWidget) =>
      oldWidget.metrics != metrics;
}

extension _SpreadsheetRowMetricsContext on BuildContext {
  SpreadsheetRowMetrics get _sheetMetrics => _SpreadsheetRowMetricsScope.of(this);
}

/// Popup das listas dropdown (fonte +30%, cards e largura -30% vs menu padrão).
const _dropdownMenuFontSize = 10.0;
const _dropdownMenuMaxHeight = 137.0;
const _dropdownMenuItemPadH = 8.0;
const _dropdownIconSize = 8.0;
const _dropdownRadius = 8.0;

/// Planilha editável para despesas de locação (estilo Excel).
class RentalExpensesSpreadsheet extends ConsumerStatefulWidget {
  const RentalExpensesSpreadsheet({
    super.key,
    required this.expenses,
    required this.condominiums,
    required this.filter,
    required this.canEdit,
    this.showAddRowButton = true,
  });

  final List<FinancialRecord> expenses;
  final List<Condominium> condominiums;
  final RentalExpenseListFilter filter;
  final bool canEdit;
  final bool showAddRowButton;

  @override
  ConsumerState<RentalExpensesSpreadsheet> createState() => RentalExpensesSpreadsheetState();
}

class RentalExpensesSpreadsheetState extends ConsumerState<RentalExpensesSpreadsheet> {
  static const _tableWidth = 1374.0;

  static final _tableBorder = TableBorder.all(
    color: ClayTokens.shadowDark.withValues(alpha: 0.35),
    width: 1,
  );

  final List<_ExpenseRowData> _rows = [];
  int _draftCounter = 0;
  int? _focusedRowIndex;
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
        ..addAll(drafts)
        ..addAll(merged);
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

  void addDraftRow() => _addDraftRow();

  Future<void> openMobileDraftSheet() => showRentalExpenseDraftSheet(
        context: context,
        ref: ref,
        condominiums: widget.condominiums,
        filter: widget.filter,
      );

  void _setFocusedRow(int index) {
    if (_focusedRowIndex != index) {
      setState(() => _focusedRowIndex = index);
    }
  }

  bool _isRowEditing(_ExpenseRowData row, int index) =>
      row.isDraft || row.isDirty || _focusedRowIndex == index;

  BoxDecoration? _rowDecoration(_ExpenseRowData row, int index) {
    if (_isRowEditing(row, index)) {
      return BoxDecoration(
        color: ClayTokens.accentSurface.withValues(alpha: 0.75),
        border: const Border(
          left: BorderSide(color: ClayTokens.accent, width: 4),
        ),
      );
    }
    if (row.isRecurringTemplate && !row.isDraft) {
      return BoxDecoration(
        color: ClayTokens.tertiary.withValues(alpha: 0.04),
      );
    }
    return null;
  }

  void _addDraftRow() {
    setState(() {
      _rows.insert(
        0,
        _ExpenseRowData.draft(
          key: 'draft_${_draftCounter++}',
          filter: widget.filter,
          condominiums: widget.condominiums,
        ),
      );
      _focusedRowIndex = 0;
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
          setState(() {
            _rows.removeAt(index);
            if (_focusedRowIndex == index) {
              _focusedRowIndex = null;
            } else if (_focusedRowIndex != null && _focusedRowIndex! > index) {
              _focusedRowIndex = _focusedRowIndex! - 1;
            }
          });
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
          if (_focusedRowIndex == index) {
            _focusedRowIndex = null;
          }
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
      setState(() {
        _rows.removeAt(index);
        if (_focusedRowIndex == index) {
          _focusedRowIndex = null;
        } else if (_focusedRowIndex != null && _focusedRowIndex! > index) {
          _focusedRowIndex = _focusedRowIndex! - 1;
        }
      });
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
    final m = context._sheetMetrics;
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: m.fieldPadV),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: m.headerFontSize,
          color: ClayTokens.textSecondary,
        ),
      ),
    );
    if (m.rowHeight == null) return content;
    return SizedBox(
      height: m.rowHeight,
      child: Center(child: content),
    );
  }

  Widget _cellPadding({required Widget child, bool highlight = false}) {
    final m = context._sheetMetrics;
    final cell = Container(
      color: highlight ? ClayTokens.accent.withValues(alpha: 0.12) : null,
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: m.cellOuterV),
      alignment: Alignment.center,
      child: child,
    );
    if (m.rowHeight == null) return cell;
    return SizedBox(height: m.rowHeight, child: cell);
  }

  TableRow _buildDataRow(int index, _ExpenseRowData row) {
    final editable = widget.canEdit && !row.isSaving;
    final highlight = _isRowEditing(row, index);
    void activateRow() => _setFocusedRow(index);

    return TableRow(
      decoration: _rowDecoration(row, index),
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
            onActivate: activateRow,
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
            onActivate: activateRow,
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
            onActivate: activateRow,
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
            onActivate: activateRow,
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
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
                  child: Text('—', style: TextStyle(fontSize: context._sheetMetrics.fontSize, color: ClayTokens.textMuted)),
                ),
        ),
        _cellPadding(
          highlight: highlight,
          child: Center(
            child: row.isSaving
                ? SizedBox(
                    width: context._sheetMetrics.spinner,
                    height: context._sheetMetrics.spinner,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : SizedBox(
                    width: context._sheetMetrics.checkbox,
                    height: context._sheetMetrics.checkbox,
                    child: Checkbox(
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
        ),
        _cellPadding(
          highlight: highlight,
          child: Center(
            child: row.isSaving
                ? SizedBox(
                    width: context._sheetMetrics.actionSpinner,
                    height: context._sheetMetrics.actionSpinner,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (editable && (row.isDraft || row.isDirty))
                        IconButton(
                          icon: Icon(Icons.save_rounded, size: context._sheetMetrics.actionIconSize),
                          tooltip: 'Salvar linha',
                          onPressed: () => _saveRow(
                            index,
                            row: _rows[index],
                            notifyValidation: true,
                            quiet: false,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: context._sheetMetrics.actionBtn,
                            minHeight: context._sheetMetrics.actionBtn,
                          ),
                        ),
                      if (row.isDraft)
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: context._sheetMetrics.actionIconSize),
                          tooltip: 'Remover rascunho',
                          onPressed: editable ? () => setState(() => _rows.removeAt(index)) : null,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: context._sheetMetrics.actionBtn,
                            minHeight: context._sheetMetrics.actionBtn,
                          ),
                        )
                      else ...[
                        if (row.expenseId != null)
                          IconButton(
                            icon: Icon(
                              Icons.receipt_long_rounded,
                              size: context._sheetMetrics.actionIconSize,
                            ),
                            tooltip: 'NF / Recibo',
                            onPressed: () => showRentalExpenseAttachmentsSheet(
                              context: context,
                              ref: ref,
                              expenseId: row.expenseId!,
                              expenseLabel: row.description,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: context._sheetMetrics.actionBtn,
                              minHeight: context._sheetMetrics.actionBtn,
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, size: context._sheetMetrics.actionIconSize),
                          tooltip: 'Excluir despesa',
                          onPressed: editable ? () => _deleteRow(index) : null,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: context._sheetMetrics.actionBtn,
                            minHeight: context._sheetMetrics.actionBtn,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.open_in_new_rounded, size: context._sheetMetrics.actionIconSize),
                          tooltip: 'Detalhes / rateio',
                          onPressed: () => context.go('/rental/expenses/${row.expenseId}'),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: context._sheetMetrics.actionBtn,
                            minHeight: context._sheetMetrics.actionBtn,
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
    final metrics = SpreadsheetRowMetrics.resolve(context);
    final rowCountLabel = metrics.rowHeight != null
        ? '${_rows.length} ${_rows.length == 1 ? 'linha' : 'linhas'}'
        : '${_rows.length} linha(s) · Enter ou sair do campo para salvar · use o ícone de salvar';
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
          10: FixedColumnWidth(174),
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
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: context._sheetMetrics.emptyPadV),
                        child: Text(
                          widget.canEdit
                              ? 'Nenhuma despesa. Clique em + Adicionar linha.'
                              : 'Nenhuma despesa cadastrada.',
                          style: TextStyle(color: ClayTokens.textMuted, fontSize: 13),
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

    return _SpreadsheetRowMetricsScope(
      metrics: metrics,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(metrics == SpreadsheetRowMetrics.mobile ? 8 : 20, 0, metrics == SpreadsheetRowMetrics.mobile ? 8 : 20, 0),
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
                        SizedBox(height: 6),
                        _SpreadsheetHorizontalScrollbar(
                          controller: _horizontalScrollController,
                          contentWidth: _tableWidth,
                          viewportWidth: viewportWidth,
                        ),
                      ],
                      SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.canEdit && widget.showAddRowButton)
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Material(
                  color: ClayTokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                  child: InkWell(
                    onTap: _addDraftRow,
                    borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                    child: Padding(
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
                SizedBox(width: 12),
                Text(
                  rowCountLabel,
                  style: TextStyle(color: ClayTokens.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        if (widget.canEdit && !widget.showAddRowButton)
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              rowCountLabel,
              style: TextStyle(color: ClayTokens.textMuted, fontSize: 12),
            ),
          ),
      ],
    ),
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

class _DropdownSelection<T> {
  const _DropdownSelection(this.value);
  final T? value;
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

  double _menuWidthForItems(BuildContext context, RenderBox anchor, Offset origin) {
    const menuPad = _dropdownMenuItemPadH * 2 + 12;
    final textStyle = TextStyle(
      fontSize: _dropdownMenuFontSize,
      fontWeight: FontWeight.w700,
    );
    final textDirection = Directionality.of(context);

    var maxTextWidth = 0.0;
    for (final item in items) {
      final painter = TextPainter(
        text: TextSpan(text: itemLabel(item), style: textStyle),
        maxLines: 1,
        textDirection: textDirection,
      )..layout();
      maxTextWidth = math.max(maxTextWidth, painter.width);
    }

    final overlaySize = Overlay.of(context).context.size ?? MediaQuery.sizeOf(context);
    final maxAvailable = overlaySize.width - origin.dx - 8;

    return math.max(anchor.size.width, maxTextWidth + menuPad).clamp(
          anchor.size.width,
          math.max(anchor.size.width, maxAvailable),
        );
  }

  double _menuLeft(double originX, double menuWidth, BuildContext context) {
    final overlayWidth = Overlay.of(context).context.size?.width ?? MediaQuery.sizeOf(context).width;
    if (originX + menuWidth <= overlayWidth - 8) return originX;
    return math.max(8, overlayWidth - menuWidth - 8);
  }

  Future<void> _openMenu(BuildContext context, RenderBox anchor) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final origin = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    final menuWidth = _menuWidthForItems(context, anchor, origin);
    final menuLeft = _menuLeft(origin.dx, menuWidth, context);
    final resolved = _resolveValue();

    final picked = await showGeneralDialog<_DropdownSelection<T>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar lista',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, _) {
        return Stack(
          children: [
            Positioned(
              left: menuLeft,
              top: origin.dy + anchor.size.height + 2,
              width: menuWidth,
              child: Material(
                elevation: 8,
                color: ClayTokens.surfaceRaised,
                borderRadius: BorderRadius.circular(_dropdownRadius),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: _dropdownMenuMaxHeight),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: items.map((item) {
                      final selected = item == resolved;
                      return InkWell(
                        onTap: () => Navigator.of(dialogContext).pop(_DropdownSelection(item)),
                        child: Container(
                          height: context._sheetMetrics.dropdownMenuItemHeight,
                          padding: EdgeInsets.symmetric(horizontal: _dropdownMenuItemPadH),
                          alignment: Alignment.centerLeft,
                          color: selected
                              ? ClayTokens.accentSurface.withValues(alpha: 0.65)
                              : null,
                          child: Text(
                            itemLabel(item),
                            style: TextStyle(
                              fontSize: _dropdownMenuFontSize,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: ClayTokens.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (picked != null) onChanged(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveValue();
    final label = resolved != null ? itemLabel(resolved) : (hint ?? '—');

    return Builder(
      builder: (fieldContext) {
        return InkWell(
          onTap: !enabled
              ? null
              : () {
                  final box = fieldContext.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  _openMenu(fieldContext, box);
                },
          borderRadius: BorderRadius.circular(ClayTokens.radiusXs),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context._sheetMetrics.fontSize, fontWeight: FontWeight.w600, color: resolved != null ? ClayTokens.textPrimary : ClayTokens.textMuted),
                  ),
                ),
                if (enabled)
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: _dropdownIconSize,
                    color: ClayTokens.muted,
                  ),
              ],
            ),
          ),
        );
      },
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
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
        child: Text(
          resolved?.name ?? fallbackName ?? '—',
          style: TextStyle(fontSize: context._sheetMetrics.fontSize, fontWeight: FontWeight.w600),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
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
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.49;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14, 2, 14, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Destino da despesa',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${sortedBlocks.length} bloco(s)/torre(s) · ${sortedProperties.length} imóvel(is)',
                      style: TextStyle(fontSize: 8, color: ClayTokens.textMuted),
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
                        !_isInLists(selected, sortedBlocks, sortedProperties)) ...[
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
      padding: EdgeInsets.fromLTRB(14, 8, 14, 3),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: ClayTokens.textSecondary,
          letterSpacing: 0.2,
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
      visualDensity: const VisualDensity(horizontal: -2, vertical: -4),
      minVerticalPadding: 0,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      selected: isSelected,
      title: Text(
        option.dropdownLabel,
        style: TextStyle(
          fontSize: 9,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: ClayTokens.accent, size: 14)
          : null,
      onTap: () => Navigator.pop(context, option),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (condominiumId == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
        child: Text(
          'Selecione o condomínio',
          style: TextStyle(fontSize: context._sheetMetrics.fontSize, color: ClayTokens.textMuted),
        ),
      );
    }

    final propertiesAsync = ref.watch(rentalPropertiesByCondominiumProvider(condominiumId!));
    final blocksAsync = ref.watch(condominiumBlocksProvider(condominiumId!));

    if (propertiesAsync.isLoading || blocksAsync.isLoading) {
      return Padding(
        padding: EdgeInsets.all(4),
        child: SizedBox(width: context._sheetMetrics.spinner, height: context._sheetMetrics.spinner, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (propertiesAsync.hasError || blocksAsync.hasError) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: context._sheetMetrics.padVSm),
        child: Material(
          color: ClayTokens.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
          child: InkWell(
            onTap: () {
              ref.invalidate(rentalPropertiesByCondominiumProvider(condominiumId!));
              ref.invalidate(condominiumBlocksProvider(condominiumId!));
            },
            borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
              child: Text(
                'Erro ao carregar · toque para tentar',
                style: TextStyle(fontSize: context._sheetMetrics.fontSize, color: ClayTokens.error),
              ),
            ),
          ),
        ),
      );
    }

    final properties = propertiesAsync.value ?? const <RentalProperty>[];
    final blocks = blocksAsync.value ?? const <CondominiumBlock>[];
    final resolved = _resolveValue(_buildOptions(blocks, properties, value), value);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => _openPicker(context, blocks, properties, resolved) : null,
          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: context._sheetMetrics.padVSm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    resolved.dropdownLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context._sheetMetrics.fontSize, fontWeight: FontWeight.w600, color: enabled ? ClayTokens.textPrimary : ClayTokens.textSecondary),
                  ),
                ),
                if (enabled)
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: _dropdownIconSize,
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
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Text(
        message,
        style: TextStyle(fontSize: 8, color: ClayTokens.textMuted, fontStyle: FontStyle.italic),
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
      padding: EdgeInsets.symmetric(horizontal: 4),
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
          padding: EdgeInsets.symmetric(horizontal: 4),
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
          padding: EdgeInsets.symmetric(horizontal: 4),
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
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
        child: Text('—', style: TextStyle(fontSize: context._sheetMetrics.fontSize, color: ClayTokens.textMuted)),
      );
    }

    final categoriesAsync = ref.watch(materialCategoriesProvider(condominiumId!));
    return categoriesAsync.when(
      loading: () => Padding(
        padding: EdgeInsets.all(4),
        child: SizedBox(width: context._sheetMetrics.spinner, height: context._sheetMetrics.spinner, child: CircularProgressIndicator(strokeWidth: 2)),
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
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
            child: Text(fallbackLabel!, style: TextStyle(fontSize: context._sheetMetrics.fontSize)),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
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
    this.onActivate,
  });

  final bool enabled;
  final String value;
  final String hint;
  final ValueChanged<String> onCommit;
  final VoidCallback? onActivate;

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
    if (_focusNode.hasFocus) {
      widget.onActivate?.call();
    } else {
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

  bool _isMobile(BuildContext context) => context._sheetMetrics.rowHeight != null;

  Future<void> _openEditSheet() async {
    widget.onActivate?.call();
    final sheetController = TextEditingController(text: _controller.text);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: ClayTokens.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ClayTokens.radiusLg)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Descrição',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ClayTextField(
                  controller: sheetController,
                  hint: widget.hint,
                  maxLines: 4,
                  pill: false,
                ),
                const SizedBox(height: 16),
                ClayButton(
                  label: 'Salvar',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(sheetContext).pop(sheetController.text),
                ),
              ],
            ),
          ),
        );
      },
    );
    sheetController.dispose();
    if (!mounted || result == null) return;
    _controller.text = result;
    widget.onCommit(result);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
        child: Text(widget.value, style: TextStyle(fontSize: context._sheetMetrics.fontSize)),
      );
    }
    if (_isMobile(context)) {
      final isPlaceholder = widget.value.isEmpty;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openEditSheet,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
            child: Text(
              isPlaceholder ? widget.hint : widget.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context._sheetMetrics.fontSize,
                color: isPlaceholder ? ClayTokens.textMuted : ClayTokens.textPrimary,
              ),
            ),
          ),
        ),
      );
    }
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hint,
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
      ),
      style: TextStyle(fontSize: context._sheetMetrics.fontSize),
      textInputAction: TextInputAction.done,
      onEditingComplete: () {
        widget.onCommit(_controller.text);
        _focusNode.unfocus();
      },
      onSubmitted: widget.onCommit,
      onTap: () => widget.onActivate?.call(),
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
    this.onActivate,
  });

  final bool enabled;
  final double value;
  final ValueChanged<double> onCommit;
  final VoidCallback? onActivate;

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
    if (_focusNode.hasFocus) {
      widget.onActivate?.call();
    } else {
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

  bool _isMobile(BuildContext context) => context._sheetMetrics.rowHeight != null;

  Future<void> _openEditSheet() async {
    widget.onActivate?.call();
    final sheetController = TextEditingController(text: _controller.text);
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: ClayTokens.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ClayTokens.radiusLg)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Valor',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ClayTextField(
                  controller: sheetController,
                  hint: '0,00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  pill: false,
                ),
                const SizedBox(height: 16),
                ClayButton(
                  label: 'Salvar',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(sheetContext).pop(_parse(sheetController.text)),
                ),
              ],
            ),
          ),
        );
      },
    );
    sheetController.dispose();
    if (!mounted || result == null) return;
    final next = result > 0 ? result.toStringAsFixed(2) : '';
    _controller.text = next;
    widget.onCommit(result);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
        child: Text(
          widget.value > 0 ? _spreadsheetCurrency.format(widget.value) : '—',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: context._sheetMetrics.fontSize, fontWeight: FontWeight.w600),
        ),
      );
    }
    if (_isMobile(context)) {
      final isPlaceholder = widget.value <= 0;
      final label = isPlaceholder
          ? '0,00'
          : _spreadsheetCurrency.format(widget.value);
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openEditSheet,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
            child: Text(
              label,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context._sheetMetrics.fontSize,
                fontWeight: FontWeight.w600,
                color: isPlaceholder ? ClayTokens.textMuted : ClayTokens.textPrimary,
              ),
            ),
          ),
        ),
      );
    }
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      decoration: InputDecoration(
        hintText: '0,00',
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
      ),
      style: TextStyle(fontSize: context._sheetMetrics.fontSize, fontWeight: FontWeight.w600),
      textInputAction: TextInputAction.done,
      onEditingComplete: () {
        _commit();
        _focusNode.unfocus();
      },
      onSubmitted: (_) => _commit(),
      onTap: () => widget.onActivate?.call(),
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
    this.onActivate,
  });

  final bool enabled;
  final DateTime? date;
  final VoidCallback onTap;
  final String placeholder;
  final VoidCallback? onActivate;

  @override
  Widget build(BuildContext context) {
    final label = date != null
        ? _spreadsheetDateFmt.format(date!)
        : placeholder;
    return InkWell(
      onTap: enabled
          ? () {
              onActivate?.call();
              onTap();
            }
          : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: context._sheetMetrics.fieldPadV),
        child: Text(
          label,
          style: TextStyle(fontSize: context._sheetMetrics.fontSize, color: date != null ? ClayTokens.textPrimary : ClayTokens.textMuted),
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
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Checkbox(
            value: isTemplate,
            onChanged: enabled ? (v) => onTemplateChanged(v ?? false) : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          ),
          const SizedBox(width: 6),
          if (isTemplate)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 2),
                child: _SpreadsheetDropdown<int>(
                  enabled: enabled,
                  value: day,
                  items: List.generate(28, (i) => i + 1),
                  itemLabel: (d) => 'Dia $d',
                  onChanged: (v) {
                    if (v != null) onDayChanged(v);
                  },
                ),
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  '—',
                  style: TextStyle(fontSize: context._sheetMetrics.fontSize, color: ClayTokens.textMuted),
                ),
              ),
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
