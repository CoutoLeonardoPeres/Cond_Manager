import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Módulo ativo na interface (Manutenção ou Locação).
final activeAppModuleProvider = StateProvider<AppModule?>((ref) => null);
