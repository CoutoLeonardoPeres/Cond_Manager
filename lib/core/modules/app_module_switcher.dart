import 'package:cond_manager/core/modules/app_module_providers.dart';
import 'package:cond_manager/core/modules/company_module_access.dart';
import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppModuleSwitcher extends ConsumerStatefulWidget {
  const AppModuleSwitcher({super.key});

  @override
  ConsumerState<AppModuleSwitcher> createState() => _AppModuleSwitcherState();
}

class _AppModuleSwitcherState extends ConsumerState<AppModuleSwitcher> {
  bool _pressed = false;
  bool _hovered = false;

  void _toggle(AppModule active, List<AppModule> enabled, UserProfile profile) {
    if (enabled.length < 2) return;

    final currentIndex = enabled.indexOf(active);
    final next = enabled[(currentIndex + 1) % enabled.length];

    ref.read(activeAppModuleProvider.notifier).state = next;
    if (context.mounted) {
      context.go(profile.permissions.homeRouteForModule(next));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    if (profile == null) return const SizedBox.shrink();

    final access = profile.modules;
    if (!access.hasMultipleModules) return const SizedBox.shrink();

    final active = ref.watch(activeAppModuleProvider) ?? access.defaultModule;
    final nextModule = _nextModule(active, access.enabledModules);
    final style = _ModuleToggleStyle.forModule(active);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: 'Alternar para ${nextModule.label}',
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: () => _toggle(active, access.enabledModules, profile),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: _hovered ? style.gradientHover : style.gradient,
                borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                boxShadow: _pressed
                    ? ClayDecorations.clayPressedShadows()
                    : ClayDecorations.clayButtonShadows(hover: _hovered),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(style.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    active.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppModule _nextModule(AppModule current, List<AppModule> enabled) {
    if (enabled.length < 2) return current;
    final index = enabled.indexOf(current);
    return enabled[(index + 1) % enabled.length];
  }
}

class _ModuleToggleStyle {
  const _ModuleToggleStyle({
    required this.icon,
    required this.gradient,
    required this.gradientHover,
  });

  final IconData icon;
  final Gradient gradient;
  final Gradient gradientHover;

  static _ModuleToggleStyle forModule(AppModule module) {
    return switch (module) {
      AppModule.maintenance => const _ModuleToggleStyle(
          icon: Icons.build_circle_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), ClayTokens.primary],
          ),
          gradientHover: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
          ),
        ),
      AppModule.rental => const _ModuleToggleStyle(
          icon: Icons.home_work_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF22D3EE), Color(0xFF0284C7)],
          ),
          gradientHover: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF67E8F9), Color(0xFF0369A1)],
          ),
        ),
    };
  }
}
