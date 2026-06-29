import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/rental_booking_channel.dart';
import 'package:cond_manager/shared/domain/enums/rental_booking_status.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RentalBookingFormPage extends ConsumerStatefulWidget {
  const RentalBookingFormPage({super.key, this.bookingId, this.initialPropertyId});

  final String? bookingId;
  final String? initialPropertyId;

  bool get isEditing => bookingId != null;

  @override
  ConsumerState<RentalBookingFormPage> createState() => _RentalBookingFormPageState();
}

class _RentalBookingFormPageState extends ConsumerState<RentalBookingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _guestNameController = TextEditingController();
  final _guestEmailController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _guestsCountController = TextEditingController(text: '1');
  final _nightlyRateController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _notesController = TextEditingController();

  RentalProperty? _property;
  RentalBookingChannel _channel = RentalBookingChannel.direct;
  RentalBookingStatus _status = RentalBookingStatus.reserved;
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;
  String? _error;
  bool _loaded = false;
  bool _initialPropertyApplied = false;

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPhoneController.dispose();
    _guestsCountController.dispose();
    _nightlyRateController.dispose();
    _totalAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  int _parseGuests(String text) {
    final v = int.tryParse(text.trim());
    return v != null && v > 0 ? v : 1;
  }

  int get _nights => _checkOut.difference(_checkIn).inDays;

  void _recalcTotal() {
    final nights = _nights;
    if (nights <= 0) return;
    final rate = _parse(_nightlyRateController.text);
    if (rate > 0) {
      _totalAmountController.text = (nights * rate).toStringAsFixed(2);
    }
  }

  void _applyInitialProperty(List<RentalProperty> properties) {
    final id = widget.initialPropertyId;
    if (id == null || _initialPropertyApplied) return;

    RentalProperty? match;
    for (final p in properties) {
      if (p.id == id) {
        match = p;
        break;
      }
    }
    if (match == null) return;

    _property = match;
    _initialPropertyApplied = true;
    final rate = match.baseDailyRate;
    if (rate != null && rate > 0) {
      _nightlyRateController.text = rate.toString();
      _recalcTotal();
    }
  }

  void _fill(RentalBooking b, List<RentalProperty> properties) {
    for (final p in properties) {
      if (p.id == b.propertyId) _property = p;
    }
    _guestNameController.text = b.guestName;
    _guestEmailController.text = b.guestEmail ?? '';
    ClayMaskedField.setPhone(_guestPhoneController, b.guestPhone);
    _guestsCountController.text = b.guestsCount.toString();
    _channel = b.channel;
    _status = b.status;
    _checkIn = b.checkIn;
    _checkOut = b.checkOut;
    if (b.nightlyRate != null) {
      _nightlyRateController.text = b.nightlyRate.toString();
    } else if (b.totalAmount != null && b.nights > 0) {
      _nightlyRateController.text = (b.totalAmount! / b.nights).toStringAsFixed(2);
    }
    if (b.totalAmount != null) {
      _totalAmountController.text = b.totalAmount.toString();
    }
    _notesController.text = b.notes ?? '';
    _loaded = true;
  }

  RentalBookingInput _buildInput(String companyId) => RentalBookingInput(
        companyId: companyId,
        propertyId: _property!.id,
        guestName: _guestNameController.text.trim(),
        guestEmail:
            _guestEmailController.text.trim().isEmpty ? null : _guestEmailController.text.trim(),
        guestPhone:
            _guestPhoneController.text.trim().isEmpty ? null : _guestPhoneController.text.trim(),
        guestsCount: _parseGuests(_guestsCountController.text),
        channel: _channel,
        status: _status,
        checkIn: _checkIn,
        checkOut: _checkOut,
        nightlyRate: _parse(_nightlyRateController.text) > 0 ? _parse(_nightlyRateController.text) : null,
        totalAmount:
            _parse(_totalAmountController.text) > 0 ? _parse(_totalAmountController.text) : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_property == null) {
      setState(() => _error = 'Selecione o imóvel.');
      return;
    }
    if (_nights <= 0) {
      setState(() => _error = 'Check-out deve ser após o check-in.');
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
      final result = await repo.updateBooking(widget.bookingId!, input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalBookingsListProvider);
          ref.invalidate(rentalGanttBookingsProvider);
          ref.invalidate(rentalBookingDetailProvider(widget.bookingId!));
          context.go(resolveReturnPath(context, fallback: '/rental/bookings'));
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final result = await repo.createBooking(input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalBookingsListProvider);
          ref.invalidate(rentalGanttBookingsProvider);
          context.go(resolveReturnPath(context, fallback: '/rental/bookings'));
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
    final properties = propertiesAsync.value ?? const <RentalProperty>[];

    if (widget.isEditing) {
      ref.watch(rentalBookingDetailProvider(widget.bookingId!)).whenData((b) {
        if (!_loaded && properties.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) setState(() => _fill(b, properties));
          });
        }
      });
    } else if (widget.initialPropertyId != null && !_initialPropertyApplied && properties.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_initialPropertyApplied) {
          setState(() => _applyInitialProperty(properties));
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
                            context.go(resolveReturnPath(context, fallback: '/rental/bookings')),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Editar reserva' : 'Nova reserva',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reserva de curta temporada com check-in, check-out e valores.',
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
                  title: 'Imóvel e hóspede',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: propertiesAsync.when(
                        data: (list) => ClayDropdownField<RentalProperty>(
                          label: 'Imóvel *',
                          value: _property,
                          items: list,
                          itemLabel: (p) => p.title,
                          onChanged: (v) => setState(() => _property = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _guestNameController,
                        label: 'Nome do hóspede *',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _guestEmailController,
                        label: 'E-mail do hóspede',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    FormGridField(
                      child: ClayMaskedField.phone(
                        controller: _guestPhoneController,
                        label: 'Telefone do hóspede',
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _guestsCountController,
                        label: 'Nº de hóspedes',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Período e canal',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: _RentalBookingDateTile(
                        label: 'Check-in *',
                        date: _checkIn,
                        onPick: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _checkIn,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _checkIn = picked;
                              if (!_checkOut.isAfter(_checkIn)) {
                                _checkOut = _checkIn.add(const Duration(days: 1));
                              }
                              _recalcTotal();
                            });
                          }
                        },
                      ),
                    ),
                    FormGridField(
                      child: _RentalBookingDateTile(
                        label: 'Check-out *',
                        date: _checkOut,
                        onPick: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _checkOut,
                            firstDate: _checkIn.add(const Duration(days: 1)),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _checkOut = picked;
                              _recalcTotal();
                            });
                          }
                        },
                      ),
                    ),
                    if (_nights > 0)
                      FormGridField(
                        child: ClaySurface(
                          depth: ClayDepth.pressed,
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            '$_nights noite${_nights == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ClayTokens.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    FormGridField(
                      child: ClayDropdownField<RentalBookingChannel>(
                        label: 'Canal',
                        value: _channel,
                        items: RentalBookingChannel.values,
                        itemLabel: (c) => c.label,
                        onChanged: (v) =>
                            setState(() => _channel = v ?? RentalBookingChannel.direct),
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<RentalBookingStatus>(
                        label: 'Status',
                        value: _status,
                        items: RentalBookingStatus.values,
                        itemLabel: (s) => s.label,
                        onChanged: (v) =>
                            setState(() => _status = v ?? RentalBookingStatus.reserved),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Valores',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayTextField(
                        controller: _nightlyRateController,
                        label: 'Diária (R\$)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(_recalcTotal),
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _totalAmountController,
                        label: 'Total (R\$)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

class _RentalBookingDateTile extends StatelessWidget {
  const _RentalBookingDateTile({
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
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
