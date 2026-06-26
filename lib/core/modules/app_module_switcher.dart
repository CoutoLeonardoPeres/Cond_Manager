import 'package:cond_manager/core/modules/app_module_providers.dart';
import 'package:cond_manager/core/modules/company_module_access.dart';
import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppModuleSwitcher extends ConsumerWidget {
  const AppModuleSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final access = profile.modules;
    if (!access.hasMultipleModules) return const SizedBox.shrink();

    final active = ref.watch(activeAppModuleProvider) ?? access.defaultModule;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClaySurface(
        depth: ClayDepth.raised,
        radius: ClayTokens.radiusFull,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AppModule>(
            value: active,
            borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ClayTokens.textPrimary,
            ),
            items: access.enabledModules
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(m.label),
                  ),
                )
                .toList(),
            onChanged: (module) {
              if (module == null || profile == null) return;
              ref.read(activeAppModuleProvider.notifier).state = module;
              if (context.mounted) {
                context.go(profile.permissions.homeRouteForModule(module));
              }
            },
          ),
        ),
      ),
    );
  }
}
