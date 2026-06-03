import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/preventive/domain/entities/preventive_plan.dart';
import 'package:cond_manager/features/preventive/presentation/providers/preventive_providers.dart';
import 'package:cond_manager/features/preventive/presentation/widgets/preventive_checklist_editor.dart';
import 'package:cond_manager/features/preventive/utils/preventive_schedule.dart';
import 'package:cond_manager/features/providers/domain/entities/service_provider.dart';
import 'package:cond_manager/features/providers/presentation/providers/service_provider_providers.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/location_type.dart';
import 'package:cond_manager/shared/domain/enums/preventive_frequency.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PreventivePlanFormPage extends ConsumerStatefulWidget {
  const PreventivePlanFormPage({super.key, this.planId});

  final String? planId;

  bool get isEditing => planId != null;

  @override
  ConsumerState<PreventivePlanFormPage> createState() => _PreventivePlanFormPageState();
}

class _PreventivePlanFormPageState extends ConsumerState<PreventivePlanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _leadTimeController = TextEditingController(text: '7');
  final _costController = TextEditingController(text: '0');

  Condominium? _condominium;
  ServiceType _serviceType = ServiceType.other;
  PreventiveFrequency _frequency = PreventiveFrequency.monthly;
  DateTime _startDate = PreventiveSchedule.todayLocal();
  DateTime? _nextDueDate;
  LocationType _locationType = LocationType.other;
  UnitOption? _unit;
  CommonAreaOption? _commonArea;
  PreventiveAssigneeType _assigneeType = PreventiveAssigneeType.none;
  InternalStaffOption? _internalStaff;
  ProviderPickerOption? _provider;
  bool _autoGenerateOs = true;
  EntityStatus _status = EntityStatus.active;
  List<PreventiveChecklistItemInput> _checklist = [];
  bool _loading = false;
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _leadTimeController.dispose();
    _costController.dispose();
    super.dispose();
  }

  int get _leadTime => int.tryParse(_leadTimeController.text) ?? 7;

  void _fill(PreventivePlan p, List<Condominium> condos) {
    _nameController.text = p.name;
    _descriptionController.text = p.description ?? '';
    _leadTimeController.text = p.leadTimeDays.toString();
    _costController.text = p.estimatedCost.toString();
    _serviceType = p.serviceType;
    _frequency = p.frequency;
    _startDate = p.startDate;
    _nextDueDate = p.nextDueDate;
    _autoGenerateOs = p.autoGenerateOs;
    _status = p.status;
    _checklist = p.checklistItems
        .map((c) => PreventiveChecklistItemInput(description: c.description, sortOrder: c.sortOrder))
        .toList();
    _assigneeType = p.assigneeType;
    if (p.unitId != null) _locationType = LocationType.unit;
    if (p.commonAreaId != null) _locationType = LocationType.commonArea;
    for (final c in condos) {
      if (c.id == p.condominiumId) _condominium = c;
    }
    _loaded = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_condominium == null) {
      setState(() => _error = 'Selecione o condomínio.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(preventiveRepositoryProvider);
    final cost = double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0;
    final checklist = _checklist.where((c) => c.description.trim().isNotEmpty).toList();

    if (widget.isEditing) {
      final result = await repo.updatePlan(
        widget.planId!,
        PreventivePlanUpdateInput(
          name: _nameController.text,
          description: _descriptionController.text,
          serviceType: _serviceType,
          frequency: _frequency,
          unitId: _locationType == LocationType.unit ? _unit?.id : null,
          commonAreaId: _locationType == LocationType.commonArea ? _commonArea?.id : null,
          responsibleId:
              _assigneeType == PreventiveAssigneeType.internal ? _internalStaff?.profileId : null,
          providerId: _assigneeType == PreventiveAssigneeType.provider ? _provider?.id : null,
          nextDueDate: _nextDueDate ?? _startDate,
          leadTimeDays: _leadTime,
          autoGenerateOs: _autoGenerateOs,
          estimatedCost: cost,
          status: _status,
          checklistItems: checklist,
        ),
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(preventivePlansListProvider);
          context.go('/preventive/${widget.planId}');
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final result = await repo.createPlan(
        PreventivePlanCreateInput(
          condominiumId: _condominium!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          serviceType: _serviceType,
          frequency: _frequency,
          unitId: _locationType == LocationType.unit ? _unit?.id : null,
          commonAreaId: _locationType == LocationType.commonArea ? _commonArea?.id : null,
          responsibleId:
              _assigneeType == PreventiveAssigneeType.internal ? _internalStaff?.profileId : null,
          providerId: _assigneeType == PreventiveAssigneeType.provider ? _provider?.id : null,
          startDate: _startDate,
          leadTimeDays: _leadTime,
          autoGenerateOs: _autoGenerateOs,
          estimatedCost: cost,
          checklistItems: checklist,
        ),
      );
      if (!mounted) return;
      result.when(
        success: (p) {
          ref.invalidate(preventivePlansListProvider);
          context.go('/preventive/${p.id}');
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
    final condoId = _condominium?.id;

    if (widget.isEditing) {
      ref.watch(preventivePlanDetailProvider(widget.planId!)).whenData((p) {
        if (!_loaded && condos.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) setState(() => _fill(p, condos));
          });
        }
      });
    } else if (_condominium == null && condos.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _condominium == null) setState(() => _condominium = condos.first);
      });
    }

    final unitsAsync = condoId != null
        ? ref.watch(ticketUnitsProvider(condoId))
        : const AsyncValue<List<UnitOption>>.data([]);
    final areasAsync = condoId != null
        ? ref.watch(ticketCommonAreasProvider(condoId))
        : const AsyncValue<List<CommonAreaOption>>.data([]);
    final staffAsync = condoId != null
        ? ref.watch(workOrderInternalStaffProvider(condoId))
        : const AsyncValue<List<InternalStaffOption>>.data([]);
    final providerQuery = condoId != null
        ? ProviderPickerQuery(condominiumId: condoId, serviceType: _serviceType)
        : null;
    final providersAsync = providerQuery != null
        ? ref.watch(workOrderProviderPickerProvider(providerQuery))
        : const AsyncValue<List<ProviderPickerOption>>.data([]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = formColumnsForWidth(constraints.maxWidth);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          context.go(resolveReturnPath(context, fallback: '/preventive')),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Editar plano preventivo' : 'Novo plano preventivo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: ClayTokens.error)),
                ],
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Plano',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayDropdownField<Condominium>(
                        label: 'Condomínio *',
                        value: _condominium,
                        items: condos,
                        itemLabel: (c) => c.name,
                        onChanged: widget.isEditing
                            ? null
                            : (v) => setState(() => _condominium = v),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _nameController,
                        label: 'Nome do plano *',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<ServiceType>(
                        label: 'Tipo de serviço *',
                        value: _serviceType,
                        items: ServiceType.values,
                        itemLabel: (s) => s.label,
                        onChanged: (v) => setState(() {
                          _serviceType = v ?? ServiceType.other;
                          _provider = null;
                        }),
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<PreventiveFrequency>(
                        label: 'Periodicidade *',
                        value: _frequency,
                        items: PreventiveFrequency.values,
                        itemLabel: (f) => f.label,
                        onChanged: (v) =>
                            setState(() => _frequency = v ?? PreventiveFrequency.monthly),
                      ),
                    ),
                    if (!widget.isEditing)
                      FormGridField(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Data de início'),
                          subtitle: Text(
                            '${_startDate.day.toString().padLeft(2, '0')}/'
                            '${_startDate.month.toString().padLeft(2, '0')}/'
                            '${_startDate.year}',
                          ),
                          trailing: const Icon(Icons.calendar_today_rounded),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setState(() => _startDate = picked);
                          },
                        ),
                      ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _leadTimeController,
                        label: 'Alertar com antecedência (dias) *',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    FormGridField(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Gerar OS automaticamente no backlog'),
                        value: _autoGenerateOs,
                        onChanged: (v) => setState(() => _autoGenerateOs = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Responsável padrão (OS)',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayDropdownField<PreventiveAssigneeType>(
                        label: 'Destino da OS',
                        value: _assigneeType,
                        items: PreventiveAssigneeType.values,
                        itemLabel: (t) => t.label,
                        onChanged: (v) => setState(() {
                          _assigneeType = v ?? PreventiveAssigneeType.none;
                          _internalStaff = null;
                          _provider = null;
                        }),
                      ),
                    ),
                    if (_assigneeType == PreventiveAssigneeType.internal)
                      FormGridField(
                        child: staffAsync.when(
                          data: (s) => ClayDropdownField<InternalStaffOption>(
                            label: 'Funcionário',
                            value: _internalStaff,
                            items: s,
                            itemLabel: (x) => '${x.fullName} (${x.roleLabel})',
                            onChanged: (v) => setState(() => _internalStaff = v),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                    if (_assigneeType == PreventiveAssigneeType.provider)
                      FormGridField(
                        child: providersAsync.when(
                          data: (p) => ClayDropdownField<ProviderPickerOption>(
                            label: 'Prestador',
                            value: _provider,
                            items: p,
                            itemLabel: (x) => x.label,
                            onChanged: (v) => setState(() => _provider = v),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Local (opcional)',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayDropdownField<LocationType>(
                        label: 'Local',
                        value: _locationType,
                        items: LocationType.values,
                        itemLabel: (l) => l.label,
                        onChanged: (v) => setState(() {
                          _locationType = v ?? LocationType.other;
                          _unit = null;
                          _commonArea = null;
                        }),
                      ),
                    ),
                    if (_locationType == LocationType.unit)
                      FormGridField(
                        child: unitsAsync.when(
                          data: (u) => ClayDropdownField<UnitOption>(
                            label: 'Unidade',
                            value: _unit,
                            items: u,
                            itemLabel: (x) => x.label,
                            onChanged: (v) => setState(() => _unit = v),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                    if (_locationType == LocationType.commonArea)
                      FormGridField(
                        child: areasAsync.when(
                          data: (a) => ClayDropdownField<CommonAreaOption>(
                            label: 'Área comum',
                            value: _commonArea,
                            items: a,
                            itemLabel: (x) => x.label,
                            onChanged: (v) => setState(() => _commonArea = v),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                PreventiveChecklistEditor(
                  items: _checklist,
                  onChanged: (c) => setState(() => _checklist = c),
                ),
                const SizedBox(height: 24),
                ClayButton(
                  label: widget.isEditing ? 'Salvar' : 'Criar plano',
                  icon: Icons.save_rounded,
                  isLoading: _loading,
                  onPressed: _loading ? null : _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
