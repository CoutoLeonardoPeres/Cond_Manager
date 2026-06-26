import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_property_link_field.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:cond_manager/shared/domain/enums/location_type.dart';
import 'package:cond_manager/shared/domain/enums/priority_level.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class TicketFormPage extends ConsumerStatefulWidget {
  const TicketFormPage({super.key});

  @override
  ConsumerState<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends ConsumerState<TicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationDescController = TextEditingController();
  final _picker = ImagePicker();

  Condominium? _condominium;
  LocationType _locationType = LocationType.other;
  ServiceType _serviceType = ServiceType.other;
  PriorityLevel _priority = PriorityLevel.medium;
  UnitOption? _unit;
  CommonAreaOption? _commonArea;
  RentalProperty? _rentalProperty;
  final List<PendingTicketFile> _pendingFiles = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationDescController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_pendingFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo de 5 fotos por chamado.')),
      );
      return;
    }
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;

    for (final file in images) {
      if (_pendingFiles.length >= 5) break;
      final bytes = await file.readAsBytes();
      final name = file.name;
      _pendingFiles.add(
        PendingTicketFile(
          bytes: bytes,
          fileName: name,
          mimeType: _mimeFromName(name),
        ),
      );
    }
    setState(() {});
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_condominium == null) {
      setState(() => _error = 'Selecione o condomínio para abrir o chamado.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final input = TicketCreateInput(
      condominiumId: _condominium!.id,
      locationType: _locationType,
      unitId: _locationType.requiresUnit ? _unit?.id : null,
      commonAreaId: _locationType == LocationType.commonArea ? _commonArea?.id : null,
      locationDescription: _locationDescController.text,
      rentalPropertyId: _rentalProperty?.id,
      serviceType: _serviceType,
      priority: _priority,
      title: _titleController.text,
      description: _descriptionController.text,
    );

    final repo = ref.read(ticketRepositoryProvider);
    final result = await repo.create(input, attachments: _pendingFiles);

    if (!mounted) return;

    result.when(
      success: (ticket) {
        ref.invalidate(ticketsListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chamado ${ticket.displayNumber} criado com sucesso!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/tickets/${ticket.id}');
      },
      failure: (e) => setState(() {
        _isLoading = false;
        _error = e.message;
      }),
    );
  }

  Widget _condominiumField(
    List<Condominium> condos,
    bool isPlatformAdmin, {
    bool loading = false,
  }) {
    if (loading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Condomínio *',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: ClayTokens.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(),
        ],
      );
    }

    if (_condominium == null && condos.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _condominium = condos.first);
      });
    }

    if (condos.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClayTextField(
            label: 'Condomínio *',
            hint: 'Nenhum condomínio cadastrado',
            validator: (_) => 'Cadastre ou selecione um condomínio',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  isPlatformAdmin
                      ? 'Cadastre um condomínio para vincular o chamado.'
                      : 'Peça ao administrador um condomínio vinculado à sua conta.',
                  style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary),
                ),
              ),
              if (isPlatformAdmin) ...[
                const SizedBox(width: 12),
                ClayButton(
                  label: 'Novo condomínio',
                  expand: false,
                  icon: Icons.add_rounded,
                  onPressed: () => goWithReturn(
                    context,
                    '/condominiums/new',
                    returnTo: '/tickets/new',
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return ClayDropdownField<Condominium>(
      label: 'Condomínio *',
      hint: 'Selecione',
      value: _condominium,
      items: condos,
      itemLabel: (c) => c.name,
      validator: (v) => v == null ? 'Obrigatório' : null,
      onChanged: (c) => setState(() {
        _condominium = c;
        _unit = null;
        _commonArea = null;
        _rentalProperty = null;
      }),
    );
  }

  List<FormGridField> _locationFields(
    List<Condominium> condos,
    bool isPlatformAdmin, {
    bool loadingCondos = false,
    required AsyncValue<List<UnitOption>> unitsAsync,
    required AsyncValue<List<CommonAreaOption>> areasAsync,
  }) {
    final items = <FormGridField>[
      FormGridField(
        child: _condominiumField(condos, isPlatformAdmin, loading: loadingCondos),
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
        child: ClayDropdownField<LocationType>(
          label: 'Local do problema *',
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
    ];

    if (_locationType.requiresUnit && _condominium != null) {
      items.add(
        FormGridField(
          child: unitsAsync.when(
            data: (units) => ClayDropdownField<UnitOption>(
              label: _locationType == LocationType.apartment ? 'Apartamento' : 'Unidade',
              hint: units.isEmpty
                  ? (_locationType == LocationType.apartment
                      ? 'Nenhum apartamento cadastrado'
                      : 'Nenhuma unidade cadastrada')
                  : 'Selecione',
              value: _unit,
              items: units,
              itemLabel: (u) => u.label,
              onChanged: (v) => setState(() => _unit = v),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    if (_locationType == LocationType.commonArea && _condominium != null) {
      items.add(
        FormGridField(
          child: areasAsync.when(
            data: (areas) => ClayDropdownField<CommonAreaOption>(
              label: 'Área comum',
              hint: areas.isEmpty ? 'Nenhuma área cadastrada' : 'Selecione',
              value: _commonArea,
              items: areas,
              itemLabel: (a) => a.label,
              onChanged: (v) => setState(() => _commonArea = v),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    items.add(
      FormGridField(
        child: ClayTextField(
          controller: _locationDescController,
          label: 'Detalhes do local',
          hint: 'Ex.: próximo ao elevador social',
        ),
      ),
    );

    return items;
  }

  Widget _buildForm({
    required int columns,
    required List<Condominium> condos,
    required bool isPlatformAdmin,
    required bool loadingCondos,
    required AsyncValue<List<UnitOption>> unitsAsync,
    required AsyncValue<List<CommonAreaOption>> areasAsync,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormGridSection(
          title: 'Localização',
          columns: columns,
          items: _locationFields(
            condos,
            isPlatformAdmin,
            loadingCondos: loadingCondos,
            unitsAsync: unitsAsync,
            areasAsync: areasAsync,
          ),
        ),
        const SizedBox(height: 16),
        FormGridSection(
          title: 'Classificação',
          columns: columns,
          items: [
            FormGridField(
              child: ClayDropdownField<ServiceType>(
                label: 'Tipo de serviço *',
                value: _serviceType,
                items: ServiceType.values,
                itemLabel: (e) => e.label,
                onChanged: (v) => setState(() => _serviceType = v ?? ServiceType.other),
              ),
            ),
            FormGridField(
              child: ClayDropdownField<PriorityLevel>(
                label: 'Prioridade *',
                value: _priority,
                items: PriorityLevel.values,
                itemLabel: (e) => e.label,
                onChanged: (v) => setState(() => _priority = v ?? PriorityLevel.medium),
              ),
            ),
            FormGridField(
              child: ClayTextField(
                controller: _titleController,
                label: 'Título *',
                hint: 'Resumo do problema',
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormGridSection(
          title: 'Descrição',
          columns: columns,
          items: [
            FormGridField(
              span: columns,
              child: ClayTextField(
                controller: _descriptionController,
                label: 'Descrição *',
                hint: 'Descreva o que aconteceu',
                maxLines: 5,
                validator: (v) =>
                    (v == null || v.trim().length < 10) ? 'Mínimo 10 caracteres' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormGridSection(
          title: 'Anexos',
          columns: columns,
          items: [
            FormGridField(
              span: columns,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fotos (${_pendingFiles.length}/5)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: ClayTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._pendingFiles.asMap().entries.map(
                        (e) => Chip(
                          label: Text(
                            e.value.fileName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: () => setState(() => _pendingFiles.removeAt(e.key)),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: const Text('Adicionar'),
                        onPressed: _isLoading ? null : _pickImages,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _FormActions(
          columns: columns,
          isLoading: _isLoading,
          onCancel: () => context.go('/tickets'),
          onSubmit: _submit,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final isPlatformAdmin = ref.watch(currentProfileProvider).value?.isPlatformAdmin == true;
    final unitsAsync = _condominium != null
        ? ref.watch(ticketUnitsProvider(_condominium!.id))
        : const AsyncValue<List<UnitOption>>.data([]);
    final areasAsync = _condominium != null
        ? ref.watch(ticketCommonAreasProvider(_condominium!.id))
        : const AsyncValue<List<CommonAreaOption>>.data([]);

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
                        onPressed: () => context.go('/tickets'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Abrir chamado',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Descreva o problema para a equipe de manutenção analisar.',
                  style: TextStyle(color: ClayTokens.textSecondary),
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  ClaySurface(
                    depth: ClayDepth.pressed,
                    color: ClayTokens.error.withValues(alpha: 0.1),
                    radius: ClayTokens.radiusSm,
                    padding: const EdgeInsets.all(14),
                    child: Text(_error!, style: const TextStyle(color: ClayTokens.error)),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildForm(
                  columns: columns,
                  condos: condosAsync.value ?? const [],
                  isPlatformAdmin: isPlatformAdmin,
                  loadingCondos: condosAsync.isLoading,
                  unitsAsync: unitsAsync,
                  areasAsync: areasAsync,
                ),
                if (condosAsync.hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Erro ao carregar condomínios: ${condosAsync.error}',
                    style: const TextStyle(color: ClayTokens.error, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClayButton(
                      label: 'Recarregar condomínios',
                      expand: false,
                      variant: ClayButtonVariant.secondary,
                      onPressed: () => ref.invalidate(accessibleCondominiumsProvider),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FormActions extends StatelessWidget {
  const _FormActions({
    required this.columns,
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
  });

  final int columns;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cancel = ClayButton(
      label: 'Cancelar',
      variant: ClayButtonVariant.secondary,
      onPressed: isLoading ? null : onCancel,
    );
    final submit = ClayButton(
      label: isLoading ? 'Enviando...' : 'Abrir chamado',
      icon: Icons.send_rounded,
      onPressed: isLoading ? null : onSubmit,
    );

    if (columns < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          submit,
          const SizedBox(height: 12),
          cancel,
        ],
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 160, child: cancel),
          const SizedBox(width: 12),
          SizedBox(width: 220, child: submit),
        ],
      ),
    );
  }
}
