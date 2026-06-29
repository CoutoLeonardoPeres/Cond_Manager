import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_type.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_charge_payment_dialog.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RentalChargeFormPage extends ConsumerStatefulWidget {
  const RentalChargeFormPage({super.key, this.chargeId});

  final String? chargeId;

  bool get isEditing => chargeId != null;

  @override
  ConsumerState<RentalChargeFormPage> createState() => _RentalChargeFormPageState();
}

class _RentalChargeFormPageState extends ConsumerState<RentalChargeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  RentalLease? _lease;
  RentalBooking? _booking;
  RentalChargeType _chargeType = RentalChargeType.rent;
  RentalChargeStatus _status = RentalChargeStatus.pending;
  DateTime? _dueDate;
  bool _loading = false;
  bool _markingPaid = false;
  String? _error;
  bool _loaded = false;
  bool _isPaid = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _fill(RentalCharge charge, List<RentalLease> leases, List<RentalBooking> bookings) {
    _descriptionController.text = charge.description;
    _amountController.text = charge.amount.toString();
    _notesController.text = charge.notes ?? '';
    _chargeType = charge.chargeType;
    _status = charge.status;
    _dueDate = charge.dueDate;
    _isPaid = charge.isPaid;
    for (final l in leases) {
      if (l.id == charge.leaseId) _lease = l;
    }
    for (final b in bookings) {
      if (b.id == charge.bookingId) _booking = b;
    }
    _loaded = true;
  }

  RentalChargeInput _buildInput(String companyId) => RentalChargeInput(
        companyId: companyId,
        leaseId: _lease?.id,
        bookingId: _booking?.id,
        chargeType: _chargeType,
        status: _status,
        description: _descriptionController.text.trim(),
        amount: _parse(_amountController.text),
        dueDate: _dueDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
      final result = await repo.updateCharge(widget.chargeId!, input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalChargesListProvider);
          ref.invalidate(rentalChargeDetailProvider(widget.chargeId!));
          context.go(resolveReturnPath(context, fallback: '/rental/charges'));
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final result = await repo.createCharge(input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalChargesListProvider);
          context.go(resolveReturnPath(context, fallback: '/rental/charges'));
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    }
  }

  Future<void> _markPaidAndSync() async {
    if (!widget.isEditing || _isPaid) return;

    final chargeResult = await ref.read(rentalRepositoryProvider).getCharge(widget.chargeId!);
    RentalCharge? charge;
    chargeResult.when(success: (c) => charge = c, failure: (_) {});
    if (charge == null || !mounted) return;

    final confirmation = await RentalChargePaymentDialog.show(context, charge: charge!);
    if (confirmation == null || !mounted) return;

    setState(() {
      _markingPaid = true;
      _error = null;
    });

    final result = await ref.read(rentalRepositoryProvider).markChargePaid(
          widget.chargeId!,
          paymentMethod: confirmation.paymentMethod,
          paidAmount: confirmation.paidAmount,
          paidAt: confirmation.paidAt,
          syncFinancial: true,
        );

    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(rentalChargesListProvider);
        ref.invalidate(rentalChargeDetailProvider(widget.chargeId!));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cobrança paga via ${confirmation.paymentMethod.label} e lançada no financeiro.',
            ),
          ),
        );
        context.go(resolveReturnPath(context, fallback: '/rental/charges'));
      },
      failure: (e) => setState(() {
        _markingPaid = false;
        _error = e.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leasesAsync = ref.watch(rentalLeasesListProvider);
    final bookingsAsync = ref.watch(rentalBookingsListProvider);
    final leases = leasesAsync.value ?? const <RentalLease>[];
    final bookings = bookingsAsync.value ?? const <RentalBooking>[];

    if (widget.isEditing) {
      ref.watch(rentalChargeDetailProvider(widget.chargeId!)).whenData((charge) {
        if (!_loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) setState(() => _fill(charge, leases, bookings));
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
                            context.go(resolveReturnPath(context, fallback: '/rental/charges')),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Editar cobrança' : 'Nova cobrança',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cobrança vinculada a contrato ou reserva, com opção de sincronizar ao financeiro.',
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
                      child: leasesAsync.when(
                        data: (list) => ClayDropdownField<RentalLease?>(
                          label: 'Contrato',
                          value: _lease,
                          items: [null, ...list],
                          itemLabel: (l) =>
                              l == null ? '—' : '${l.propertyTitle} · ${l.tenantName ?? '—'}',
                          onChanged: (v) => setState(() {
                            _lease = v;
                            if (v != null) _booking = null;
                          }),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    FormGridField(
                      child: bookingsAsync.when(
                        data: (list) => ClayDropdownField<RentalBooking?>(
                          label: 'Reserva',
                          value: _booking,
                          items: [null, ...list],
                          itemLabel: (b) =>
                              b == null ? '—' : '${b.propertyTitle} · ${b.guestName}',
                          onChanged: (v) => setState(() {
                            _booking = v;
                            if (v != null) _lease = null;
                          }),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Cobrança',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayDropdownField<RentalChargeType>(
                        label: 'Tipo',
                        value: _chargeType,
                        items: RentalChargeType.values,
                        itemLabel: (t) => t.label,
                        onChanged: (v) => setState(() => _chargeType = v ?? RentalChargeType.rent),
                      ),
                    ),
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
                      child: _RentalChargeDateTile(
                        label: 'Vencimento',
                        date: _dueDate,
                        onPick: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _dueDate = picked);
                        },
                      ),
                    ),
                    FormGridField(
                      span: columns,
                      child: ClayTextField(
                        controller: _descriptionController,
                        label: 'Descrição *',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<RentalChargeStatus>(
                        label: 'Status',
                        value: _status,
                        items: RentalChargeStatus.values,
                        itemLabel: (s) => s.label,
                        onChanged: (v) =>
                            setState(() => _status = v ?? RentalChargeStatus.pending),
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
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      if (widget.isEditing && !_isPaid)
                        SizedBox(
                          width: columns >= 3 ? 320 : double.infinity,
                          child: ClayButton(
                            label: 'Marcar pago e lançar no financeiro',
                            variant: ClayButtonVariant.secondary,
                            icon: Icons.payments_rounded,
                            isLoading: _markingPaid,
                            onPressed: _markingPaid || _loading ? null : _markPaidAndSync,
                          ),
                        ),
                      SizedBox(
                        width: columns >= 3 ? 220 : double.infinity,
                        child: ClayButton(
                          label: widget.isEditing ? 'Salvar' : 'Cadastrar',
                          icon: Icons.save_rounded,
                          isLoading: _loading,
                          onPressed: _loading || _markingPaid ? null : _submit,
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
}

class _RentalChargeDateTile extends StatelessWidget {
  const _RentalChargeDateTile({
    required this.label,
    required this.onPick,
    this.date,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final formatted = date != null
        ? '${date!.day.toString().padLeft(2, '0')}/'
            '${date!.month.toString().padLeft(2, '0')}/'
            '${date!.year}'
        : 'Selecionar';

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
