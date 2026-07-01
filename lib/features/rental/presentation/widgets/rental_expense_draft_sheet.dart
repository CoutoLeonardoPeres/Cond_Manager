import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/materials/domain/entities/material.dart' as mat;
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_expense_list_filter.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_expense_location.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_expense_mapping.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/condominium_bill_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:cond_manager/shared/domain/enums/rental_expense_entry_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

Future<bool?> showRentalExpenseDraftSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<Condominium> condominiums,
  required RentalExpenseListFilter filter,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: ClayTokens.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ClayTokens.radiusLg)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) => RentalExpenseDraftSheet(
        scrollController: scrollController,
        condominiums: condominiums,
        filter: filter,
      ),
    ),
  );
}

class RentalExpenseDraftSheet extends ConsumerStatefulWidget {
  const RentalExpenseDraftSheet({
    super.key,
    required this.scrollController,
    required this.condominiums,
    required this.filter,
  });

  final ScrollController scrollController;
  final List<Condominium> condominiums;
  final RentalExpenseListFilter filter;

  @override
  ConsumerState<RentalExpenseDraftSheet> createState() => _RentalExpenseDraftSheetState();
}

class _RentalExpenseDraftSheetState extends ConsumerState<RentalExpenseDraftSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  Condominium? _condominium;
  RentalExpenseLocation _location = const RentalExpenseLocation.condominium();
  RentalExpenseEntryType _entryType = RentalExpenseEntryType.fixedBill;
  CondominiumBillType _billType = CondominiumBillType.water;
  ServiceType _serviceType = ServiceType.other;
  mat.MaterialCategory? _materialCategory;
  DateTime? _dueDate;
  late DateTime _referenceDate;
  bool _isRecurringTemplate = true;
  int _recurrenceDay = 10;
  bool _isPaid = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final month = widget.filter.month ?? DateTime.now();
    _referenceDate = DateTime(month.year, month.month, DateTime.now().day);

    if (widget.filter.condominiumId != null) {
      for (final c in widget.condominiums) {
        if (c.id == widget.filter.condominiumId) {
          _condominium = c;
          break;
        }
      }
    } else if (widget.condominiums.length == 1) {
      _condominium = widget.condominiums.first;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double _parseAmount() => double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

  String _effectiveDescription() {
    final trimmed = _descriptionController.text.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return switch (_entryType) {
      RentalExpenseEntryType.fixedBill => _billType.label,
      RentalExpenseEntryType.service => _serviceType.label,
      RentalExpenseEntryType.material => _materialCategory?.name ?? 'Material',
    };
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
      description: _effectiveDescription(),
      amount: _parseAmount(),
      referenceDate: _referenceDate,
      dueDate: _dueDate,
      paidAt: _isPaid ? DateTime.now() : null,
      blockId: _location.blockId,
      rentalPropertyId: _location.rentalPropertyId,
      rentalExpenseEntryType: _entryType,
      condominiumBillType:
          _entryType == RentalExpenseEntryType.fixedBill ? _billType : null,
      expenseServiceType: _entryType == RentalExpenseEntryType.service ? _serviceType : null,
      materialCategoryId:
          _entryType == RentalExpenseEntryType.material ? _materialCategory?.id : null,
      isRecurringTemplate:
          _entryType == RentalExpenseEntryType.fixedBill && _isRecurringTemplate,
      recurrenceDayOfMonth: _isRecurringTemplate ? _recurrenceDay : null,
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
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickLocation() async {
    final condoId = _condominium?.id;
    if (condoId == null) return;

    final properties = await ref.read(rentalPropertiesByCondominiumProvider(condoId).future);
    final blocks = await ref.read(condominiumBlocksProvider(condoId).future);

    if (!mounted) return;

    final options = <RentalExpenseLocation>[
      const RentalExpenseLocation.condominium(),
      ...properties.map(
        (p) => RentalExpenseLocation.property(id: p.id, title: p.title),
      ),
      ...blocks.map(
        (b) => RentalExpenseLocation.block(id: b.id, name: b.name),
      ),
    ];

    final picked = await showModalBottomSheet<RentalExpenseLocation>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: options
              .map(
                (o) => ListTile(
                  title: Text(o.dropdownLabel),
                  trailing: o == _location ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.pop(ctx, o),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (picked != null) setState(() => _location = picked);
  }

  Future<void> _save() async {
    if (_condominium == null) {
      setState(() => _error = 'Selecione o condomínio.');
      return;
    }
    if (_parseAmount() <= 0) {
      setState(() => _error = 'Informe um valor válido.');
      return;
    }
    if (_entryType == RentalExpenseEntryType.material && _materialCategory == null) {
      setState(() => _error = 'Selecione a categoria de material.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await ref.read(financialRepositoryProvider).create(_buildCreateInput());
    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(rentalExpensesListProvider);
        ref.invalidate(rentalExpenseDueAlertsProvider);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Despesa registrada.')),
        );
      },
      failure: (e) => setState(() {
        _saving = false;
        _error = e.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final condoId = _condominium?.id;
    final categoriesAsync = condoId != null
        ? ref.watch(materialCategoriesProvider(condoId))
        : const AsyncValue<List<mat.MaterialCategory>>.data([]);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Text(
              'Nova despesa',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Preencha os campos como na planilha.',
              style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ClayDropdownField<Condominium?>(
              label: 'Condomínio',
              value: _condominium,
              items: widget.condominiums,
              itemLabel: (c) => c?.name ?? 'Selecione',
              onChanged: (c) => setState(() {
                _condominium = c;
                _location = const RentalExpenseLocation.condominium();
                _materialCategory = null;
              }),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Local', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text(_location.dropdownLabel),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _condominium == null ? null : _pickLocation,
            ),
            const SizedBox(height: 8),
            ClayDropdownField<RentalExpenseEntryType>(
              label: 'Tipo',
              value: _entryType,
              items: RentalExpenseEntryType.values,
              itemLabel: (t) => switch (t) {
                RentalExpenseEntryType.fixedBill => 'Conta fixa',
                RentalExpenseEntryType.service => 'Serviço',
                RentalExpenseEntryType.material => 'Material',
              },
              onChanged: (t) {
                if (t == null) return;
                setState(() {
                  _entryType = t;
                  if (t == RentalExpenseEntryType.fixedBill) {
                    _isRecurringTemplate = _billType.typicallyRecurring;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            if (_entryType == RentalExpenseEntryType.fixedBill)
              ClayDropdownField<CondominiumBillType>(
                label: 'Conta',
                value: _billType,
                items: CondominiumBillType.values,
                itemLabel: (t) => t.label,
                onChanged: (t) {
                  if (t == null) return;
                  setState(() {
                    _billType = t;
                    _isRecurringTemplate = t.typicallyRecurring;
                  });
                },
              ),
            if (_entryType == RentalExpenseEntryType.service)
              ClayDropdownField<ServiceType>(
                label: 'Serviço',
                value: _serviceType,
                items: ServiceType.values,
                itemLabel: (t) => t.label,
                onChanged: (t) {
                  if (t != null) setState(() => _serviceType = t);
                },
              ),
            if (_entryType == RentalExpenseEntryType.material)
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Erro ao carregar categorias.'),
                data: (cats) => ClayDropdownField<mat.MaterialCategory?>(
                  label: 'Categoria material',
                  value: _materialCategory,
                  items: [null, ...cats],
                  itemLabel: (c) => c?.name ?? 'Selecione',
                  onChanged: (c) => setState(() => _materialCategory = c),
                ),
              ),
            const SizedBox(height: 12),
            ClayTextField(
              controller: _descriptionController,
              label: 'Descrição',
              hint: 'Opcional — usa o tipo se vazio',
            ),
            const SizedBox(height: 12),
            ClayTextField(
              controller: _amountController,
              label: 'Valor (R\$)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data referência'),
              subtitle: Text(dateFmt.format(_referenceDate)),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: () => _pickDate(
                initial: _referenceDate,
                onPicked: (d) => setState(() => _referenceDate = d),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vencimento'),
              subtitle: Text(_dueDate == null ? '—' : dateFmt.format(_dueDate!)),
              trailing: const Icon(Icons.event_rounded),
              onTap: () => _pickDate(
                initial: _dueDate ?? _referenceDate,
                onPicked: (d) => setState(() => _dueDate = d),
              ),
            ),
            if (_entryType == RentalExpenseEntryType.fixedBill) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Despesa fixa recorrente'),
                value: _isRecurringTemplate,
                onChanged: (v) => setState(() => _isRecurringTemplate = v),
              ),
              if (_isRecurringTemplate)
                ClayDropdownField<int>(
                  label: 'Dia do vencimento',
                  value: _recurrenceDay,
                  items: List.generate(28, (i) => i + 1),
                  itemLabel: (d) => 'Dia $d',
                  onChanged: (d) {
                    if (d != null) setState(() => _recurrenceDay = d);
                  },
                ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Já paga'),
              value: _isPaid,
              onChanged: (v) => setState(() => _isPaid = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: ClayTokens.error)),
            ],
            const SizedBox(height: 16),
            ClayButton(
              label: _saving ? 'Salvando…' : 'Salvar despesa',
              icon: Icons.save_rounded,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
