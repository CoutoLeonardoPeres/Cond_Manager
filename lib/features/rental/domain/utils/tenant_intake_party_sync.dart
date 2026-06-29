import 'package:cond_manager/core/formatters/brazilian_input_format.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';

bool partyCategoryUsesIntakeForm(RentalPartyCategory category) =>
    category == RentalPartyCategory.tenant ||
    category == RentalPartyCategory.occupant ||
    category == RentalPartyCategory.guest;

/// Mescla colunas da pessoa com [intake_metadata] para preencher o formulário completo.
Map<String, String> partyToIntakeFieldValues(RentalParty party) {
  final values = <String, String>{};

  final meta = party.intakeMetadata;
  if (meta != null) {
    for (final entry in meta.entries) {
      if (entry.value != null) {
        values[entry.key] = entry.value.toString();
      }
    }
  }

  void set(String key, String? value) {
    if (value != null && value.trim().isNotEmpty) {
      values[key] = value.trim();
    }
  }

  set('LOCATARIO_NOME_COMPLETO', party.fullName);
  set('LOCATARIO_EMAIL', party.email);
  set('LOCATARIO_TELEFONE', party.phone);
  set('LOCATARIO_WHATSAPP', party.phone);
  if (party.documentNumber != null) {
    values['LOCATARIO_CPF'] = BrazilianInputFormat.formatCpf(party.documentNumber!);
  }
  set('LOCATARIO_CEP', party.addressZip);
  set('LOCATARIO_LOGRADOURO', party.addressStreet);
  set('LOCATARIO_NUMERO', party.addressNumber);
  set('LOCATARIO_COMPLEMENTO', party.addressComplement);
  set('LOCATARIO_BAIRRO', party.addressNeighborhood);
  set('LOCATARIO_CIDADE', party.addressCity);
  set('LOCATARIO_ESTADO', party.addressState);

  return values;
}

RentalPartyInput partyInputFromIntakeValues({
  required String companyId,
  required Map<String, String> values,
  required RentalPartyCategory category,
  String status = 'active',
  String? notes,
}) {
  String? pick(String key) {
    final v = values[key]?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  final fullName = pick('LOCATARIO_NOME_COMPLETO') ?? '';
  final phone = pick('LOCATARIO_WHATSAPP') ?? pick('LOCATARIO_TELEFONE');
  final metadata = Map<String, dynamic>.from(values);

  return RentalPartyInput(
    companyId: companyId,
    fullName: fullName,
    category: category,
    email: pick('LOCATARIO_EMAIL'),
    phone: phone,
    documentNumber: pick('LOCATARIO_CPF'),
    notes: notes,
    status: status,
    addressStreet: pick('LOCATARIO_LOGRADOURO'),
    addressNumber: pick('LOCATARIO_NUMERO'),
    addressComplement: pick('LOCATARIO_COMPLEMENTO'),
    addressNeighborhood: pick('LOCATARIO_BAIRRO'),
    addressCity: pick('LOCATARIO_CIDADE'),
    addressState: pick('LOCATARIO_ESTADO'),
    addressZip: pick('LOCATARIO_CEP'),
    intakeMetadata: metadata,
  );
}
