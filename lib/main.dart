import 'dart:async';

import 'package:cond_manager/core/config/bootstrap_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BootstrapApp.installGlobalErrorHandlers();

  runZonedGuarded(
    () {
      runApp(
        const ProviderScope(
          child: BootstrapApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Erro não tratado no Cond Manager: $error\n$stack');
    },
  );
}
