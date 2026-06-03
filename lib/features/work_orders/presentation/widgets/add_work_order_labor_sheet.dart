import 'package:cond_manager/features/providers/domain/entities/service_provider.dart';
import 'package:cond_manager/features/providers/presentation/providers/service_provider_providers.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order_labor.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_labor_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/shared/domain/enums/labor_source.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AddWorkOrderLaborSheet extends ConsumerStatefulWidget {
  const AddWorkOrderLaborSheet({super.key, required this.workOrder});

  final WorkOrder workOrder;

  static Future<void> show(BuildContext context, WorkOrder workOrder) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: AddWorkOrderLaborSheet(workOrder: workOrder),
      ),
    );
  }

  @override
  ConsumerState<AddWorkOrderLaborSheet> createState() => _AddWorkOrderLaborSheetState();
}

class _AddWorkOrderLaborSheetState extends ConsumerState<AddWorkOrderLaborSheet> {
  final _workerNameController = TextEditingController();
  final _workerCountController = TextEditingController(text: '1');
  final _hoursController = TextEditingController();
  final _rateController = TextEditingController();
  final _travelController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  LaborSource _source = LaborSource.thirdParty;
  ServiceType _serviceType = ServiceType.other;
  InternalStaffOption? _staff;
  ProviderPickerOption? _provider;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _serviceType = widget.workOrder.serviceType;
  }

  @override
  void dispose() {
    _workerNameController.dispose();
    _workerCountController.dispose();
    _hoursController.dispose();
    _rateController.dispose();
    _travelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;
  int _parseInt(String text) => int.tryParse(text.trim()) ?? 0;

  double get _previewLabor {
    final count = _parseInt(_workerCountController.text);
    final h = _parse(_hoursController.text);
    final r = _parse(_rateController.text);
    return count * h * r;
  }

  double get _previewTotal => _previewLabor + _parse(_travelController.text);

  Future<void> _submit() async {
    final workerName = _workerNameController.text.trim();
    final workerCount = _parseInt(_workerCountController.text);
    final hours = _parse(_hoursController.text);
    final rate = _parse(_rateController.text);
    final travel = _parse(_travelController.text);

    if (workerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome ou identificação da equipe.')),
      );
      return;
    }
    if (workerCount < 1 || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profissionais e horas devem ser maiores que zero.')),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await ref.read(workOrderRepositoryProvider).addLabor(
          AddWorkOrderLaborInput(
            workOrderId: widget.workOrder.id,
            condominiumId: widget.workOrder.condominiumId,
            laborSource: _source,
            serviceType: _serviceType,
            workerName: workerName,
            workerCount: workerCount,
            hours: hours,
            hourlyRate: rate,
            travelCost: travel,
            providerId: _provider?.id,
            profileId: _staff?.profileId,
            notes: _notesController.text,
          ),
        );

    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(workOrderLaborProvider(widget.workOrder.id));
        ref.invalidate(workOrderDetailProvider(widget.workOrder.id));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mão de obra lançada na OS.')),
        );
      },
      failure: (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final staffAsync = ref.watch(workOrderInternalStaffProvider(widget.workOrder.condominiumId));
    final providersAsync = ref.watch(
      workOrderProviderPickerProvider(
        ProviderPickerQuery(
          condominiumId: widget.workOrder.condominiumId,
          serviceType: _serviceType,
        ),
      ),
    );

    return ClaySurface(
      depth: ClayDepth.raised,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lançar mão de obra',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SegmentedButton<LaborSource>(
              segments: const [
                ButtonSegment(value: LaborSource.thirdParty, label: Text('Terceirizado')),
                ButtonSegment(value: LaborSource.internalTeam, label: Text('Equipe própria')),
              ],
              selected: {_source},
              onSelectionChanged: (s) => setState(() {
                _source = s.first;
                _provider = null;
                _staff = null;
              }),
            ),
            const SizedBox(height: 12),
            ClayDropdownField<ServiceType>(
              label: 'Categoria / função *',
              value: _serviceType,
              items: ServiceType.values,
              itemLabel: (t) => t.label,
              onChanged: (v) => setState(() {
                _serviceType = v ?? ServiceType.other;
                _provider = null;
              }),
            ),
            const SizedBox(height: 12),
            if (_source == LaborSource.internalTeam)
              staffAsync.when(
                data: (list) {
                  final items = [null, ...list];
                  return ClayDropdownField<InternalStaffOption?>(
                    label: 'Funcionário (opcional)',
                    value: _staff,
                    items: items,
                    itemLabel: (s) => s == null ? '—' : '${s.fullName} (${s.roleLabel})',
                    onChanged: (v) => setState(() {
                      _staff = v;
                      if (v != null) _workerNameController.text = v.fullName;
                    }),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              )
            else
              providersAsync.when(
                data: (list) {
                  final items = [null, ...list];
                  return ClayDropdownField<ProviderPickerOption?>(
                    label: 'Prestador (opcional)',
                    value: _provider,
                    items: items,
                    itemLabel: (p) => p?.label ?? '—',
                    onChanged: (v) => setState(() {
                      _provider = v;
                      if (v != null) _workerNameController.text = v.label;
                    }),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            const SizedBox(height: 12),
            ClayTextField(
              controller: _workerNameController,
              label: 'Nome / equipe *',
              hint: 'Ex.: Equipe elétrica João, Pedreiros Silva',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClayTextField(
                    controller: _workerCountController,
                    label: 'Nº profissionais *',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClayTextField(
                    controller: _hoursController,
                    label: 'Horas / prof. *',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClayTextField(
                    controller: _rateController,
                    label: 'Valor/hora (R\$) *',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClayTextField(
                    controller: _travelController,
                    label: 'Deslocamento (R\$)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'HH: ${currency.format(_previewLabor)} · Total: ${currency.format(_previewTotal)}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: ClayTokens.primary),
            ),
            const SizedBox(height: 12),
            ClayTextField(controller: _notesController, label: 'Observações', maxLines: 2),
            const SizedBox(height: 16),
            ClayButton(
              label: 'Confirmar lançamento',
              icon: Icons.check_rounded,
              isLoading: _loading,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
