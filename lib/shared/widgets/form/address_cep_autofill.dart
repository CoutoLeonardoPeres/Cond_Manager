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
}

/// Busca ViaCEP ao completar 8 dígitos no campo CEP.
class AddressCepAutofill {
  AddressCepAutofill(
    this.fields, {
    this.onLoadingChanged,
    this.onFilled,
    this.onNotFound,
  });

  final AddressFields fields;
  final void Function(bool loading)? onLoadingChanged;
  final void Function()? onFilled;
  final void Function()? onNotFound;

  Timer? _debounce;
  int _lookupGeneration = 0;
  bool _loading = false;
  bool _paused = false;

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
    _debounce = Timer(const Duration(milliseconds: 450), _lookup);
  }

  Future<void> _lookup() async {
    if (_paused) return;

    final digits = BrazilianInputFormat.digitsOnly(fields.zip.text);
    if (digits.length != 8) return;

    final generation = ++_lookupGeneration;
    _setLoading(true);

    final result = await ViaCepService.lookup(digits);
    if (generation != _lookupGeneration) return;

    _setLoading(false);

    if (result == null) {
      onNotFound?.call();
      return;
    }

    if (result.street != null && result.street!.isNotEmpty) {
      fields.street.text = result.street!;
    }
    if (result.complement != null && result.complement!.isNotEmpty) {
      fields.complement.text = result.complement!;
    }
    if (result.neighborhood != null && result.neighborhood!.isNotEmpty) {
      fields.neighborhood.text = result.neighborhood!;
    }
    if (result.city != null && result.city!.isNotEmpty) {
      fields.city.text = result.city!;
    }
    if (result.state != null && result.state!.isNotEmpty) {
      fields.state.text = result.state!;
    }

    onFilled?.call();
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    onLoadingChanged?.call(value);
  }
}

/// Seção de endereço com o layout padrão (CEP | Logradouro | Número | Complemento / Bairro | Cidade | Estado).
Widget buildAddressFormSection({
  required String title,
  required AddressFields fields,
  bool cityRequired = false,
  bool stateRequired = false,
  String streetLabel = 'Logradouro',
  String zipLabel = 'CEP',
  bool cepLoading = false,
}) {
  return ClaySurface(
    depth: ClayDepth.raised,
    radius: ClayTokens.radiusLg,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: ClayTokens.primary,
          ),
        ),
        const SizedBox(height: 16),
        AddressFormLayout(
          fields: fields,
          cityRequired: cityRequired,
          stateRequired: stateRequired,
          streetLabel: streetLabel,
          zipLabel: zipLabel,
          cepLoading: cepLoading,
        ),
      ],
    ),
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
  });

  final AddressFields fields;
  final bool cityRequired;
  final bool stateRequired;
  final String streetLabel;
  final String zipLabel;
  final bool cepLoading;

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

  Widget? get _cepSuffix {
    if (!cepLoading) return null;
    return const SizedBox(
      width: 22,
      height: 22,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _cepField() => ClayMaskedField.cep(
        controller: fields.zip,
        label: zipLabel,
        hint: '00000-000',
        suffixIcon: _cepSuffix,
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
  });

  final AddressFields fields;
  final bool cityRequired;
  final bool stateRequired;
  final String streetLabel;
  final String zipLabel;
  final bool cepLoading;

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

/// @deprecated Use [buildAddressFormSection]. Mantido para compatibilidade.
int addressFormColumnsForWidth(double width) => 1;

/// @deprecated Use [buildAddressFormSection].
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
