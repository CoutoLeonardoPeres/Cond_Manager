import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/materials/domain/entities/material.dart' as mat;
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_expense_mapping.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:cond_manager/shared/domain/enums/condominium_bill_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:cond_manager/shared/domain/enums/rental_expense_entry_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RentalExpenseFormPage extends ConsumerStatefulWidget {
  const RentalExpenseFormPage({super.key, this.expenseId});

  final String? expenseId;

  bool get isEditing => expenseId != null;

  @override
  ConsumerState<RentalExpenseFormPage> createState() => _RentalExpenseFormPageState();
}

class _RentalExpenseFormPageState extends ConsumerState<RentalExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _taxController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  Condominium? _condominium;
  UnitOption? _unit;
  RentalExpenseEntryType _entryType = RentalExpenseEntryType.fixedBill;
  CondominiumBillType _billType = CondominiumBillType.water;
  ServiceType _serviceType = ServiceType.other;
  mat.MaterialCategory? _materialCategory;
  DateTime _referenceDate = DateTime.now();
  bool _markPaid = false;
  bool _isRecurringTemplate = false;
  int _recurrenceDay = 10;
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _fill(FinancialRecord r, List<Condominium> condos, List<mat.MaterialCategory> categories) {
    _descriptionController.text = r.description;
    _amountController.text = r.amount.toString();
    _taxController.text = r.taxAmount.toString();
    _notesController.text = r.notes ?? '';
    _referenceDate = r.referenceDate;
    _markPaid = r.isPaid;
    _entryType = r.rentalExpenseEntryType ?? RentalExpenseEntryType.fixedBill;
    _billType = r.condominiumBillType ?? CondominiumBillType.other;
    _serviceType = r.expenseServiceType ?? ServiceType.other;
    _isRecurringTemplate = r.isRecurringTemplate;
    _recurrenceDay = r.recurrenceDayOfMonth ?? 10;
    for (final c in condos) {
      if (c.id == r.condominiumId) _condominium = c;
    }
    if (r.materialCategoryId != null) {
      for (final cat in categories) {
        if (cat.id == r.materialCategoryId) _materialCategory = cat;
      }
    }
    _loaded = true;
  }

  FinancialRecordCreateInput _buildCreateInput() {
    final category = financialCategoryForRentalExpense(
      entryType: _entryType,
      billType: _entryType == RentalExpenseEntryType.fixedBill ? _billType : null,
    );
    return FinancialRecordCreateInput(
      scope: FinancialScope.condominium,
      condominiumId: _condominium!.id,
      recordType: FinancialRecordType.expense,
      category: category,
      description: _descriptionController.text.trim(),
      amount: _parse(_amountController.text),
      taxAmount: _parse(_taxController.text),
      referenceDate: _referenceDate,
      paidAt: _markPaid ? DateTime.now() : null,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      unitId: _unit?.id,
      rentalExpenseEntryType: _entryType,
      condominiumBillType: _entryType == RentalExpenseEntryType.fixedBill ? _billType : null,
      expenseServiceType: _entryType == RentalExpenseEntryType.service ? _serviceType : null,
      materialCategoryId: _entryType == RentalExpenseEntryType.material ? _materialCategory?.id : null,
      isRecurringTemplate: _entryType == RentalExpenseEntryType.fixedBill && _isRecurringTemplate,
      recurrenceDayOfMonth: _isRecurringTemplate ? _recurrenceDay : null,
    );
  }

  FinancialRecordUpdateInput _buildUpdateInput(FinancialRecord existing) {
    final category = financialCategoryForRentalExpense(
      entryType: _entryType,
      billType: _entryType == RentalExpenseEntryType.fixedBill ? _billType : null,
    );
    return FinancialRecordUpdateInput(
      recordType: existing.recordType,
      category: category,
      description: _descriptionController.text.trim(),
      amount: _parse(_amountController.text),
      taxAmount: _parse(_taxController.text),
      referenceDate: _referenceDate,
      paidAt: _markPaid ? (existing.paidAt ?? DateTime.now()) : null,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      unitId: _unit?.id,
      rentalExpenseEntryType: _entryType,
      condominiumBillType: _entryType == RentalExpenseEntryType.fixedBill ? _billType : null,
      expenseServiceType: _entryType == RentalExpenseEntryType.service ? _serviceType : null,
      materialCategoryId: _entryType == RentalExpenseEntryType.material ? _materialCategory?.id : null,
      isRecurringTemplate: _entryType == RentalExpenseEntryType.fixedBill && _isRecurringTemplate,
      recurrenceDayOfMonth: _isRecurringTemplate ? _recurrenceDay : null,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_condominium == null) {
      setState(() => _error = 'Selecione o condomínio.');
      return;
    }
    if (_entryType == RentalExpenseEntryType.material && _materialCategory == null) {
      setState(() => _error = 'Selecione a categoria de material.');
      return;
    }
    if (_parse(_amountController.text) <= 0) {
      setState(() => _error = 'Informe um valor válido.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(financialRepositoryProvider);

    if (widget.isEditing) {
      final existingResult = await repo.getById(widget.expenseId!);
      if (!mounted) return;
      existingResult.when(
        success: (record) async {
          final result = await repo.update(widget.expenseId!, _buildUpdateInput(record));
          if (!mounted) return;
          result.when(
            success: (_) {
              ref.invalidate(rentalExpensesListProvider);
              ref.invalidate(rentalExpenseDueAlertsProvider);
              ref.invalidate(rentalExpenseDetailProvider(widget.expenseId!));
              context.go('/rental/expenses/${widget.expenseId}');
            },
            failure: (e) => setState(() {
              _loading = false;
              _error = e.message;
            }),
          );
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
      return;
    }

    final result = await repo.create(_buildCreateInput());
    if (!mounted) return;
    result.when(
      success: (record) {
        ref.invalidate(rentalExpensesListProvider);
        ref.invalidate(rentalExpenseDueAlertsProvider);
        context.go('/rental/expenses/${record.id}');
      },
      failure: (e) => setState(() {
        _loading = false;
        _error = e.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final condos = condosAsync.value ?? const <Condominium>[];
    final condoId = _condominium?.id;

    final unitsAsync = condoId != null
        ? ref.watch(ticketUnitsProvider(condoId))
        : const AsyncValue<List<UnitOption>>.data([]);

    final categoriesAsync = condoId != null
        ? ref.watch(materialCategoriesProvider(condoId))
        : const AsyncValue<List<mat.MaterialCategory>>.data([]);

    if (widget.isEditing) {
      ref.watch(rentalExpenseDetailProvider(widget.expenseId!)).whenData((r) {
        if (!_loaded && condos.isNotEmpty) {
          final categories = categoriesAsync.value ?? const <mat.MaterialCategory>[];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) {
              setState(() => _fill(r, condos, categories));
              if (r.unitId != null && condoId != null) {
                ref.read(ticketUnitsProvider(condoId)).whenData((units) {
                  for (final u in units) {
                    if (u.id == r.unitId) setState(() => _unit = u);
                  }
                });
              }
            }
          });
        }
      });
    } else if (_condominium == null && condos.length == 1) {
      _condominium = condos.first;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClaySurface(
                  depth: ClayDepth.raised,
                  radius: ClayTokens.radiusFull,
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go(
                      resolveReturnPath(context, fallback: '/rental/expenses'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isEditing ? 'Editar despesa' : 'Nova despesa',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Despesa do condomínio ou de uma unidade. Sem unidade selecionada, a despesa é do condomínio.',
              style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            condosAsync.when(
              data: (list) => ClayDropdownField<Condominium>(
                label: 'Condomínio *',
                value: _condominium,
                items: list,
                itemLabel: (c) => c.name,
                onChanged: widget.isEditing
                    ? null
                    : (c) => setState(() {
                          _condominium = c;
                          _unit = null;
                          _materialCategory = null;
                        }),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            if (condoId != null)
              unitsAsync.when(
                data: (units) => ClayDropdownField<UnitOption?>(
                  label: 'Unidade',
                  hint: 'Opcional — deixe vazio para despesa do condomínio',
                  value: _unit,
                  items: [null, ...units],
                  itemLabel: (u) => u?.label ?? 'Condomínio (áreas comuns / geral)',
                  onChanged: (u) => setState(() => _unit = u),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            const SizedBox(height: 16),
            SegmentedButton<RentalExpenseEntryType>(
              segments: RentalExpenseEntryType.values
                  .map((t) => ButtonSegment(value: t, label: Text(t.label, style: const TextStyle(fontSize: 11))))
                  .toList(),
              selected: {_entryType},
              onSelectionChanged: (s) => setState(() {
                _entryType = s.first;
                if (_entryType == RentalExpenseEntryType.fixedBill &&
                    _billType.typicallyRecurring) {
                  _isRecurringTemplate = true;
                }
              }),
            ),
            const SizedBox(height: 12),
            if (_entryType == RentalExpenseEntryType.fixedBill)
              ClayDropdownField<CondominiumBillType>(
                label: 'Tipo de conta / despesa fixa',
                value: _billType,
                items: CondominiumBillType.values,
                itemLabel: (t) => t.label,
                onChanged: (v) => setState(() {
                  _billType = v ?? CondominiumBillType.other;
                  if (_billType.typicallyRecurring) _isRecurringTemplate = true;
                }),
              ),
            if (_entryType == RentalExpenseEntryType.service)
              ClayDropdownField<ServiceType>(
                label: 'Tipo de serviço',
                value: _serviceType,
                items: ServiceType.values,
                itemLabel: (t) => t.label,
                onChanged: (v) => setState(() => _serviceType = v ?? ServiceType.other),
              ),
            if (_entryType == RentalExpenseEntryType.material)
              categoriesAsync.when(
                data: (categories) => ClayDropdownField<mat.MaterialCategory>(
                  label: 'Categoria de material',
                  value: _materialCategory,
                  items: categories,
                  itemLabel: (c) => c.name,
                  onChanged: (v) => setState(() => _materialCategory = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Erro ao carregar categorias de material.'),
              ),
            const SizedBox(height: 12),
            ClayTextField(
              controller: _descriptionController,
              label: 'Descrição *',
              validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClayTextField(
                    controller: _amountController,
                    label: 'Valor (R\$) *',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClayTextField(
                    controller: _taxController,
                    label: 'Impostos (R\$)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DateTile(
              label: 'Data de referência',
              date: _referenceDate,
              onPick: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _referenceDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _referenceDate = picked);
              },
            ),
            const SizedBox(height: 8),
            ClaySurface(
              depth: ClayDepth.pressed,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Marcar como pago', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                value: _markPaid,
                onChanged: (v) => setState(() => _markPaid = v),
              ),
            ),
            if (_entryType == RentalExpenseEntryType.fixedBill) ...[
              const SizedBox(height: 8),
              ClaySurface(
                depth: ClayDepth.pressed,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Modelo mensal recorrente',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Use para água, energia, internet etc. Gere cópias pelo botão na listagem.',
                    style: TextStyle(fontSize: 12, color: ClayTokens.textSecondary),
                  ),
                  value: _isRecurringTemplate,
                  onChanged: (v) => setState(() => _isRecurringTemplate = v),
                ),
              ),
              if (_isRecurringTemplate) ...[
                const SizedBox(height: 8),
                ClayDropdownField<int>(
                  label: 'Dia do vencimento no mês',
                  value: _recurrenceDay,
                  items: List.generate(28, (i) => i + 1),
                  itemLabel: (d) => 'Dia $d',
                  onChanged: (d) => setState(() => _recurrenceDay = d ?? 10),
                ),
              ],
            ],
            const SizedBox(height: 12),
            ClayTextField(
              controller: _notesController,
              label: 'Observações',
              maxLines: 3,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: ClayTokens.error)),
            ],
            const SizedBox(height: 24),
            ClayButton(
              label: widget.isEditing ? 'Salvar' : 'Registrar despesa',
              icon: Icons.save_rounded,
              isLoading: _loading,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.date, required this.onPick});

  final String label;
  final DateTime date;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: InkWell(
        onTap: onPick,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: ClayTokens.textSecondary)),
                  const SizedBox(height: 4),
                  Text(formatted, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
            const Icon(Icons.calendar_today_rounded, color: ClayTokens.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
