import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/shell/presentation/widgets/mobile_nav_shortcuts_sheet.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MobileNavMenuItem {
  const MobileNavMenuItem({
    required this.path,
    required this.icon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final String label;
}

void showMobileNavMenuSheet({
  required BuildContext context,
  required List<MobileNavMenuItem> items,
  required String currentPath,
  AppModule? module,
  WidgetRef? ref,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: ClayTokens.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ClayTokens.radiusLg)),
    ),
      builder: (ctx) {
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.7;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Navegação',
                  style: AppTypography.heading(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                if (module != null && ref != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        showMobileNavShortcutsSheet(
                          context: context,
                          ref: ref,
                          module: module,
                          availableItems: items,
                        );
                      },
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Personalizar barra inferior'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                    final item = items[i];
                    final selected = currentPath == item.path ||
                        (item.path != '/' &&
                            item.path != '/rental' &&
                            currentPath.startsWith('${item.path}/')) ||
                        ((item.path == '/' || item.path == '/rental') &&
                            currentPath == item.path);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          context.go(item.path);
                        },
                        borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
                        child: ClaySurface(
                          depth: selected ? ClayDepth.raised : ClayDepth.pressed,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 22,
                                color: selected ? ClayTokens.accent : ClayTokens.muted,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 14,
                                    color: selected ? ClayTokens.foreground : ClayTokens.textSecondary,
                                  ),
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check_rounded, size: 20, color: ClayTokens.accent),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
  );
}
