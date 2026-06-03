import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Caminho seguro para voltar após [returnTo] na query string (usado com `context.go`).
String resolveReturnPath(BuildContext context, {String fallback = '/'}) {
  final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
  if (returnTo != null && returnTo.startsWith('/')) {
    return returnTo;
  }
  return fallback;
}

/// Navega para [path] preservando destino de retorno na query.
void goWithReturn(BuildContext context, String path, {required String returnTo}) {
  final uri = Uri(path: path, queryParameters: {'returnTo': returnTo});
  context.go(uri.toString());
}
