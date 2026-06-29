import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

Future<void> showRentalLeaseEditSheet(
  BuildContext context,
  WidgetRef ref, {
  required String leaseId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => RentalLeaseEditSheet(leaseId: leaseId),
  );
}

class RentalLeaseEditSheet extends ConsumerStatefulWidget {
  const RentalLeaseEditSheet({super.key, required this.leaseId});

  final String leaseId;

  @override
  ConsumerState<RentalLeaseEditSheet> createState() => _RentalLeaseEditSheetState();
}

class _RentalLeaseEditSheetState extends ConsumerState<RentalLeaseEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyRentController = TextEditingController();
  final _dueDayController = TextEditingController();
  final _notesController = TextEditingController();
  final _terminationReasonController = TextEditingController();
  final _restrictionReasonController = TextEditingController();

  RentalParty? _tenant;
  RentalLeaseStatus _status = RentalLeaseStatus.active;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  DateTime _terminateEndDate = DateTime.now();
  bool _applyTenantRestriction = false;
  bool _showTerminateSection = false;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  RentalLease? _lease;

  @override
  void dispose() {
    _monthlyRentController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    _terminationReasonController.dispose();
    _restrictionReasonController.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  int? _parseInt(String text) {
    final v = int.tryParse(text.trim());
    return v != null && v >= 1 && v <= 28 ? v : null;
  }

  void _fill(RentalLease lease, List<RentalParty> parties) {
    _lease = lease;
    _status = lease.status;
    _startDate = rentalGanttDateOnly(lease.startDate);
    _endDate = lease.endDate != null ? rentalGanttDateOnly(lease.endDate!) : null;
    _terminateEndDate = _endDate ?? DateTime.now();
    _monthlyRentController.text = lease.monthlyRent.toString();
    if (lease.dueDayOfMonth != null) {
      _dueDayController.text = lease.dueDayOfMonth.toString();
    }
    _notesController.text = lease.notes ?? '';
    if (lease.terminationReason != null) {
      _terminationReasonController.text = lease.terminationReason!;
    }
    if (lease.primaryTenantPartyId != null) {
      for (final p in parties) {
        if (p.id == lease.primaryTenantPartyId) {
          _tenant = p;
          break;
        }
      }
    }
    _loaded = true;
  }

  RentalLeaseInput _buildInput(String companyId) => RentalLeaseInput(
        companyId: companyId,
        propertyId: _lease!.propertyId,
        primaryTenantPartyId: _tenant?.id,
        listingMode: _lease!.listingMode,
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
        monthlyRent: _parse(_monthlyRentController.text),
        dueDayOfMonth: _parseInt(_dueDayController.text),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

  void _invalidateAll() {
    ref.invalidate(rentalLeasesListProvider);
    ref.invalidate(rentalGanttLeasesProvider);
    ref.invalidate(rentalGanttBookingsProvider);
    ref.invalidate(rentalLeaseDetailProvider(widget.leaseId));
    ref.invalidate(rentalPartiesListProvider);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_parse(_monthlyRentController.text) <= 0) {
      setState(() => _error = 'Informe o valor do aluguel mensal.');
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

    final result = await ref
        .read(rentalRepositoryProvider)
        .updateLease(widget.leaseId, _buildInput(companyId));
    if (!mounted) return;

    result.when(
      success: (_) {
        _invalidateAll();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrato atualizado com sucesso.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      failure: (e) => setState(() {
        _loading = false;
        _error = e.message;
      }),
    );
  }

  Future<void> _terminate() async {
    if (_terminationReasonController.text.trim().isEmpty) {
      setState(() => _error = 'Informe o motivo do encerramento.');
      return;
    }
    if (_applyTenantRestriction && _restrictionReasonController.text.trim().isEmpty) {
      setState(() => _error = 'Informe o motivo da restrição ao locatário/inquilino.');
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

    final result = await ref.read(rentalRepositoryProvider).terminateLease(
          widget.leaseId,
          TerminateLeaseInput(
            endDate: rentalGanttDateOnly(_terminateEndDate),
            terminationReason: _terminationReasonController.text.trim(),
            applyTenantRestriction: _applyTenantRestriction,
            restrictionReason: _applyTenantRestriction
                ? _restrictionReasonController.text.trim()
                : null,
          ),
        );
    if (!mounted) return;

    result.when(
      success: (_) {
        _invalidateAll();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _applyTenantRestriction
                  ? 'Contrato encerrado e restrição aplicada.'
                  : 'Contrato encerrado com sucesso.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      failure: (e) => setState(() {
        _loading = false;
        _error = e.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaseAsync = ref.watch(rentalLeaseDetailProvider(widget.leaseId));
    final partiesAsync = ref.watch(rentalPartiesListProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isTerminated = _lease?.status == RentalLeaseStatus.terminated;

    leaseAsync.whenData((lease) {
      final parties = partiesAsync.value;
      if (!_loaded && parties != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_loaded) setState(() => _fill(lease, parties));
        });
      }
    });

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClaySurface(
        depth: ClayDepth.raised,
        radius: ClayTokens.radiusLg,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          child: leaseAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
            ),
            error: (e, _) => Text('$e'),
            data: (_) {
              if (!_loaded) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
                );
              }

              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ClayTokens.textMuted.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Editar contrato',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_lease!.propertyTitle}${_lease!.tenantName != null ? ' · ${_lease!.tenantName}' : ''}',
                        style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: ClayTokens.error)),
                      ],
                      const SizedBox(height: 16),
                      partiesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('$e'),
                        data: (parties) {
                          final tenants = parties
                              .where((p) => p.category.canBeLeaseTenant)
                              .toList();
                          if (_tenant != null && tenants.every((p) => p.id != _tenant!.id)) {
                            tenants.insert(0, _tenant!);
                          }
                          return ClaySearchableDropdownField<RentalParty>(
                            label: 'Inquilino / Locatário',
                            hint: 'Digite o nome para buscar…',
                            value: _tenant,
                            items: tenants,
                            itemLabel: (p) {
                              if (p.isRentalRestricted) {
                                return '${p.fullName} (restrito)';
                              }
                              return p.fullName;
                            },
                            onChanged: isTerminated ? (_) {} : (v) => setState(() => _tenant = v),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ClayDropdownField<RentalLeaseStatus>(
                        label: 'Status',
                        value: _status,
                        items: RentalLeaseStatus.values,
                        itemLabel: (s) => s.label,
                        onChanged: isTerminated
                            ? null
                            : (v) => setState(() => _status = v ?? RentalLeaseStatus.active),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickTile(
                              label: 'Início',
                              value: dateFmt.format(_startDate),
                              onTap: isTerminated
                                  ? () {}
                                  : () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setState(() => _startDate = rentalGanttDateOnly(picked));
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DatePickTile(
                              label: 'Término',
                              value: _endDate != null ? dateFmt.format(_endDate!) : 'Indeterminado',
                              onTap: isTerminated
                                  ? () {}
                                  : () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _endDate ?? _startDate,
                                        firstDate: _startDate,
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setState(() => _endDate = rentalGanttDateOnly(picked));
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClayTextField(
                        controller: _monthlyRentController,
                        label: 'Aluguel mensal (R\$) *',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        readOnly: isTerminated,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obrigatório';
                          if (_parse(v) <= 0) return 'Valor inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      ClayTextField(
                        controller: _dueDayController,
                        label: 'Dia de vencimento (1–28)',
                        keyboardType: TextInputType.number,
                        readOnly: isTerminated,
                      ),
                      const SizedBox(height: 12),
                      ClayTextField(
                        controller: _notesController,
                        label: 'Observações',
                        maxLines: 2,
                        readOnly: isTerminated,
                      ),
                      if (!isTerminated) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ClayButton(
                                label: 'Salvar',
                                icon: Icons.save_rounded,
                                isLoading: _loading && !_showTerminateSection,
                                onPressed: _loading ? null : _submit,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () => setState(
                                        () => _showTerminateSection = !_showTerminateSection,
                                      ),
                              icon: Icon(
                                _showTerminateSection
                                    ? Icons.expand_less_rounded
                                    : Icons.gavel_rounded,
                                size: 18,
                              ),
                              label: Text(_showTerminateSection ? 'Ocultar' : 'Encerrar'),
                              style: TextButton.styleFrom(foregroundColor: ClayTokens.error),
                            ),
                          ],
                        ),
                        if (_showTerminateSection) ...[
                          const SizedBox(height: 16),
                          ClaySurface(
                            depth: ClayDepth.pressed,
                            color: ClayTokens.error.withValues(alpha: 0.06),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Encerrar contrato',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'O contrato será marcado como encerrado e sairá do Gantt.',
                                  style: TextStyle(
                                    color: ClayTokens.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _DatePickTile(
                                  label: 'Data de encerramento',
                                  value: dateFmt.format(_terminateEndDate),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _terminateEndDate,
                                      firstDate: _startDate,
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(
                                        () => _terminateEndDate = rentalGanttDateOnly(picked),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                ClayTextField(
                                  controller: _terminationReasonController,
                                  label: 'Motivo do encerramento *',
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  value: _applyTenantRestriction,
                                  onChanged: (v) =>
                                      setState(() => _applyTenantRestriction = v ?? false),
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: const Text(
                                    'Aplicar restrição ao locatário/inquilino',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: const Text(
                                    'Impede novos contratos com esta pessoa sem revisão.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                if (_applyTenantRestriction) ...[
                                  const SizedBox(height: 8),
                                  ClayTextField(
                                    controller: _restrictionReasonController,
                                    label: 'Motivo da restrição *',
                                    maxLines: 2,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                ClayButton(
                                  label: 'Confirmar encerramento',
                                  icon: Icons.block_rounded,
                                  isLoading: _loading,
                                  onPressed: _loading ? null : _terminate,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...[
                        const SizedBox(height: 16),
                        ClaySurface(
                          depth: ClayDepth.pressed,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contrato encerrado',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              if (_lease!.terminationReason != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Motivo: ${_lease!.terminationReason}',
                                  style: const TextStyle(
                                    color: ClayTokens.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/rental/leases/${widget.leaseId}/edit');
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Abrir formulário completo'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DatePickTile extends StatelessWidget {
  const _DatePickTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
      child: ClaySurface(
        depth: ClayDepth.pressed,
        radius: ClayTokens.radiusSm,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ClayTokens.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
