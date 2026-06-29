import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
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

/// Abre modal para criar reserva a partir de um clique no mapa Gantt.
Future<void> showRentalQuickBookingSheet(
  BuildContext context,
  WidgetRef ref, {
  required RentalProperty property,
  required DateTime checkIn,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => RentalQuickBookingSheet(
      property: property,
      initialCheckIn: rentalGanttDateOnly(checkIn),
    ),
  );
}

class RentalQuickBookingSheet extends ConsumerStatefulWidget {
  const RentalQuickBookingSheet({
    super.key,
    required this.property,
    required this.initialCheckIn,
  });

  final RentalProperty property;
  final DateTime initialCheckIn;

  @override
  ConsumerState<RentalQuickBookingSheet> createState() => _RentalQuickBookingSheetState();
}

class _RentalQuickBookingSheetState extends ConsumerState<RentalQuickBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _guestsCountController = TextEditingController(text: '1');
  final _nightlyRateController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _paymentDueDayController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _checkIn;
  late DateTime _checkOut;
  RentalParty? _guest;
  RentalBookingChannel _channel = RentalBookingChannel.direct;
  RentalBookingStatus _status = RentalBookingStatus.reserved;
  bool _isFixedRent = false;
  bool _registerProportionalCharge = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkIn = widget.initialCheckIn;
    _checkOut = _checkIn.add(const Duration(days: 1));
    if (widget.property.baseDailyRate != null) {
      _nightlyRateController.text = widget.property.baseDailyRate.toString();
      _recalcTotal();
    }
    if (widget.property.baseRentAmount != null) {
      _monthlyRentController.text = widget.property.baseRentAmount.toString();
    }
  }

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

  int get _nights => _checkOut.difference(_checkIn).inDays;

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  int _parseGuests(String text) {
    final v = int.tryParse(text.trim());
    return v != null && v > 0 ? v : 1;
  }

  int _parseInt(String text) {
    final v = int.tryParse(text.trim());
    return v != null && v > 0 ? v : 0;
  }

  int? get _dueDay {
    final day = _parseInt(_paymentDueDayController.text);
    return day >= 1 && day <= 28 ? day : null;
  }

  _ProportionalPreview? get _proportionalPreview {
    if (!_isFixedRent) return null;
    final monthly = _parse(_monthlyRentController.text);
    final dueDay = _dueDay;
    if (monthly <= 0 || dueDay == null) return null;

    final nextDue = RentalFixedRentCalculator.nextDueDate(_checkIn, dueDay);
    final days = RentalFixedRentCalculator.daysUntilNextDue(_checkIn, dueDay);
    final amount = RentalFixedRentCalculator.proportionalAmount(
      checkIn: _checkIn,
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

  void _recalcTotal() {
    if (_isFixedRent) return;
    final nights = _nights;
    if (nights <= 0) return;
    final rate = _parse(_nightlyRateController.text);
    if (rate > 0) {
      _totalAmountController.text = (nights * rate).toStringAsFixed(2);
    }
  }

  void _applyGuest(RentalParty? party) {
    setState(() => _guest = party);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_guest == null) {
      setState(() => _error = 'Selecione o locatário/hóspede.');
      return;
    }
    if (_nights <= 0) {
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

    final preview = _proportionalPreview;
    final input = RentalBookingInput(
      companyId: companyId,
      propertyId: widget.property.id,
      guestPartyId: _guest!.id,
      guestName: _guest!.fullName,
      guestEmail: _guest!.email,
      guestPhone: _guest!.phone,
      guestsCount: _parseGuests(_guestsCountController.text),
      channel: _channel,
      status: _status,
      checkIn: _checkIn,
      checkOut: _checkOut,
      nightlyRate: !_isFixedRent && _parse(_nightlyRateController.text) > 0
          ? _parse(_nightlyRateController.text)
          : null,
      totalAmount: !_isFixedRent && _parse(_totalAmountController.text) > 0
          ? _parse(_totalAmountController.text)
          : (preview != null ? preview.amount : null),
      isFixedRent: _isFixedRent,
      monthlyRent: _isFixedRent && _parse(_monthlyRentController.text) > 0
          ? _parse(_monthlyRentController.text)
          : null,
      paymentDueDay: _isFixedRent ? _dueDay : null,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final result = await ref.read(rentalRepositoryProvider).createBooking(input);
    if (!mounted) return;

    result.when(
      success: (booking) {
        ref.invalidate(rentalBookingsListProvider);
        ref.invalidate(rentalGanttBookingsProvider);
        _finishCreate(companyId, booking.id);
      },
      failure: (e) => setState(() {
        _loading = false;
        _error = e.message;
      }),
    );
  }

  Future<void> _finishCreate(String companyId, String bookingId) async {
    if (_isFixedRent && _registerProportionalCharge) {
      await _saveProportionalCharge(companyId, bookingId);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reserva criada com sucesso.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveProportionalCharge(String companyId, String bookingId) async {
    final preview = _proportionalPreview;
    if (preview == null || preview.amount <= 0) return;

    final dateFmt = DateFormat('dd/MM/yyyy');
    final description = preview.isFullMonth
        ? 'Aluguel fixo — ${widget.property.title}'
        : 'Aluguel proporcional (${dateFmt.format(_checkIn)} → ${dateFmt.format(preview.nextDueDate)})';

    await ref.read(rentalRepositoryProvider).createCharge(
          RentalChargeInput(
            companyId: companyId,
            bookingId: bookingId,
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
    final partiesAsync = ref.watch(rentalPartiesListProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final preview = _proportionalPreview;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClaySurface(
        depth: ClayDepth.raised,
        radius: ClayTokens.radiusLg,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          child: Form(
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
                    'Nova reserva',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.property.title,
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
                      final selectedInList =
                          _guest != null && guests.any((p) => p.id == _guest!.id);
                      final dropdownValue = selectedInList ? _guest : null;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClayDropdownField<RentalParty?>(
                            label: 'Locatário / hóspede *',
                            hint: guests.isEmpty
                                ? 'Cadastre uma pessoa em Locação → Pessoas'
                                : null,
                            value: dropdownValue,
                            items: [null, ...guests],
                            itemLabel: (p) => p?.fullName ?? '—',
                            onChanged: _applyGuest,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                final returnTo = GoRouterState.of(context).uri.toString();
                                final uri = Uri(
                                  path: '/rental/parties/new',
                                  queryParameters: {
                                    'returnTo': returnTo,
                                    'category': RentalPartyCategory.guest.value,
                                  },
                                );
                                Navigator.of(context).pop();
                                context.go(uri.toString());
                              },
                              icon: const Icon(Icons.person_add_rounded, size: 18),
                              label: const Text('Cadastrar pessoa agora'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickTile(
                          label: 'Check-in',
                          value: dateFmt.format(_checkIn),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _checkIn,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _checkIn = rentalGanttDateOnly(picked);
                                if (!_checkOut.isAfter(_checkIn)) {
                                  _checkOut = _checkIn.add(const Duration(days: 1));
                                }
                                _recalcTotal();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickTile(
                          label: 'Check-out',
                          value: dateFmt.format(_checkOut),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _checkOut,
                              firstDate: _checkIn.add(const Duration(days: 1)),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _checkOut = rentalGanttDateOnly(picked);
                                _recalcTotal();
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
                        child: ClayTextField(
                          controller: _guestsCountController,
                          label: 'Nº hóspedes',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                    ],
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
                              value: _registerProportionalCharge,
                              onChanged: (v) =>
                                  setState(() => _registerProportionalCharge = v ?? true),
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(_recalcTotal),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClayTextField(
                            controller: _totalAmountController,
                            label: 'Total (R\$)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                          label: 'Salvar reserva',
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
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClayTokens.textMuted),
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
