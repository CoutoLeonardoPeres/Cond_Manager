import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_property_link_field.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/providers/domain/entities/service_provider.dart';
import 'package:cond_manager/features/providers/presentation/providers/service_provider_providers.dart';
import 'package:cond_manager/features/providers/presentation/utils/provider_permissions.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/utils/ticket_work_order_bridge.dart';
import 'package:cond_manager/shared/domain/enums/location_type.dart';
import 'package:cond_manager/shared/domain/enums/priority_level.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorkOrderFormPage extends ConsumerStatefulWidget {
  const WorkOrderFormPage({
    super.key,
    this.initialTicketId,
    this.initialCondominiumId,
  });

  final String? initialTicketId;
  final String? initialCondominiumId;

  @override
  ConsumerState<WorkOrderFormPage> createState() => _WorkOrderFormPageState();
}

class _WorkOrderFormPageState extends ConsumerState<WorkOrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationDescController = TextEditingController();

  Condominium? _condominium;
  Ticket? _sourceTicket;
  TicketLinkOption? _linkedTicket;
  LocationType _locationType = LocationType.other;
  ServiceType _serviceType = ServiceType.other;
  PriorityLevel _priority = PriorityLevel.medium;
  WorkOrderAssigneeType _assigneeType = WorkOrderAssigneeType.none;
  InternalStaffOption? _internalStaff;
  ProviderPickerOption? _provider;
  UnitOption? _unit;
  CommonAreaOption? _commonArea;
  RentalProperty? _rentalProperty;
  String? _pendingUnitId;
  String? _pendingCommonAreaId;
  String? _requesterId;
  bool _isLoading = false;
  String? _error;

  bool get _ticketLinkLocked => widget.initialTicketId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialTicketId != null) {
      _linkedTicket = TicketLinkOption(
        id: widget.initialTicketId!,
        label: 'Chamado vinculado',
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationDescController.dispose();
    super.dispose();
  }

  void _applyTicket(Ticket ticket, List<Condominium> condos) {
    final draft = buildWorkOrderDraftFromTicket(ticket, condos);
    _sourceTicket = ticket;
    _condominium = draft.condominium;
    _linkedTicket = draft.linkedTicket;
    _titleController.text = draft.title;
    _descriptionController.text = draft.description;
    _serviceType = draft.serviceType;
    _priority = draft.priority;
    _locationType = draft.locationType;
    _locationDescController.text = draft.locationDescription;
    _requesterId = draft.requesterId;
    _pendingUnitId = draft.unitId;
    _pendingCommonAreaId = draft.commonAreaId;
    _unit = null;
    _commonArea = null;
    setState(() {});
  }

  Future<void> _onTicketLinkChanged(TicketLinkOption? option, List<Condominium> condos) async {
    if (option == null || option.id.isEmpty) {
      setState(() {
        _linkedTicket = null;
        _sourceTicket = null;
      });
      return;
    }
    setState(() => _linkedTicket = option);
    final result = await ref.read(ticketRepositoryProvider).getById(option.id);
    result.when(
      success: (ticket) {
        if (!mounted) return;
        _applyTicket(ticket, condos);
      },
      failure: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar chamado: ${e.message}')),
        );
      },
    );
  }

  void _resolveLocationOptions(
    List<UnitOption> units,
    List<CommonAreaOption> areas,
  ) {
    var changed = false;
    if (_pendingUnitId != null) {
      for (final u in units) {
        if (u.id == _pendingUnitId) {
          _unit = u;
          _pendingUnitId = null;
          changed = true;
          break;
        }
      }
    }
    if (_pendingCommonAreaId != null) {
      for (final a in areas) {
        if (a.id == _pendingCommonAreaId) {
          _commonArea = a;
          _pendingCommonAreaId = null;
          changed = true;
          break;
        }
      }
    }
    if (changed && mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_condominium == null) {
      setState(() => _error = 'Selecione o condomínio.');
      return;
    }
    if (_assigneeType == WorkOrderAssigneeType.internal && _internalStaff == null) {
      setState(() => _error = 'Selecione o funcionário responsável.');
      return;
    }
    if (_assigneeType == WorkOrderAssigneeType.provider && _provider == null) {
      setState(() => _error = 'Selecione o prestador de serviço.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final input = WorkOrderCreateInput(
      condominiumId: _condominium!.id,
      ticketId: _linkedTicket != null && _linkedTicket!.id.isNotEmpty
          ? _linkedTicket!.id
          : null,
      title: _titleController.text,
      description: _descriptionController.text,
      serviceType: _serviceType,
      priority: _priority,
      locationType: _locationType,
      locationDescription: _locationDescController.text,
      unitId: _locationType == LocationType.unit ? _unit?.id : null,
      commonAreaId: _locationType == LocationType.commonArea ? _commonArea?.id : null,
      requesterId: _requesterId,
      internalResponsibleId:
          _assigneeType == WorkOrderAssigneeType.internal ? _internalStaff?.profileId : null,
      providerId: _assigneeType == WorkOrderAssigneeType.provider ? _provider?.id : null,
      rentalPropertyId: _rentalProperty?.id,
    );

    final result = await ref.read(workOrderRepositoryProvider).create(input);

    if (!mounted) return;

    result.when(
      success: (wo) {
        ref.invalidate(workOrdersListProvider);
        if (_linkedTicket != null) {
          ref.invalidate(ticketDetailProvider(_linkedTicket!.id));
          ref.invalidate(ticketsListProvider);
        }
        context.go('/work-orders/${wo.id}');
      },
      failure: (e) => setState(() {
        _isLoading = false;
        _error = e.message;
      }),
    );
  }

  String get _returnPath =>
      resolveReturnPath(context, fallback: '/work-orders');

  void _openRegisterProvider(BuildContext context) {
    if (_condominium == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o condomínio antes de cadastrar o prestador.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final returnTo = GoRouterState.of(context).uri.toString();
    context.go(
      Uri(
        path: '/providers/new',
        queryParameters: {
          'condominiumId': _condominium!.id,
          'serviceType': _serviceType.value,
          'returnTo': returnTo,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canRegisterProvider =
        ref.watch(currentProfileProvider).value?.canCreateProvider ?? false;
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final condos = condosAsync.value ?? const <Condominium>[];
    final ticketFromRoute = widget.initialTicketId != null
        ? ref.watch(ticketDetailProvider(widget.initialTicketId!))
        : null;

    ref.listen(accessibleCondominiumsProvider, (prev, next) {
      if (_sourceTicket == null || _condominium != null) return;
      next.whenData((list) {
        if (list.isNotEmpty) _applyTicket(_sourceTicket!, list);
      });
    });

    if (widget.initialTicketId != null) {
      ref.listen(ticketDetailProvider(widget.initialTicketId!), (prev, next) {
        next.whenData((ticket) => _applyTicket(ticket, condos));
      });
      if (ticketFromRoute?.hasValue == true && _sourceTicket == null) {
        ticketFromRoute!.whenData((ticket) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _applyTicket(ticket, condos);
          });
        });
      }
    }

    if (widget.initialCondominiumId != null && _condominium == null && condos.isNotEmpty) {
      final match = condos.where((c) => c.id == widget.initialCondominiumId);
      if (match.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _condominium = match.first);
        });
      }
    }

    final condoId = _condominium?.id;
    final staffAsync = condoId != null
        ? ref.watch(workOrderInternalStaffProvider(condoId))
        : const AsyncValue<List<InternalStaffOption>>.data([]);
    final providerQuery = condoId != null
        ? ProviderPickerQuery(condominiumId: condoId, serviceType: _serviceType)
        : null;
    final providersAsync = providerQuery != null
        ? ref.watch(workOrderProviderPickerProvider(providerQuery))
        : const AsyncValue<List<ProviderPickerOption>>.data([]);
    final ticketsAsync = condoId != null
        ? ref.watch(workOrderLinkableTicketsProvider(condoId))
        : const AsyncValue<List<TicketLinkOption>>.data([]);
    final unitsAsync = condoId != null
        ? ref.watch(ticketUnitsProvider(condoId))
        : const AsyncValue<List<UnitOption>>.data([]);
    final areasAsync = condoId != null
        ? ref.watch(ticketCommonAreasProvider(condoId))
        : const AsyncValue<List<CommonAreaOption>>.data([]);

    if (condoId != null) {
      ref.listen(ticketUnitsProvider(condoId), (prev, next) {
        next.whenData((units) {
          final areas = ref.read(ticketCommonAreasProvider(condoId)).value;
          if (areas != null) _resolveLocationOptions(units, areas);
        });
      });
      ref.listen(ticketCommonAreasProvider(condoId), (prev, next) {
        next.whenData((areas) {
          final units = ref.read(ticketUnitsProvider(condoId)).value;
          if (units != null) _resolveLocationOptions(units, areas);
        });
      });
    }

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
                    ClaySurface(
                      depth: ClayDepth.raised,
                      radius: ClayTokens.radiusFull,
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => context.go(_returnPath),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nova ordem de serviço',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gere um número de OS e designe funcionário interno ou prestador.',
                  style: TextStyle(color: ClayTokens.textSecondary),
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  ClaySurface(
                    depth: ClayDepth.pressed,
                    color: ClayTokens.error.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(14),
                    child: Text(_error!, style: const TextStyle(color: ClayTokens.error)),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_sourceTicket != null) ...[
                  _LinkedTicketBanner(ticket: _sourceTicket!),
                  const SizedBox(height: 16),
                ],
                FormGridSection(
                  title: 'Vínculo e local',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: condosAsync.isLoading
                          ? const LinearProgressIndicator()
                          : _condominiumDropdown(condos),
                    ),
                    FormGridField(
                      span: 2,
                      child: RentalPropertyLinkField(
                        condominiumId: _condominium?.id,
                        value: _rentalProperty,
                        onChanged: (p) => setState(() => _rentalProperty = p),
                      ),
                    ),
                    FormGridField(
                      child: _ticketLinkLocked && _linkedTicket != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chamado vinculado',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: ClayTokens.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _linkedTicket!.label,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            )
                          : ticketsAsync.when(
                              data: (tickets) {
                                final items = [
                                  const TicketLinkOption(
                                    id: '',
                                    label: 'Sem chamado vinculado',
                                  ),
                                  ...tickets,
                                ];
                                final selected = _linkedTicket != null &&
                                        items.any((t) => t.id == _linkedTicket!.id)
                                    ? _linkedTicket
                                    : items.first;
                                return ClayDropdownField<TicketLinkOption>(
                                  label: 'Chamado (opcional)',
                                  hint: 'Vincular a um chamado',
                                  value: selected,
                                  items: items,
                                  itemLabel: (t) => t.label,
                                  onChanged: _ticketLinkLocked
                                      ? null
                                      : (v) => _onTicketLinkChanged(
                                            v?.id.isEmpty == true ? null : v,
                                            condos,
                                          ),
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<LocationType>(
                        label: 'Local *',
                        value: _locationType,
                        items: LocationType.values,
                        itemLabel: (e) => e.label,
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
                          data: (units) => ClayDropdownField<UnitOption>(
                            label: 'Unidade',
                            value: _unit,
                            items: units,
                            itemLabel: (u) => u.label,
                            onChanged: (v) => setState(() => _unit = v),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                    if (_locationType == LocationType.commonArea)
                      FormGridField(
                        child: areasAsync.when(
                          data: (areas) => ClayDropdownField<CommonAreaOption>(
                            label: 'Área comum',
                            value: _commonArea,
                            items: areas,
                            itemLabel: (a) => a.label,
                            onChanged: (v) => setState(() => _commonArea = v),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _locationDescController,
                        label: 'Detalhes do local',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Serviço',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayTextField(
                        controller: _titleController,
                        label: 'Título *',
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<ServiceType>(
                        label: 'Tipo de serviço *',
                        value: _serviceType,
                        items: ServiceType.values,
                        itemLabel: (e) => e.label,
                        onChanged: (v) => setState(() {
                          _serviceType = v ?? ServiceType.other;
                          _provider = null;
                        }),
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<PriorityLevel>(
                        label: 'Prioridade *',
                        value: _priority,
                        items: PriorityLevel.values,
                        itemLabel: (e) => e.label,
                        onChanged: (v) =>
                            setState(() => _priority = v ?? PriorityLevel.medium),
                      ),
                    ),
                    FormGridField(
                      span: columns,
                      child: ClayTextField(
                        controller: _descriptionController,
                        label: 'Descrição',
                        maxLines: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Responsável pela execução',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayDropdownField<WorkOrderAssigneeType>(
                        label: 'Tipo de responsável *',
                        value: _assigneeType,
                        items: WorkOrderAssigneeType.values,
                        itemLabel: (e) => e.label,
                        onChanged: (v) => setState(() {
                          _assigneeType = v ?? WorkOrderAssigneeType.none;
                          _internalStaff = null;
                          _provider = null;
                        }),
                      ),
                    ),
                    if (_assigneeType == WorkOrderAssigneeType.internal)
                      FormGridField(
                        child: staffAsync.when(
                          data: (staff) => ClayDropdownField<InternalStaffOption>(
                            label: 'Funcionário *',
                            hint: staff.isEmpty
                                ? 'Cadastre usuários na equipe do condomínio'
                                : 'Selecione',
                            value: _internalStaff,
                            items: staff,
                            itemLabel: (s) => '${s.fullName} (${s.roleLabel})',
                            validator: (v) => v == null ? 'Obrigatório' : null,
                            onChanged: (v) => setState(() => _internalStaff = v),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                    if (_assigneeType == WorkOrderAssigneeType.provider)
                      FormGridField(
                        child: providersAsync.when(
                          data: (providers) => _ProviderAssigneeField(
                            providers: providers,
                            serviceType: _serviceType,
                            selected: _provider,
                            canRegisterProvider: canRegisterProvider,
                            condominiumSelected: _condominium != null,
                            onChanged: (v) => setState(() => _provider = v),
                            onRegisterProvider: () => _openRegisterProvider(context),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 160,
                        child: ClayButton(
                          label: 'Cancelar',
                          variant: ClayButtonVariant.secondary,
                          onPressed: _isLoading ? null : () => context.go(_returnPath),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 220,
                        child: ClayButton(
                          label: _isLoading ? 'Salvando...' : 'Criar OS',
                          icon: Icons.check_rounded,
                          onPressed: _isLoading ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _condominiumDropdown(List<Condominium> condos) {
    if (_condominium == null && condos.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _condominium = condos.first);
      });
    }
    if (condos.isEmpty) {
      return ClayTextField(
        label: 'Condomínio *',
        hint: 'Nenhum condomínio disponível',
        validator: (_) => 'Cadastre um condomínio',
      );
    }
    return ClayDropdownField<Condominium>(
      label: 'Condomínio *',
      value: _condominium,
      items: condos,
      itemLabel: (c) => c.name,
      validator: (v) => v == null ? 'Obrigatório' : null,
      onChanged: (c) => setState(() {
        _condominium = c;
        _internalStaff = null;
        _provider = null;
        if (!_ticketLinkLocked) {
          _linkedTicket = null;
          _sourceTicket = null;
        }
        _unit = null;
        _commonArea = null;
        _rentalProperty = null;
      }),
    );
  }
}

class _ProviderAssigneeField extends StatelessWidget {
  const _ProviderAssigneeField({
    required this.providers,
    required this.serviceType,
    required this.selected,
    required this.canRegisterProvider,
    required this.condominiumSelected,
    required this.onChanged,
    required this.onRegisterProvider,
  });

  final List<ProviderPickerOption> providers;
  final ServiceType serviceType;
  final ProviderPickerOption? selected;
  final bool canRegisterProvider;
  final bool condominiumSelected;
  final ValueChanged<ProviderPickerOption?> onChanged;
  final VoidCallback onRegisterProvider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (providers.isEmpty) ...[
          ClaySurface(
            depth: ClayDepth.pressed,
            padding: const EdgeInsets.all(14),
            child: Text(
              'Nenhum prestador ativo para ${serviceType.label} neste condomínio.',
              style: const TextStyle(color: ClayTokens.textSecondary, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
        ] else
          ClayDropdownField<ProviderPickerOption>(
            label: 'Prestador *',
            hint: 'Selecione (${serviceType.label})',
            value: selected,
            items: providers,
            itemLabel: (p) => p.label,
            validator: (v) => v == null ? 'Obrigatório' : null,
            onChanged: onChanged,
          ),
        if (canRegisterProvider) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ClayButton(
              label: providers.isEmpty
                  ? 'Cadastrar prestador para ${serviceType.label}'
                  : 'Cadastrar novo prestador',
              variant: ClayButtonVariant.secondary,
              expand: false,
              icon: Icons.person_add_alt_1_rounded,
              onPressed: condominiumSelected ? onRegisterProvider : null,
            ),
          ),
          if (!condominiumSelected)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Selecione o condomínio para habilitar o cadastro.',
                style: TextStyle(fontSize: 12, color: ClayTokens.textMuted),
              ),
            ),
        ],
      ],
    );
  }
}

class _LinkedTicketBanner extends StatelessWidget {
  const _LinkedTicketBanner({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.raised,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, color: ClayTokens.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Dados importados do chamado ${ticket.displayNumber}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${ticket.id}',
            style: const TextStyle(fontSize: 11, color: ClayTokens.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (ticket.condominiumName != null) ticket.condominiumName!,
              ticket.serviceType.label,
              ticket.priority.label,
              ticket.locationType.label,
              if (ticket.requesterName != null) 'Solicitante: ${ticket.requesterName}',
            ].join(' · '),
            style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
