import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RentalLeaseFormPage extends ConsumerStatefulWidget {
  const RentalLeaseFormPage({super.key, this.leaseId});

  final String? leaseId;

  bool get isEditing => leaseId != null;

  @override
  ConsumerState<RentalLeaseFormPage> createState() => _RentalLeaseFormPageState();
}

class _RentalLeaseFormPageState extends ConsumerState<RentalLeaseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyRentController = TextEditingController();
  final _depositController = TextEditingController();
  final _dueDayController = TextEditingController();
  final _leaseNumberController = TextEditingController();
  final _notesController = TextEditingController();

  RentalProperty? _property;
  RentalParty? _tenant;
  RentalListingMode _listingMode = RentalListingMode.longTerm;
  RentalLeaseStatus _status = RentalLeaseStatus.draft;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _loading = false;
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _monthlyRentController.dispose();
    _depositController.dispose();
    _dueDayController.dispose();
    _leaseNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  int? _parseInt(String text) {
    final v = int.tryParse(text.trim());
    return v != null && v >= 1 && v <= 31 ? v : null;
  }

  void _fill(
    RentalLease lease,
    List<RentalProperty> properties,
    List<RentalParty> parties,
  ) {
    for (final p in properties) {
      if (p.id == lease.propertyId) _property = p;
    }
    for (final party in parties) {
      if (party.id == lease.primaryTenantPartyId) _tenant = party;
    }
    _listingMode = lease.listingMode;
    _status = lease.status;
    _startDate = lease.startDate;
    _endDate = lease.endDate;
    _monthlyRentController.text = lease.monthlyRent.toString();
    if (lease.depositAmount != null) _depositController.text = lease.depositAmount.toString();
    if (lease.dueDayOfMonth != null) _dueDayController.text = lease.dueDayOfMonth.toString();
    _leaseNumberController.text = lease.leaseNumber ?? '';
    _notesController.text = lease.notes ?? '';
    _loaded = true;
  }

  RentalLeaseInput _buildInput(String companyId) => RentalLeaseInput(
        companyId: companyId,
        propertyId: _property!.id,
        primaryTenantPartyId: _tenant?.id,
        leaseNumber: _leaseNumberController.text.trim().isEmpty
            ? null
            : _leaseNumberController.text.trim(),
        listingMode: _listingMode,
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
        monthlyRent: _parse(_monthlyRentController.text),
        depositAmount: _parse(_depositController.text) > 0 ? _parse(_depositController.text) : null,
        dueDayOfMonth: _parseInt(_dueDayController.text),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_property == null) {
      setState(() => _error = 'Selecione o imóvel.');
      return;
    }

    final companyId = ref.read(currentProfileProvider).value?.companyId;
    if (companyId == null) {
      setState(() => _error = 'Empresa não identificada.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(rentalRepositoryProvider);
    final input = _buildInput(companyId);

    if (widget.isEditing) {
      final result = await repo.updateLease(widget.leaseId!, input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalLeasesListProvider);
          ref.invalidate(rentalGanttLeasesProvider);
          ref.invalidate(rentalLeaseDetailProvider(widget.leaseId!));
          context.go(resolveReturnPath(context, fallback: '/rental/leases'));
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final result = await repo.createLease(input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalLeasesListProvider);
          ref.invalidate(rentalGanttLeasesProvider);
          context.go(resolveReturnPath(context, fallback: '/rental/leases'));
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
    final propertiesAsync = ref.watch(rentalPropertiesListProvider);
    final partiesAsync = ref.watch(rentalPartiesListProvider);
    final properties = propertiesAsync.value ?? const <RentalProperty>[];
    final parties = partiesAsync.value ?? const <RentalParty>[];

    if (widget.isEditing) {
      ref.watch(rentalLeaseDetailProvider(widget.leaseId!)).whenData((lease) {
        if (!_loaded && properties.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) setState(() => _fill(lease, properties, parties));
          });
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : formColumnsForWidth(constraints.maxWidth);

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
                            context.go(resolveReturnPath(context, fallback: '/rental/leases')),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Editar contrato' : 'Novo contrato',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contrato de locação de longo prazo vinculado a um imóvel e inquilino.',
                  style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
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
                  title: 'Vínculos',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: propertiesAsync.when(
                        data: (list) => ClayDropdownField<RentalProperty>(
                          label: 'Imóvel *',
                          value: _property,
                          items: list,
                          itemLabel: (p) => p.title,
                          onChanged: (v) => setState(() {
                            _property = v;
                            if (v != null) _listingMode = v.listingMode;
                          }),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    FormGridField(
                      child: partiesAsync.when(
                        data: (list) => ClayDropdownField<RentalParty?>(
                          label: 'Inquilino',
                          value: _tenant,
                          items: [null, ...list],
                          itemLabel: (p) => p?.fullName ?? '—',
                          onChanged: (v) => setState(() => _tenant = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Período e valores',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: _RentalDateTile(
                        label: 'Início *',
                        date: _startDate,
                        onPick: () async {
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
                      child: _RentalDateTile(
                        label: 'Término',
                        date: _endDate,
                        placeholder: 'Indeterminado',
                        onPick: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? _startDate,
                            firstDate: _startDate,
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _monthlyRentController,
                        label: 'Aluguel mensal (R\$) *',
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
                        controller: _depositController,
                        label: 'Caução (R\$)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _dueDayController,
                        label: 'Dia de vencimento',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<RentalLeaseStatus>(
                        label: 'Status',
                        value: _status,
                        items: RentalLeaseStatus.values,
                        itemLabel: (s) => s.label,
                        onChanged: (v) => setState(() => _status = v ?? RentalLeaseStatus.draft),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _leaseNumberController,
                        label: 'Número do contrato',
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
                    width: columns >= 3 ? 220 : double.infinity,
                    child: ClayButton(
                      label: widget.isEditing ? 'Salvar' : 'Cadastrar',
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

class _RentalDateTile extends StatelessWidget {
  const _RentalDateTile({
    required this.label,
    required this.onPick,
    this.date,
    this.placeholder = 'Selecionar',
  });

  final String label;
  final DateTime? date;
  final String placeholder;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final formatted = date != null
        ? '${date!.day.toString().padLeft(2, '0')}/'
            '${date!.month.toString().padLeft(2, '0')}/'
            '${date!.year}'
        : placeholder;

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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: date != null ? null : ClayTokens.textSecondary,
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
