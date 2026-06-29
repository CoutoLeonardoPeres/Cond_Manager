import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_expense_mapping.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_expense_month_adjust.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RentalExpenseMonthAdjustSheet extends ConsumerStatefulWidget {
  const RentalExpenseMonthAdjustSheet({
    super.key,
    required this.expenses,
    required this.month,
  });

  final List<FinancialRecord> expenses;
  final DateTime month;

  static Future<void> show(
    BuildContext context, {
    required List<FinancialRecord> expenses,
    required DateTime month,
  }) {
    final adjustable = rentalExpensesAdjustableForMonth(expenses, month);
    if (adjustable.isEmpty) {
      return showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nada para ajustar'),
          content: Text(
            'Não há contas fixas lançadas em ${DateFormat('MM/yyyy').format(month)}. '
            'Use “Gerar fixas do mês” primeiro.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
          child: RentalExpenseMonthAdjustSheet(expenses: expenses, month: month),
        ),
      ),
    );
  }

  @override
  ConsumerState<RentalExpenseMonthAdjustSheet> createState() =>
      _RentalExpenseMonthAdjustSheetState();
}

class _RentalExpenseMonthAdjustSheetState extends ConsumerState<RentalExpenseMonthAdjustSheet> {
  final _amountControllers = <String, TextEditingController>{};
  final _paidFlags = <String, bool>{};
  bool _syncTemplates = true;
  bool _loading = false;
  String? _error;

  List<FinancialRecord> get _items =>
      rentalExpensesAdjustableForMonth(widget.expenses, widget.month);

  @override
  void initState() {
    super.initState();
    for (final e in _items) {
      _amountControllers[e.id] = TextEditingController(text: e.amount.toStringAsFixed(2));
      _paidFlags[e.id] = e.isPaid;
    }
  }

  @override
  void dispose() {
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(financialRepositoryProvider);
    var updated = 0;

    for (final expense in _items) {
      final amount = _parse(_amountControllers[expense.id]!.text);
      if (amount <= 0) {
        setState(() {
          _loading = false;
          _error = 'Valor inválido em “${expense.description}”.';
        });
        return;
      }

      final markPaid = _paidFlags[expense.id] ?? false;
      final input = FinancialRecordUpdateInput(
        recordType: expense.recordType,
        category: expense.category,
        description: expense.description,
        amount: amount,
        taxAmount: expense.taxAmount,
        referenceDate: expense.referenceDate,
        dueDate: expense.dueDate,
        paidAt: markPaid ? (expense.paidAt ?? DateTime.now()) : null,
        notes: expense.notes,
        unitId: expense.unitId,
        rentalExpenseEntryType: expense.rentalExpenseEntryType,
        condominiumBillType: expense.condominiumBillType,
        expenseServiceType: expense.expenseServiceType,
        materialCategoryId: expense.materialCategoryId,
        isRecurringTemplate: expense.isRecurringTemplate,
        recurrenceDayOfMonth: expense.recurrenceDayOfMonth,
        recurrenceActive: expense.recurrenceActive,
      );

      final result = await repo.update(expense.id, input);
      var failed = false;
      result.when(
        success: (_) => updated++,
        failure: (e) {
          failed = true;
          setState(() {
            _loading = false;
            _error = e.message;
          });
        },
      );
      if (failed) return;

      if (_syncTemplates && expense.recurrenceTemplateId != null) {
        final templateResult = await repo.getById(expense.recurrenceTemplateId!);
        await templateResult.when(
          success: (template) async {
            await repo.update(
              template.id,
              FinancialRecordUpdateInput(
                recordType: template.recordType,
                category: template.category,
                description: template.description,
                amount: amount,
                taxAmount: template.taxAmount,
                referenceDate: template.referenceDate,
                dueDate: template.dueDate,
                paidAt: template.paidAt,
                notes: template.notes,
                unitId: template.unitId,
                rentalExpenseEntryType: template.rentalExpenseEntryType,
                condominiumBillType: template.condominiumBillType,
                expenseServiceType: template.expenseServiceType,
                materialCategoryId: template.materialCategoryId,
                isRecurringTemplate: true,
                recurrenceDayOfMonth: template.recurrenceDayOfMonth,
                recurrenceActive: template.recurrenceActive,
              ),
            );
          },
          failure: (_) {},
        );
      }
    }

    if (!mounted) return;
    ref.invalidate(rentalExpensesListProvider);
    ref.invalidate(rentalExpenseDueAlertsProvider);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$updated despesa(s) atualizada(s).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MM/yyyy').format(widget.month);

    return ClaySurface(
      depth: ClayDepth.raised,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ajustar fixas — $monthLabel',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Atualize valores reais das contas do mês (água, energia, internet…).',
            style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final expense = _items[index];
                final typeLabel = rentalExpenseTypeLabel(
                  entryType: expense.rentalExpenseEntryType,
                  billType: expense.condominiumBillType,
                  serviceType: expense.expenseServiceType,
                  materialCategoryName: expense.materialCategoryName,
                );

                return ClaySurface(
                  depth: ClayDepth.pressed,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(typeLabel, style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClayTextField(
                              controller: _amountControllers[expense.id]!,
                              label: 'Valor (R\$)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Pago'),
                            selected: _paidFlags[expense.id] ?? false,
                            onSelected: (v) => setState(() => _paidFlags[expense.id] = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          ClaySurface(
            depth: ClayDepth.pressed,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Atualizar modelos mensais', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                'Próximos meses usarão estes valores como base.',
                style: TextStyle(fontSize: 11),
              ),
              value: _syncTemplates,
              onChanged: (v) => setState(() => _syncTemplates = v),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: ClayTokens.error)),
          ],
          const SizedBox(height: 12),
          ClayButton(
            label: 'Salvar ajustes',
            icon: Icons.save_rounded,
            isLoading: _loading,
            onPressed: _loading ? null : _save,
          ),
        ],
      ),
    );
  }
}
