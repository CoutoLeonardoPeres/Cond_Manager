import 'package:cond_manager/core/formatters/brazilian_input_format.dart';
import 'package:flutter/services.dart';

class PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _apply(newValue, BrazilianInputFormat.formatPhone, maxDigits: 11);
  }
}

class CpfMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _apply(newValue, BrazilianInputFormat.formatCpf, maxDigits: 11);
  }
}

class CnpjMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _apply(newValue, BrazilianInputFormat.formatCnpj, maxDigits: 14);
  }
}

class CepMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _apply(newValue, BrazilianInputFormat.formatCep, maxDigits: 8);
  }
}

class DocumentMaskFormatter extends TextInputFormatter {
  DocumentMaskFormatter({required this.isCnpj});

  final bool isCnpj;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _apply(
      newValue,
      (v) => BrazilianInputFormat.formatDocument(v, isCnpj: isCnpj),
      maxDigits: isCnpj ? 14 : 11,
    );
  }
}

TextEditingValue _apply(
  TextEditingValue newValue,
  String Function(String) format, {
  required int maxDigits,
}) {
  final digits = BrazilianInputFormat.digitsOnly(newValue.text);
  if (digits.length > maxDigits) {
    return newValue.copyWith(text: format(digits.substring(0, maxDigits)));
  }
  final formatted = format(digits);
  return TextEditingValue(
    text: formatted,
    selection: TextSelection.collapsed(offset: formatted.length),
  );
}
