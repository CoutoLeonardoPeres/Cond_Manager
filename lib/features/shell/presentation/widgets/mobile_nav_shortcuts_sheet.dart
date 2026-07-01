import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/features/shell/data/mobile_nav_shortcuts_storage.dart';
import 'package:cond_manager/features/shell/presentation/providers/mobile_nav_shortcuts_provider.dart';
import 'package:cond_manager/features/shell/presentation/widgets/mobile_nav_menu_sheet.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kShortcutCardHeight = 44.0;
const _kShortcutCardGap = 4.0;
const _kShortcutIconSize = 18.0;

void showMobileNavShortcutsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required AppModule module,
  required List<MobileNavMenuItem> availableItems,
}) {
  final saved = ref.read(mobileNavShortcutsProvider(module));
  final orderedSelected = <String>[
    for (final path in saved)
      if (availableItems.any((i) => i.path == path)) path,
  ];

  if (orderedSelected.isEmpty) {
    for (final item in availableItems.take(MobileNavShortcutsStorage.maxShortcuts)) {
      orderedSelected.add(item.path);
    }
  }

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: ClayTokens.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ClayTokens.radiusLg)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocalState) {
          MobileNavMenuItem? itemFor(String path) {
            for (final item in availableItems) {
              if (item.path == path) return item;
            }
            return null;
          }

          void toggle(String path) {
            setLocalState(() {
              if (orderedSelected.contains(path)) {
                orderedSelected.remove(path);
              } else if (orderedSelected.length < MobileNavShortcutsStorage.maxShortcuts) {
                orderedSelected.add(path);
              }
            });
          }

          void onReorder(int oldIndex, int newIndex) {
            setLocalState(() {
              if (newIndex > oldIndex) newIndex--;
              final path = orderedSelected.removeAt(oldIndex);
              orderedSelected.insert(newIndex, path);
            });
          }

          final unselected =
              availableItems.where((i) => !orderedSelected.contains(i.path)).toList();
          final atLimit = orderedSelected.length >= MobileNavShortcutsStorage.maxShortcuts;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Atalhos da barra inferior',
                    style: AppTypography.heading(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Escolha até ${MobileNavShortcutsStorage.maxShortcuts} telas. '
                    'Arraste os cards selecionados para definir a ordem na barra '
                    '(esquerda → direita). O botão Menu sempre mostra o restante.',
                    style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  if (orderedSelected.isNotEmpty) ...[
                    Text(
                      'Ordem na barra',
                      style: AppTypography.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ClayTokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: orderedSelected.length * (_kShortcutCardHeight + _kShortcutCardGap),
                      child: ReorderableListView.builder(
                        padding: EdgeInsets.zero,
                        buildDefaultDragHandles: false,
                        onReorder: onReorder,
                        itemCount: orderedSelected.length,
                        itemBuilder: (_, index) {
                          final path = orderedSelected[index];
                          final item = itemFor(path);
                          if (item == null) {
                            return SizedBox(key: ValueKey(path));
                          }
                          return _SelectedShortcutCard(
                            key: ValueKey(path),
                            index: index,
                            item: item,
                            onToggle: () => toggle(path),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (unselected.isNotEmpty) ...[
                    Text(
                      'Adicionar à barra',
                      style: AppTypography.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ClayTokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: unselected.length,
                      separatorBuilder: (_, _) => const SizedBox(height: _kShortcutCardGap),
                      itemBuilder: (_, i) {
                        final item = unselected[i];
                        return _AvailableShortcutCard(
                          item: item,
                          disabled: atLimit,
                          onTap: () => toggle(item.path),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          await ref.read(mobileNavShortcutsProvider(module).notifier).reset();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Restaurar padrão'),
                      ),
                      const Spacer(),
                      ClayButton(
                        label: 'Salvar',
                        expand: false,
                        onPressed: () async {
                          await ref
                              .read(mobileNavShortcutsProvider(module).notifier)
                              .save(List<String>.from(orderedSelected));
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _SelectedShortcutCard extends StatelessWidget {
  const _SelectedShortcutCard({
    super.key,
    required this.index,
    required this.item,
    required this.onToggle,
  });

  final int index;
  final MobileNavMenuItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _kShortcutCardGap),
      child: SizedBox(
        height: _kShortcutCardHeight,
        child: ClaySurface(
          depth: ClayDepth.raised,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    size: _kShortcutIconSize,
                    color: ClayTokens.muted.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ClayTokens.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ClayTokens.accent,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(item.icon, size: _kShortcutIconSize, color: ClayTokens.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.1),
                ),
              ),
              _compactCheckbox(
                value: true,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _compactCheckbox({
  required bool value,
  required ValueChanged<bool?>? onChanged,
}) {
  return SizedBox(
    width: 36,
    height: 36,
    child: Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: ClayTokens.accent,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}

class _AvailableShortcutCard extends StatelessWidget {
  const _AvailableShortcutCard({
    required this.item,
    required this.disabled,
    required this.onTap,
  });

  final MobileNavMenuItem item;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
        child: SizedBox(
          height: _kShortcutCardHeight,
          child: ClaySurface(
            depth: ClayDepth.pressed,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: _kShortcutIconSize,
                  color: disabled ? ClayTokens.textMuted : ClayTokens.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      height: 1.1,
                      color: disabled ? ClayTokens.textMuted : ClayTokens.foreground,
                    ),
                  ),
                ),
                _compactCheckbox(
                  value: false,
                  onChanged: disabled ? null : (_) => onTap(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
