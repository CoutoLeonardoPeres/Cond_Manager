import 'dart:convert';

import 'package:cond_manager/core/formatters/brazilian_input_format.dart';
import 'package:http/http.dart' as http;

class ViaCepAddress {
  const ViaCepAddress({
    this.street,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
  });

  final String? street;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;
}

class ViaCepService {
  ViaCepService._();

  static Future<ViaCepAddress?> lookup(String cep) async {
    final digits = BrazilianInputFormat.digitsOnly(cep);
    if (digits.length != 8) return null;

    try {
      final response = await http
          .get(Uri.parse('https://viacep.com.br/ws/$digits/json/'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['erro'] == true) return null;

      return ViaCepAddress(
        street: _orNull(data['logradouro']),
        complement: _orNull(data['complemento']),
        neighborhood: _orNull(data['bairro']),
        city: _orNull(data['localidade']),
        state: _orNull(data['uf'])?.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static String? _orNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
