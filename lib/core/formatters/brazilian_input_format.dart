/// Formatação e normalização de campos brasileiros (telefone, CPF, CNPJ, CEP).
class BrazilianInputFormat {
  BrazilianInputFormat._();

  static String digitsOnly(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String formatPhone(String value) {
    final d = digitsOnly(value);
    if (d.isEmpty) return '';

    if (d.length <= 2) return '($d';
    if (d.length <= 6) {
      return '(${d.substring(0, 2)}) ${d.substring(2)}';
    }
    if (d.length <= 10) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
    }
    final capped = d.length > 11 ? d.substring(0, 11) : d;
    return '(${capped.substring(0, 2)}) ${capped.substring(2, 7)}-${capped.substring(7)}';
  }

  static String formatCpf(String value) {
    final d = _cap(digitsOnly(value), 11);
    if (d.isEmpty) return '';
    if (d.length <= 3) return d;
    if (d.length <= 6) return '${d.substring(0, 3)}.${d.substring(3)}';
    if (d.length <= 9) {
      return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6)}';
    }
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  static String formatCnpj(String value) {
    final d = _cap(digitsOnly(value), 14);
    if (d.isEmpty) return '';
    if (d.length <= 2) return d;
    if (d.length <= 5) return '${d.substring(0, 2)}.${d.substring(2)}';
    if (d.length <= 8) {
      return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5)}';
    }
    if (d.length <= 12) {
      return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8)}';
    }
    return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8, 12)}-${d.substring(12)}';
  }

  static String formatCep(String value) {
    final d = _cap(digitsOnly(value), 8);
    if (d.isEmpty) return '';
    if (d.length <= 5) return d;
    return '${d.substring(0, 5)}-${d.substring(5)}';
  }

  static String formatDocument(String value, {required bool isCnpj}) {
    return isCnpj ? formatCnpj(value) : formatCpf(value);
  }

  static String _cap(String digits, int max) {
    return digits.length > max ? digits.substring(0, max) : digits;
  }
}

class BrazilianValidators {
  BrazilianValidators._();

  static String? phone(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Obrigatório' : null;
    }
    final len = BrazilianInputFormat.digitsOnly(value).length;
    if (len < 10) return 'Telefone incompleto';
    return null;
  }

  static String? cpf(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Obrigatório' : null;
    }
    if (BrazilianInputFormat.digitsOnly(value).length != 11) {
      return 'CPF incompleto';
    }
    return null;
  }

  static String? cnpj(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Obrigatório' : null;
    }
    if (BrazilianInputFormat.digitsOnly(value).length != 14) {
      return 'CNPJ incompleto';
    }
    return null;
  }

  static String? cep(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Obrigatório' : null;
    }
    if (BrazilianInputFormat.digitsOnly(value).length != 8) {
      return 'CEP incompleto';
    }
    return null;
  }

  static String? document(String? value, {required bool isCnpj, bool required = false}) {
    return isCnpj ? cnpj(value, required: required) : cpf(value, required: required);
  }
}
