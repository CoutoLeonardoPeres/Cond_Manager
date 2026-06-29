import 'package:flutter_dotenv/flutter_dotenv.dart';

/// URL pública do app (web/produção) para links de convite nos e-mails.
String? resolveAppPublicUrl() {
  const fromDefine = String.fromEnvironment('APP_PUBLIC_URL');
  if (fromDefine.isNotEmpty) return fromDefine;

  final fromDotenv = dotenv.env['APP_PUBLIC_URL']?.trim();
  if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;

  return null;
}

/// Monta o link de convite para compartilhar com o usuário.
String buildInviteLink(String token) {
  final publicUrl = resolveAppPublicUrl();
  if (publicUrl != null) {
    return '${publicUrl.replaceAll(RegExp(r'/+$'), '')}/invite/$token';
  }

  final base = Uri.base;
  if (base.hasScheme && base.host.isNotEmpty) {
    return '${base.origin}/invite/$token';
  }

  return '/invite/$token';
}

/// Monta o link público do formulário de cadastro de locatário/inquilino.
String buildTenantIntakeLink(String token) {
  final publicUrl = resolveAppPublicUrl();
  if (publicUrl != null) {
    return '${publicUrl.replaceAll(RegExp(r'/+$'), '')}/cadastro-locatario/$token';
  }

  final base = Uri.base;
  if (base.hasScheme && base.host.isNotEmpty) {
    return '${base.origin}/cadastro-locatario/$token';
  }

  return '/cadastro-locatario/$token';
}
