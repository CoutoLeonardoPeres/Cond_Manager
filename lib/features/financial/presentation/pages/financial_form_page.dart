import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/materials/domain/entities/material.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/shared/domain/enums/financial_category.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FinancialFormPage extends ConsumerStatefulWidget {
  const FinancialFormPage({
    super.key,
    this.recordId,
    this.initialScope,
    this.initialCondominiumId,
  });

  final String? recordId;
  final FinancialScope? initialScope;
  final String? initialCondominiumId;

  bool get isEditing => recordId != null;

  @override
  ConsumerState<FinancialFormPage> createState() => _FinancialFormPageState();
}

class _FinancialFormPageState extends ConsumerState<FinancialFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _taxController = TextEditingController(text: '0');
  final _hoursController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();

  FinancialScope _scope = FinancialScope.condominium;
  Condominium? _condominium;
  FinancialRecordType _recordType = FinancialRecordType.expense;
  FinancialCategory _category = FinancialCategory.other;
  DateTime _referenceDate = DateTime.now();
  DateTime? _dueDate;
  bool _markPaid = false;
  DateTime? _originalPaidAt;
  ProviderPickerForMaterial? _provider;
  bool _loading = false;
  String? _error;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialScope != null) _scope = widget.initialScope!;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    _hoursController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _recalcLaborAmount() {
    if (_category != FinancialCategory.laborHour) return;
    final h = _parse(_hoursController.text);
    final r = _parse(_rateController.text);
    if (h > 0 && r > 0) _amountController.text = (h * r).toStringAsFixed(2);
  }

  void _fill(FinancialRecord r, List<Condominium> condos, List<ProviderPickerForMaterial> suppliers) {
    _scope = r.scope;
    _recordType = r.recordType;
    _category = r.category;
    _descriptionController.text = r.description;
    _amountController.text = r.amount.toString();
    _taxController.text = r.taxAmount.toString();
    _referenceDate = r.referenceDate;
    _dueDate = r.dueDate;
    _markPaid = r.isPaid;
    _originalPaidAt = r.paidAt;
    _notesController.text = r.notes ?? '';
    if (r.laborHours != null) _hoursController.text = r.laborHours.toString();
    if (r.hourlyRate != null) _rateController.text = r.hourlyRate.toString();
    for (final c in condos) {
      if (c.id == r.condominiumId) _condominium = c;
    }
    if (r.providerId != null) {
      for (final p in suppliers) {
        if (p.id == r.providerId) _provider = p;
      }
      _provider ??= ProviderPickerForMaterial(
        id: r.providerId!,
        label: r.providerName ?? 'Prestador',
      );
    }
    _loaded = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scope == FinancialScope.condominium && _condominium == null) {
      setState(() => _error = 'Selecione o condomínio.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final amount = _parse(_amountController.text);
    final tax = _parse(_taxController.text);
    final hours = _category == FinancialCategory.laborHour ? _parse(_hoursController.text) : null;
    final rate = _category == FinancialCategory.laborHour ? _parse(_rateController.text) : null;
    final paidAt = _markPaid ? (_originalPaidAt ?? DateTime.now()) : null;

    final repo = ref.read(financialRepositoryProvider);

    if (widget.isEditing) {
      final result = await repo.update(
        widget.recordId!,
        FinancialRecordUpdateInput(
          recordType: _recordType,
          category: _category,
          description: _descriptionController.text,
          amount: amount,
          taxAmount: tax,
          laborHours: (hours ?? 0) > 0 ? hours : null,
          hourlyRate: (rate ?? 0) > 0 ? rate : null,
          referenceDate: _referenceDate,
          dueDate: _dueDate,
          paidAt: paidAt,
          providerId: _provider?.id,
          notes: _notesController.text,
        ),
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(financialRecordsListProvider);
          context.go('/financial');
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final result = await repo.create(
        FinancialRecordCreateInput(
          scope: _scope,
          condominiumId: _condominium?.id,
          recordType: _recordType,
          category: _category,
          description: _descriptionController.text,
          amount: amount,
          taxAmount: tax,
          laborHours: (hours ?? 0) > 0 ? hours : null,
          hourlyRate: (rate ?? 0) > 0 ? rate : null,
          referenceDate: _referenceDate,
          dueDate: _dueDate,
          paidAt: paidAt,
          providerId: _provider?.id,
          notes: _notesController.text,
        ),
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(financialRecordsListProvider);
          context.go('/financial');
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final condos = condosAsync.value ?? const <Condominium>[];
    final condoId = _condominium?.id ?? widget.initialCondominiumId;

    final suppliersAsync = condoId != null
        ? ref.watch(materialSuppliersProvider(condoId))
        : const AsyncValue<List<ProviderPickerForMaterial>>.data([]);

    if (widget.isEditing) {
      ref.watch(financialRecordDetailProvider(widget.recordId!)).whenData((r) {
        if (!_loaded && condos.isNotEmpty) {
          final suppliers = suppliersAsync.value ?? const <ProviderPickerForMaterial>[];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) setState(() => _fill(r, condos, suppliers));
          });
        }
      });
    } else {
      if (_condominium == null && widget.initialCondominiumId != null) {
        for (final c in condos) {
          if (c.id == widget.initialCondominiumId) _condominium = c;
        }
      } else if (_condominium == null && condos.length == 1 && _scope == FinancialScope.condominium) {
        _condominium = condos.first;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : formColumnsForWidth(constraints.maxWidth);

        final valueItems = <FormGridField>[
          FormGridField(
            span: columns,
            child: ClayTextField(
              controller: _descriptionController,
              label: 'Descrição *',
              validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
          ),
          if (_category == FinancialCategory.laborHour) ...[
            FormGridField(
              child: ClayTextField(
                controller: _hoursController,
                label: 'Horas',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _recalcLaborAmount(),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _rateController,
                label: 'Valor/hora (R\$)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _recalcLaborAmount(),
              ),
            ),
          ],
          FormGridField(
            child: ClayTextField(
              controller: _amountController,
              label: 'Valor (R\$) *',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Obrigatório';
                if (_parse(v) <= 0) return 'Informe um valor válido';
                return null;
              },
            ),
          ),
          FormGridField(
            child: ClayTextField(
              controller: _taxController,
              label: 'Impostos (R\$)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ];

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
                        onPressed: () =>
                            context.go(resolveReturnPath(context, fallback: '/financial')),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Editar lançamento' : 'Novo lançamento',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isEditing
                      ? 'Atualize valores, datas e vínculos do lançamento.'
                      : 'Registre receita ou despesa do condomínio ou da gestora.',
                  style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  ClaySurface(
                    depth: ClayDepth.pressed,
                    color: ClayTokens.error.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(14),
                    child: Text(_error!, style: const TextStyle(color: ClayTokens.error)),
                  ),
                ],
                const SizedBox(height: 20),
                FormGridSection(
                  title: 'Contexto',
                  columns: columns,
                  items: [
                    if (!widget.isEditing)
                      FormGridField(
                        span: columns,
                        child: SegmentedButton<FinancialScope>(
                          segments: const [
                            ButtonSegment(
                              value: FinancialScope.condominium,
                              label: Text('Condomínio'),
                            ),
                            ButtonSegment(
                              value: FinancialScope.managementCompany,
                              label: Text('Gestora'),
                            ),
                          ],
                          selected: {_scope},
                          onSelectionChanged: (s) => setState(() {
                            _scope = s.first;
                            if (_scope == FinancialScope.managementCompany) {
                              _condominium = null;
                            }
                          }),
                        ),
                      ),
                    if (_scope == FinancialScope.condominium)
                      FormGridField(
                        child: ClayDropdownField<Condominium>(
                          label: 'Condomínio *',
                          value: _condominium,
                          items: condos,
                          itemLabel: (c) => c.name,
                          onChanged: widget.isEditing ? null : (v) => setState(() => _condominium = v),
                        ),
                      ),
                    FormGridField(
                      child: ClayDropdownField<FinancialRecordType>(
                        label: 'Tipo *',
                        value: _recordType,
                        items: FinancialRecordType.values,
                        itemLabel: (t) => t.label,
                        onChanged: (v) => setState(() => _recordType = v ?? FinancialRecordType.expense),
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<FinancialCategory>(
                        label: 'Categoria *',
                        value: _category,
                        items: FinancialCategory.values,
                        itemLabel: (c) => c.label,
                        onChanged: (v) => setState(() => _category = v ?? FinancialCategory.other),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Descrição e valores',
                  columns: columns,
                  items: valueItems,
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Datas e vínculos',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: _FinancialDateTile(
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
                    ),
                    FormGridField(
                      child: ClaySurface(
                        depth: ClayDepth.pressed,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Marcar como pago',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          value: _markPaid,
                          onChanged: (v) => setState(() => _markPaid = v),
                        ),
                      ),
                    ),
                    if (condoId != null)
                      FormGridField(
                        child: suppliersAsync.when(
                          data: (list) {
                            final items = [null, ...list];
                            return ClayDropdownField<ProviderPickerForMaterial?>(
                              label: 'Prestador / fornecedor',
                              value: _provider,
                              items: items,
                              itemLabel: (p) => p?.label ?? '—',
                              onChanged: (v) => setState(() => _provider = v),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Observações',
                  columns: columns,
                  items: [
                    FormGridField(
                      span: columns,
                      child: ClayTextField(
                        controller: _notesController,
                        label: 'Observações',
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: columns >= 3 ? 240 : double.infinity,
                    child: ClayButton(
                      label: widget.isEditing ? 'Salvar' : 'Registrar',
                      icon: Icons.save_rounded,
                      isLoading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FinancialDateTile extends StatelessWidget {
  const _FinancialDateTile({
    required this.label,
    required this.date,
    required this.onPick,
  });

  final String label;
  final DateTime date;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: ClayTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatted,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
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
