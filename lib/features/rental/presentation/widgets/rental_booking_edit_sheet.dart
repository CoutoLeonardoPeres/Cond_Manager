import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_fixed_rent_calculator.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';
import 'package:cond_manager/shared/domain/enums/rental_booking_channel.dart';
import 'package:cond_manager/shared/domain/enums/rental_booking_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_type.dart';
import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Abre modal para editar reserva a partir do Gantt.
Future<void> showRentalBookingEditSheet(
  BuildContext context,
  WidgetRef ref, {
  required String bookingId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => RentalBookingEditSheet(bookingId: bookingId),
  );
}

class RentalBookingEditSheet extends ConsumerStatefulWidget {
  const RentalBookingEditSheet({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<RentalBookingEditSheet> createState() => _RentalBookingEditSheetState();
}

class _RentalBookingEditSheetState extends ConsumerState<RentalBookingEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _guestsCountController = TextEditingController();
  final _nightlyRateController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _paymentDueDayController = TextEditingController();
  final _notesController = TextEditingController();

  RentalParty? _guest;
  RentalBookingChannel _channel = RentalBookingChannel.direct;
  RentalBookingStatus _status = RentalBookingStatus.reserved;
  DateTime? _checkIn;
  DateTime? _checkOut;
  bool _isFixedRent = false;
  bool _createProportionalCharge = true;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  RentalBooking? _booking;

  @override
  void dispose() {
    _guestsCountController.dispose();
    _nightlyRateController.dispose();
    _totalAmountController.dispose();
    _monthlyRentController.dispose();
    _paymentDueDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  int _parseInt(String text) {
    final v = int.tryParse(text.trim());
    return v != null && v > 0 ? v : 0;
  }

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  int? get _dueDay {
    final day = _parseInt(_paymentDueDayController.text);
    return day >= 1 && day <= 28 ? day : null;
  }

  void _recalcNightlyTotal() {
    final nights = _nights;
    if (nights <= 0 || _isFixedRent) return;
    final rate = _parse(_nightlyRateController.text);
    if (rate > 0) {
      _totalAmountController.text = (nights * rate).toStringAsFixed(2);
    }
  }

  void _fill(RentalBooking booking, List<RentalParty> parties) {
    _booking = booking;
    _channel = booking.channel;
    _status = booking.status;
    _checkIn = rentalGanttDateOnly(booking.checkIn);
    _checkOut = rentalGanttDateOnly(booking.checkOut);
    _guestsCountController.text = booking.guestsCount.toString();
    _isFixedRent = booking.isFixedRent;
    if (booking.nightlyRate != null) {
      _nightlyRateController.text = booking.nightlyRate.toString();
    }
    if (booking.totalAmount != null) {
      _totalAmountController.text = booking.totalAmount.toString();
    }
    if (booking.monthlyRent != null) {
      _monthlyRentController.text = booking.monthlyRent.toString();
    }
    if (booking.paymentDueDay != null) {
      _paymentDueDayController.text = booking.paymentDueDay.toString();
    }
    _notesController.text = booking.notes ?? '';
    if (booking.guestPartyId != null) {
      for (final p in parties) {
        if (p.id == booking.guestPartyId) {
          _guest = p;
          break;
        }
      }
    }
    _loaded = true;
  }

  RentalBookingInput _buildInput(String companyId) => RentalBookingInput(
        companyId: companyId,
        propertyId: _booking!.propertyId,
        guestPartyId: _guest?.id,
        guestName: _guest?.fullName ?? _booking!.guestName,
        guestEmail: _guest?.email ?? _booking!.guestEmail,
        guestPhone: _guest?.phone ?? _booking!.guestPhone,
        guestsCount: _parseInt(_guestsCountController.text).clamp(1, 99),
        channel: _channel,
        status: _status,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        nightlyRate: !_isFixedRent && _parse(_nightlyRateController.text) > 0
            ? _parse(_nightlyRateController.text)
            : null,
        totalAmount: !_isFixedRent && _parse(_totalAmountController.text) > 0
            ? _parse(_totalAmountController.text)
            : (_isFixedRent ? _proportionalPreview?.amount : null),
        isFixedRent: _isFixedRent,
        monthlyRent: _isFixedRent && _parse(_monthlyRentController.text) > 0
            ? _parse(_monthlyRentController.text)
            : null,
        paymentDueDay: _isFixedRent ? _dueDay : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

  _ProportionalPreview? get _proportionalPreview {
    if (!_isFixedRent || _checkIn == null) return null;
    final monthly = _parse(_monthlyRentController.text);
    final dueDay = _dueDay;
    if (monthly <= 0 || dueDay == null) return null;

    final nextDue = RentalFixedRentCalculator.nextDueDate(_checkIn!, dueDay);
    final days = RentalFixedRentCalculator.daysUntilNextDue(_checkIn!, dueDay);
    final amount = RentalFixedRentCalculator.proportionalAmount(
      checkIn: _checkIn!,
      dueDayOfMonth: dueDay,
      monthlyRent: monthly,
    );

    return _ProportionalPreview(
      amount: amount,
      days: days,
      nextDueDate: nextDue,
      isFullMonth: days >= 28,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_guest == null && _booking!.guestName.trim().isEmpty) {
      setState(() => _error = 'Selecione o locatário/hóspede.');
      return;
    }
    if (_checkIn == null || _checkOut == null || _nights <= 0) {
      setState(() => _error = 'Check-out deve ser após o check-in.');
      return;
    }
    if (_isFixedRent) {
      if (_parse(_monthlyRentController.text) <= 0) {
        setState(() => _error = 'Informe o valor do aluguel fixo mensal.');
        return;
      }
      if (_dueDay == null) {
        setState(() => _error = 'Informe o dia de vencimento (1 a 28).');
        return;
      }
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
    final result = await repo.updateBooking(widget.bookingId, input);
    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(rentalBookingsListProvider);
        ref.invalidate(rentalGanttBookingsProvider);
        ref.invalidate(rentalBookingDetailProvider(widget.bookingId));
        _finishSave(companyId);
      },
      failure: (e) => setState(() {
        _loading = false;
        _error = e.message;
      }),
    );
  }

  Future<void> _finishSave(String companyId) async {
    if (_isFixedRent && _createProportionalCharge) {
      await _maybeCreateProportionalCharge(companyId);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reserva atualizada com sucesso.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _maybeCreateProportionalCharge(String companyId) async {
    final preview = _proportionalPreview;
    if (preview == null || preview.amount <= 0) return;

    final existing = await ref.read(rentalRepositoryProvider).listCharges(
          RentalChargeListFilter(bookingId: widget.bookingId),
        );
    final hasRentCharge = existing.when(
      success: (list) => list.any(
        (c) =>
            c.chargeType == RentalChargeType.rent &&
            c.status != RentalChargeStatus.cancelled,
      ),
      failure: (_) => true,
    );
    if (hasRentCharge) return;

    final dateFmt = DateFormat('dd/MM/yyyy');
    final description = preview.isFullMonth
        ? 'Aluguel fixo — ${_booking!.propertyTitle}'
        : 'Aluguel proporcional (${dateFmt.format(_checkIn!)} → ${dateFmt.format(preview.nextDueDate)})';

    await ref.read(rentalRepositoryProvider).createCharge(
          RentalChargeInput(
            companyId: companyId,
            bookingId: widget.bookingId,
            partyId: _guest?.id,
            chargeType: RentalChargeType.rent,
            status: RentalChargeStatus.pending,
            description: description,
            amount: preview.amount,
            dueDate: preview.nextDueDate,
            notes: 'Gerado automaticamente pela reserva.',
          ),
        );
    ref.invalidate(rentalChargesListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(rentalBookingDetailProvider(widget.bookingId));
    final partiesAsync = ref.watch(rentalPartiesListProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    bookingAsync.whenData((booking) {
      final parties = partiesAsync.value;
      if (!_loaded && parties != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_loaded) setState(() => _fill(booking, parties));
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
          child: bookingAsync.when(
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

              final preview = _proportionalPreview;

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
                        'Editar reserva',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _booking!.propertyTitle,
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
                          final guests =
                              parties.where((p) => p.category.canBeBookingGuest).toList();
                          if (_guest != null && !guests.any((p) => p.id == _guest!.id)) {
                            guests.insert(0, _guest!);
                          }
                          final dropdownValue =
                              _guest != null && guests.any((p) => p.id == _guest!.id)
                                  ? _guest
                                  : null;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClayDropdownField<RentalParty?>(
                                label: 'Locatário / hóspede *',
                                value: dropdownValue,
                                items: [null, ...guests],
                                itemLabel: (p) => p?.fullName ?? '—',
                                onChanged: (p) => setState(() => _guest = p),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () {
                                    final returnTo = GoRouterState.of(context).uri.toString();
                                    Navigator.of(context).pop();
                                    context.go(
                                      '/rental/parties/new?returnTo=$returnTo&category=${RentalPartyCategory.guest.value}',
                                    );
                                  },
                                  icon: const Icon(Icons.person_add_rounded, size: 18),
                                  label: const Text('Cadastrar pessoa'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ClayDropdownField<RentalBookingStatus>(
                        label: 'Status',
                        value: _status,
                        items: RentalBookingStatus.values,
                        itemLabel: (s) => s.label,
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickTile(
                              label: 'Check-in',
                              value: dateFmt.format(_checkIn!),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _checkIn!,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _checkIn = rentalGanttDateOnly(picked);
                                    if (_checkOut == null || !_checkOut!.isAfter(_checkIn!)) {
                                      _checkOut = _checkIn!.add(const Duration(days: 1));
                                    }
                                    _recalcNightlyTotal();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DatePickTile(
                              label: 'Check-out',
                              value: dateFmt.format(_checkOut!),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _checkOut!,
                                  firstDate: _checkIn!.add(const Duration(days: 1)),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _checkOut = rentalGanttDateOnly(picked);
                                    _recalcNightlyTotal();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClayDropdownField<RentalBookingChannel>(
                              label: 'Canal',
                              value: _channel,
                              items: RentalBookingChannel.values,
                              itemLabel: (c) => c.label,
                              onChanged: (v) {
                                if (v != null) setState(() => _channel = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClayTextField(
                              controller: _guestsCountController,
                              label: 'Nº hóspedes',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClaySurface(
                        depth: ClayDepth.pressed,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Aluguel fixo mensal',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              subtitle: const Text(
                                'Cobra valor mensal fixo com vencimento no dia informado.',
                                style: TextStyle(fontSize: 12, color: ClayTokens.textSecondary),
                              ),
                              value: _isFixedRent,
                              onChanged: (v) => setState(() => _isFixedRent = v),
                            ),
                            if (_isFixedRent) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: ClayTextField(
                                      controller: _monthlyRentController,
                                      label: 'Aluguel mensal (R\$) *',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ClayTextField(
                                      controller: _paymentDueDayController,
                                      label: 'Dia vencimento *',
                                      hint: '1–28',
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              if (preview != null) ...[
                                const SizedBox(height: 12),
                                ClaySurface(
                                  depth: ClayDepth.raised,
                                  color: ClayTokens.tertiary.withValues(alpha: 0.08),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preview.isFullMonth
                                            ? 'Próxima cobrança: valor integral'
                                            : 'Aluguel proporcional até o vencimento',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${currency.format(preview.amount)} — '
                                        '${preview.days} dia${preview.days == 1 ? '' : 's'} '
                                        '(até ${dateFmt.format(preview.nextDueDate)})',
                                        style: const TextStyle(
                                          color: ClayTokens.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: _createProportionalCharge,
                                  onChanged: (v) =>
                                      setState(() => _createProportionalCharge = v ?? true),
                                  title: const Text(
                                    'Registrar cobrança proporcional',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      if (!_isFixedRent) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClayTextField(
                                controller: _nightlyRateController,
                                label: 'Diária (R\$)',
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(_recalcNightlyTotal),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClayTextField(
                                controller: _totalAmountController,
                                label: 'Total (R\$)',
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      ClayTextField(
                        controller: _notesController,
                        label: 'Observações',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _loading ? null : () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClayButton(
                              label: 'Salvar',
                              icon: Icons.save_rounded,
                              isLoading: _loading,
                              onPressed: _loading ? null : _submit,
                            ),
                          ),
                        ],
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

class _ProportionalPreview {
  const _ProportionalPreview({
    required this.amount,
    required this.days,
    required this.nextDueDate,
    required this.isFullMonth,
  });

  final double amount;
  final int days;
  final DateTime nextDueDate;
  final bool isFullMonth;
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
