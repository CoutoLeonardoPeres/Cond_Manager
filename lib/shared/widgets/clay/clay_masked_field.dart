import 'package:cond_manager/core/formatters/brazilian_input_format.dart';
import 'package:cond_manager/core/formatters/brazilian_mask_formatters.dart';
import 'package:cond_manager/shared/widgets/clay/clay_text_field.dart';
import 'package:flutter/material.dart';

/// Campos com máscara brasileira padronizada.
class ClayMaskedField {
  ClayMaskedField._();

  static ClayTextField phone({
    required TextEditingController controller,
    String? label,
    String? hint,
    bool required = false,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return ClayTextField(
      controller: controller,
      label: label,
      hint: hint ?? '(00) 00000-0000',
      keyboardType: TextInputType.phone,
      readOnly: readOnly,
      inputFormatters: [PhoneMaskFormatter()],
      validator: validator ??
          (required ? (v) => BrazilianValidators.phone(v, required: true) : null),
    );
  }

  static ClayTextField cpf({
    required TextEditingController controller,
    String? label,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return ClayTextField(
      controller: controller,
      label: label,
      hint: '000.000.000-00',
      keyboardType: TextInputType.number,
      inputFormatters: [CpfMaskFormatter()],
      validator: validator ??
          (required ? (v) => BrazilianValidators.cpf(v, required: true) : null),
    );
  }

  static ClayTextField cnpj({
    required TextEditingController controller,
    String? label,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return ClayTextField(
      controller: controller,
      label: label,
      hint: '00.000.000/0000-00',
      keyboardType: TextInputType.number,
      inputFormatters: [CnpjMaskFormatter()],
      validator: validator ??
          (required ? (v) => BrazilianValidators.cnpj(v, required: true) : null),
    );
  }

  static ClayTextField cep({
    required TextEditingController controller,
    String? label,
    String? hint,
    Widget? suffixIcon,
    bool required = false,
    String? Function(String?)? validator,
    Future<void> Function()? onComplete,
  }) {
    return ClayTextField(
      controller: controller,
      label: label,
      hint: hint ?? '00000-000',
      suffixIcon: suffixIcon,
      keyboardType: TextInputType.number,
      inputFormatters: [CepMaskFormatter()],
      validator: validator ??
          (required ? (v) => BrazilianValidators.cep(v, required: true) : null),
      onChanged: (value) {
        final digits = BrazilianInputFormat.digitsOnly(value);
        if (digits.length == 8) {
          onComplete?.call();
        }
      },
    );
  }

  static ClayTextField document({
    required TextEditingController controller,
    required bool isCnpj,
    String? label,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return ClayTextField(
      key: ValueKey('doc-$isCnpj'),
      controller: controller,
      label: label,
      hint: isCnpj ? '00.000.000/0000-00' : '000.000.000-00',
      keyboardType: TextInputType.number,
      inputFormatters: [DocumentMaskFormatter(isCnpj: isCnpj)],
      validator: validator ??
          (required
              ? (v) => BrazilianValidators.document(v, isCnpj: isCnpj, required: true)
              : null),
    );
  }

  /// Aplica máscara ao preencher formulário com dados do banco.
  static void setPhone(TextEditingController c, String? value) {
    c.text = BrazilianInputFormat.formatPhone(value ?? '');
  }

  static void setCpf(TextEditingController c, String? value) {
    c.text = BrazilianInputFormat.formatCpf(value ?? '');
  }

  static void setCnpj(TextEditingController c, String? value) {
    c.text = BrazilianInputFormat.formatCnpj(value ?? '');
  }

  static void setCep(TextEditingController c, String? value) {
    c.text = BrazilianInputFormat.formatCep(value ?? '');
  }

  static void setDocument(
    TextEditingController c,
    String? value, {
    required bool isCnpj,
  }) {
    c.text = BrazilianInputFormat.formatDocument(value ?? '', isCnpj: isCnpj);
  }

  /// Reformata documento ao trocar CPF ↔ CNPJ.
  static void onDocumentTypeChanged(
    TextEditingController c, {
    required bool isCnpj,
  }) {
    c.text = BrazilianInputFormat.formatDocument(c.text, isCnpj: isCnpj);
  }
}
