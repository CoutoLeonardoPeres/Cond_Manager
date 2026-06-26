import 'dart:async';

import 'package:cond_manager/core/formatters/brazilian_input_format.dart';
import 'package:cond_manager/core/services/viacep_service.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:cond_manager/shared/widgets/clay/clay_surface.dart';
import 'package:cond_manager/shared/widgets/form/clay_form_grid.dart';
import 'package:flutter/material.dart';

/// Controllers de um bloco de endereço (padrão visual unificado).
class AddressFields {
  AddressFields({
    required this.zip,
    required this.street,
    required this.number,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  final TextEditingController zip;
  final TextEditingController street;
  final TextEditingController number;
  final TextEditingController complement;
  final TextEditingController neighborhood;
  final TextEditingController city;
  final TextEditingController state;

  AddressCepAutofill? _autofill;

  void _bind(AddressCepAutofill autofill) => _autofill = autofill;

  void pauseCepLookup() => _autofill?.pause();

  void resumeCepLookup() => _autofill?.resume();

  Future<void> lookupCepNow() => _autofill?.lookupNow() ?? Future.value();
}

/// Busca endereço na base dos Correios (via ViaCEP) ao completar 8 dígitos no CEP.
class AddressCepAutofill {
  AddressCepAutofill(
    this.fields, {
    this.onLoadingChanged,
    this.onFilled,
    this.onNotFound,
    this.onError,
  }) {
    fields._bind(this);
  }

  final AddressFields fields;
  final void Function(bool loading)? onLoadingChanged;
  final void Function()? onFilled;
  final void Function()? onNotFound;
  final void Function(String message)? onError;

  Timer? _debounce;
  int _lookupGeneration = 0;
  bool _loading = false;
  bool _paused = false;
  String? _lastLookedUpCep;

  bool get isLoading => _loading;

  void attach() => fields.zip.addListener(_onZipChanged);

  void detach() {
    _debounce?.cancel();
    fields.zip.removeListener(_onZipChanged);
  }

  void pause() => _paused = true;

  void resume() => _paused = false;

  void _onZipChanged() {
    _debounce?.cancel();
    final digits = BrazilianInputFormat.digitsOnly(fields.zip.text);
    if (digits.length < 8) {
      _lastLookedUpCep = null;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => lookupNow());
  }

  /// Dispara busca manual ou automática (Correios / ViaCEP).
  Future<void> lookupNow() async {
    if (_paused) return;

    final digits = BrazilianInputFormat.digitsOnly(fields.zip.text);
    if (digits.length != 8) return;
    if (_lastLookedUpCep == digits && !_loading) return;

    final generation = ++_lookupGeneration;
    _setLoading(true);

    final result = await ViaCepService.lookup(digits);
    if (generation != _lookupGeneration) return;

    _setLoading(false);

    if (result == null) {
      _lastLookedUpCep = null;
      onNotFound?.call();
      onError?.call('CEP não encontrado na base dos Correios.');
      return;
    }

    _lastLookedUpCep = digits;
    _apply(result);
    onFilled?.call();
  }

  void _apply(ViaCepAddress result) {
    _setText(fields.street, result.street);
    if (result.complement != null && result.complement!.isNotEmpty) {
      _setText(fields.complement, result.complement);
    }
    _setText(fields.neighborhood, result.neighborhood);
    _setText(fields.city, result.city);
    _setText(fields.state, result.state);
  }

  void _setText(TextEditingController controller, String? value) {
    if (value == null || value.isEmpty) return;
    controller.text = value;
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    onLoadingChanged?.call(value);
  }
}

/// Seção de endereço com busca automática de CEP (Correios).
class AddressFormSection extends StatefulWidget {
  const AddressFormSection({
    super.key,
    required this.title,
    required this.fields,
    this.cityRequired = false,
    this.stateRequired = false,
    this.streetLabel = 'Logradouro',
    this.zipLabel = 'CEP',
    this.onCepNotFound,
    this.onCepFilled,
    this.showCepFeedback = true,
  });

  final String title;
  final AddressFields fields;
  final bool cityRequired;
  final bool stateRequired;
  final String streetLabel;
  final String zipLabel;
  final VoidCallback? onCepNotFound;
  final VoidCallback? onCepFilled;
  final bool showCepFeedback;

  @override
  State<AddressFormSection> createState() => _AddressFormSectionState();
}

class _AddressFormSectionState extends State<AddressFormSection> {
  late final AddressCepAutofill _autofill;
  bool _cepLoading = false;

  @override
  void initState() {
    super.initState();
    _autofill = AddressCepAutofill(
      widget.fields,
      onLoadingChanged: (v) => setState(() => _cepLoading = v),
      onNotFound: () {
        widget.onCepNotFound?.call();
        if (widget.showCepFeedback && mounted) {
          _showSnack('CEP não encontrado na base dos Correios.', isError: true);
        }
      },
      onFilled: () {
        widget.onCepFilled?.call();
        if (widget.showCepFeedback && mounted) {
          _showSnack('Endereço preenchido automaticamente.');
        }
      },
    );
    _autofill.attach();
  }

  @override
  void dispose() {
    _autofill.detach();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? ClayTokens.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.raised,
      radius: ClayTokens.radiusLg,
      padding: EdgeInsets.all(ClayTokens.gap(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ClayTokens.accent,
                ),
          ),
          SizedBox(height: ClayTokens.gap(14)),
          AddressFormLayout(
            fields: widget.fields,
            cityRequired: widget.cityRequired,
            stateRequired: widget.stateRequired,
            streetLabel: widget.streetLabel,
            zipLabel: widget.zipLabel,
            cepLoading: _cepLoading,
            onCepSearch: _autofill.lookupNow,
          ),
        ],
      ),
    );
  }
}

/// Atalho — prefira [AddressFormSection].
Widget buildAddressFormSection({
  required String title,
  required AddressFields fields,
  bool cityRequired = false,
  bool stateRequired = false,
  String streetLabel = 'Logradouro',
  String zipLabel = 'CEP',
  VoidCallback? onCepNotFound,
  bool showCepFeedback = true,
}) {
  return AddressFormSection(
    title: title,
    fields: fields,
    cityRequired: cityRequired,
    stateRequired: stateRequired,
    streetLabel: streetLabel,
    zipLabel: zipLabel,
    onCepNotFound: onCepNotFound,
    showCepFeedback: showCepFeedback,
  );
}

/// Layout padrão de endereço em duas linhas (proporções da referência visual).
class AddressFormLayout extends StatelessWidget {
  const AddressFormLayout({
    super.key,
    required this.fields,
    this.cityRequired = false,
    this.stateRequired = false,
    this.streetLabel = 'Logradouro',
    this.zipLabel = 'CEP',
    this.cepLoading = false,
    this.onCepSearch,
  });

  final AddressFields fields;
  final bool cityRequired;
  final bool stateRequired;
  final String streetLabel;
  final String zipLabel;
  final bool cepLoading;
  final Future<void> Function()? onCepSearch;

  static const _gap = 12.0;
  static const _rowGap = 14.0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;

    if (!wide) {
      return _MobileLayout(
        fields: fields,
        cityRequired: cityRequired,
        stateRequired: stateRequired,
        streetLabel: streetLabel,
        zipLabel: zipLabel,
        cepLoading: cepLoading,
        onCepSearch: onCepSearch,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 15, child: _cepField()),
            const SizedBox(width: _gap),
            Expanded(flex: 45, child: _streetField()),
            const SizedBox(width: _gap),
            Expanded(flex: 12, child: _numberField()),
            const SizedBox(width: _gap),
            Expanded(flex: 28, child: _complementField()),
          ],
        ),
        const SizedBox(height: _rowGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 40, child: _neighborhoodField()),
            const SizedBox(width: _gap),
            Expanded(flex: 45, child: _cityField()),
            const SizedBox(width: _gap),
            Expanded(flex: 15, child: _stateField()),
          ],
        ),
      ],
    );
  }

  Widget _cepSuffix() {
    if (cepLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (onCepSearch == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Buscar CEP nos Correios',
      icon: const Icon(Icons.search_rounded, size: 20),
      color: ClayTokens.accent,
      onPressed: () => onCepSearch!(),
    );
  }

  Widget _cepField() => ClayMaskedField.cep(
        controller: fields.zip,
        label: zipLabel,
        hint: '00000-000',
        suffixIcon: _cepSuffix(),
        onComplete: onCepSearch,
      );

  Widget _streetField() => ClayTextField(
        controller: fields.street,
        label: streetLabel,
      );

  Widget _numberField() => ClayTextField(
        controller: fields.number,
        label: 'Número',
      );

  Widget _complementField() => ClayTextField(
        controller: fields.complement,
        label: 'Complemento',
      );

  Widget _neighborhoodField() => ClayTextField(
        controller: fields.neighborhood,
        label: 'Bairro',
      );

  Widget _cityField() => ClayTextField(
        controller: fields.city,
        label: cityRequired ? 'Cidade *' : 'Cidade',
        validator: cityRequired
            ? (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null
            : null,
      );

  Widget _stateField() => ClayTextField(
        controller: fields.state,
        label: stateRequired ? 'Estado *' : 'Estado',
        validator: stateRequired
            ? (v) {
                if (v == null || v.trim().isEmpty) return 'Obrigatório';
                if (v.trim().length != 2) return '2 letras';
                return null;
              }
            : null,
        onChanged: (v) {
          final upper = v.toUpperCase();
          if (upper != v) {
            fields.state.value = fields.state.value.copyWith(
              text: upper,
              selection: TextSelection.collapsed(offset: upper.length),
            );
          }
        },
      );
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.fields,
    required this.cityRequired,
    required this.stateRequired,
    required this.streetLabel,
    required this.zipLabel,
    required this.cepLoading,
    this.onCepSearch,
  });

  final AddressFields fields;
  final bool cityRequired;
  final bool stateRequired;
  final String streetLabel;
  final String zipLabel;
  final bool cepLoading;
  final Future<void> Function()? onCepSearch;

  @override
  Widget build(BuildContext context) {
    Widget? cepSuffix;
    if (cepLoading) {
      cepSuffix = const SizedBox(
        width: 22,
        height: 22,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (onCepSearch != null) {
      cepSuffix = IconButton(
        tooltip: 'Buscar CEP nos Correios',
        icon: const Icon(Icons.search_rounded, size: 20),
        color: ClayTokens.accent,
        onPressed: () => onCepSearch!(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClayMaskedField.cep(
                controller: fields.zip,
                label: zipLabel,
                hint: '00000-000',
                suffixIcon: cepSuffix,
                onComplete: onCepSearch,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ClayTextField(
                controller: fields.street,
                label: streetLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClayTextField(
                controller: fields.number,
                label: 'Número',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClayTextField(
                controller: fields.complement,
                label: 'Complemento',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClayTextField(
          controller: fields.neighborhood,
          label: 'Bairro',
        ),
        const SizedBox(height: 12),
        ClayTextField(
          controller: fields.city,
          label: cityRequired ? 'Cidade *' : 'Cidade',
          validator: cityRequired
              ? (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null
              : null,
        ),
        const SizedBox(height: 12),
        ClayTextField(
          controller: fields.state,
          label: stateRequired ? 'Estado *' : 'Estado',
          validator: stateRequired
              ? (v) {
                  if (v == null || v.trim().isEmpty) return 'Obrigatório';
                  if (v.trim().length != 2) return '2 letras';
                  return null;
                }
              : null,
          onChanged: (v) {
            final upper = v.toUpperCase();
            if (upper != v) {
              fields.state.value = fields.state.value.copyWith(
                text: upper,
                selection: TextSelection.collapsed(offset: upper.length),
              );
            }
          },
        ),
      ],
    );
  }
}

/// @deprecated Use [AddressFormSection]. Mantido para compatibilidade.
int addressFormColumnsForWidth(double width) => 1;

/// @deprecated Use [AddressFormSection].
List<FormGridField> buildAddressFormGrid({
  required AddressFields fields,
  required int columns,
  bool cityRequired = false,
  bool stateRequired = false,
  String streetLabel = 'Logradouro',
  String zipLabel = 'CEP',
  bool cepLoading = false,
}) {
  return [
    FormGridField(
      span: 1,
      child: AddressFormLayout(
        fields: fields,
        cityRequired: cityRequired,
        stateRequired: stateRequired,
        streetLabel: streetLabel,
        zipLabel: zipLabel,
        cepLoading: cepLoading,
      ),
    ),
  ];
}
